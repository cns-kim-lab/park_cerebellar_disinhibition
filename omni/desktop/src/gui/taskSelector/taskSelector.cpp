#include "gui/taskSelector/taskSelector.h"
#include "system/omLocalPreferences.hpp"
#include "events/events.h"
#include "gui/exec.hpp"
#include "task/comparisonTask.h"
#include "task/viewingTask.h"
#include "task/editingTask.h"

using namespace om::task;

enum class Columns {
  Id = 0,
  Cell,
  Parent,
  Progress,
  Status,
  Notes,
  Path
};

TaskSelector::TaskSelector(QWidget* p) : QDialog(p) {
  QGridLayout* layout = new QGridLayout(this);

  datasetCombo_ = new QComboBox(this);
  layout->addWidget(datasetCombo_, 0, 0, 1, 1);
  om::connect(datasetCombo_, SIGNAL(currentIndexChanged(int)), this,
              SLOT(updateCells()));

  cellCombo_ = new QComboBox(this);
  layout->addWidget(cellCombo_, 0, 1, 1, 1);
  om::connect(cellCombo_, SIGNAL(currentIndexChanged(int)), this,
              SLOT(updateList()));

  //jwgim add
  tasktypeCombo_ = new QComboBox(this);
  tasktypeCombo_->addItem(tr("Trace"), (int)om::task::TaskSelectType::TRACE);
  tasktypeCombo_->addItem(tr("Compare"), (int)om::task::TaskSelectType::COMPARE);
  tasktypeCombo_->setCurrentIndex(0);
  layout->addWidget(tasktypeCombo_, 0, 2, 1, 1);
  om::connect(tasktypeCombo_, SIGNAL(currentIndexChanged(int)), this,
              SLOT(updateTasktype()));

  taskstatusCombo_ = new QComboBox(this);
  taskstatusCombo_->addItem(tr("Normal"), (int)om::task::TaskSelectStatus::NORMAL);
  taskstatusCombo_->addItem(tr("Ongoing"), (int)om::task::TaskSelectStatus::ONGOING);
  taskstatusCombo_->addItem(tr("Skipped"), (int)om::task::TaskSelectStatus::SKIPPED);
  taskstatusCombo_->addItem(tr("Completed"), (int)om::task::TaskSelectStatus::COMPLETED);
  taskstatusCombo_->setCurrentIndex(1);
  layout->addWidget(taskstatusCombo_, 0, 3, 1, 1);
  om::connect(taskstatusCombo_, SIGNAL(currentIndexChanged(int)), this,
              SLOT(updateTaskstatus()));

  taskLineEdit_ = new QLineEdit(this);
  layout->addWidget(taskLineEdit_, 0, 4);
  om::connect(taskLineEdit_, SIGNAL(textEdited(const QString&)), this,
              SLOT(updateList()));

  refreshButton_ = new QPushButton(tr("Refresh"), this);
  layout->addWidget(refreshButton_, 0, 5);
  om::connect(refreshButton_, SIGNAL(clicked()), this, SLOT(updateList()));

  taskTable_ = new QTableWidget(this);
  taskTable_->setRowCount(0);

  QStringList headerLabels;
  headerLabels << "Id"
               << "Cell"
               << "Parent"
               << "Progress"
               << "Status"
               << "Notes"
               << "Path";
  taskTable_->setColumnCount(headerLabels.size());
  taskTable_->setHorizontalHeaderLabels(headerLabels);

  taskTable_->setSortingEnabled(true);
  taskTable_->setSelectionBehavior(QAbstractItemView::SelectRows);
  taskTable_->setSelectionMode(QAbstractItemView::SingleSelection);
  taskTable_->setHorizontalScrollMode(QAbstractItemView::ScrollPerPixel);
  //taskTable_->setEditTriggers(QAbstractItemView::DoubleClicked);

  layout->addWidget(taskTable_, 1, 0, 1, 6);
  om::connect(taskTable_, SIGNAL(itemSelectionChanged()), this,
              SLOT(updateEnabled()));
  // om::connect(taskTable_, SIGNAL(itemChanged(QTableWidgetItem*)), this,
  //             SLOT(itemEdited(QTableWidgetItem*)));

  traceButton_ = new QPushButton(tr("Trace"), this);
  layout->addWidget(traceButton_, 2, 0);
  om::connect(traceButton_, SIGNAL(clicked()), this, SLOT(traceClicked()));

  compareButton_ = new QPushButton(tr("Compare"), this);
  layout->addWidget(compareButton_, 2, 1);
  om::connect(compareButton_, SIGNAL(clicked()), this, SLOT(compareClicked()));

  //jwgim add
  viewButton_ = new QPushButton(tr("View"), this);
  layout->addWidget(viewButton_, 2, 2);
  om::connect(viewButton_, SIGNAL(clicked()), this, SLOT(viewClicked()));

  editButton_ = new QPushButton(tr("EditSeed"), this);
  layout->addWidget(editButton_, 2, 3);
  om::connect(editButton_, SIGNAL(clicked()), this, SLOT(editClicked()));

  closeButton_ = new QPushButton(tr("Close"), this);
  layout->addWidget(closeButton_, 2, 5);
  om::connect(closeButton_, SIGNAL(clicked()), this, SLOT(reject()));

  //jwgim add
  datasetID_ = 0; 
  cellID_ = 0; 

  refreshButton_->setDefault(true); 
  closeButton_->setDefault(true);

  setWindowTitle(tr("Task Selector"));

  for (int i = 0; i < layout->columnCount(); ++i) {
    layout->setColumnMinimumWidth(i,
                                  sizeHint().width() / layout->columnCount());
  }
}

QSize TaskSelector::sizeHint() const { return QSize(900, 600); }

void TaskSelector::showEvent(QShowEvent* event) {
  datasetCombo_->clear();
  datasetList = TaskManager::GetDatasetIDs();   
  int idx = 0;
  for(int i=0;i<datasetList->size();i++) {
    datasetCombo_->addItem( QString::fromStdString(datasetList->at(i)), (quint64)std::stoi(datasetList->at(i)) );    
    if( std::stoi(datasetList->at(i)) == datasetID_ )
      idx = i;
  }
  datasetCombo_->setCurrentIndex(idx);   
}

void TaskSelector::updateCells() {    
  datasetID_ =  datasetID();

  cellList = TaskManager::GetCellIDs(datasetID());
  cellCombo_->clear();
  int idx = 0;
  for(int i=0;i<cellList->size();i++) {
    cellCombo_->addItem( QString::fromStdString(cellList->at(i)), (quint64)std::stoi(cellList->at(i)) );
    if( std::stoi(cellList->at(i)) == cellID_ ) 
      idx = i;
  }
  cellCombo_->setCurrentIndex(idx);
}

void TaskSelector::updateList() {  
  cellID_ = cellID();
  getTasks();
  updateEnabled();
}

void TaskSelector::updateEnabled() {
  auto row = taskTable_->currentRow();
  auto* taskIdItem = taskTable_->item(row, (int)Columns::Id);
  if (!taskIdItem) {
    traceButton_->setEnabled(false);
    compareButton_->setEnabled(false);
    viewButton_->setEnabled(false);
    editButton_->setEnabled(false);
    return;
  }   

  auto use_trace = false;
  auto use_compare = false;
  auto use_view = false;
  auto use_edit = false;
  auto taskId = taskID();
  if(taskId) {  //all available
    traceTask = TaskManager::GetTracingTask(taskId, true, taskstatus());
    compareTask = TaskManager::GetComparisonTask(taskId, true, taskstatus());
    viewTask = TaskManager::GetViewingTask(taskId);
    editTask = TaskManager::GetEditingTask(taskId);
    use_trace = traceTask? true:false;
    use_compare = compareTask? true:false;
    use_view = viewTask? true:false;
    use_edit = editTask? true:false;
  }
  else {
    if( tasktype() == (int)om::task::TaskSelectType::TRACE ) {      
      traceTask = TaskManager::GetTracingTask(selectedTaskId(), false, taskstatus());
      use_trace = traceTask? true:false;
    }
    else { 
      compareTask = TaskManager::GetComparisonTask(selectedTaskId(), false, taskstatus());
      use_compare = compareTask? true:false;
    }
    viewTask = TaskManager::GetViewingTask(selectedTaskId());
    use_view = viewTask? true:false;
    use_edit = false;
  }
  traceButton_->setEnabled(use_trace);
  compareButton_->setEnabled(use_compare);
  viewButton_->setEnabled(use_view);
  editButton_->setEnabled(use_edit);
}

int TaskSelector::selectedTaskId() {
  auto row = taskTable_->currentRow();
  auto* taskIdItem = taskTable_->item(row, (int)Columns::Id);
  if (!taskIdItem) {
    log_infos << "No task selected";
    return 0;
  }
  return taskIdItem->data(0).toInt();
}

void TaskSelector::traceClicked() {
  auto taskId = taskID();
  auto id = selectedTaskId();
  log_debugs << "Tracing Task: " << id;
  traceButton_->setEnabled(false);
  if( traceTask ) {    
    if( !TaskManager::UpdateRecordToStartTraceTask(id, taskId?true:false, taskstatus(), traceTask) ) {
      log_errors << "update record failed";
      QMessageBox db_fail(QMessageBox::Warning, 
                  "DB update failed",
                  "DB update failed, please try again.", 
                  QMessageBox::Close );
      db_fail.exec();
      return;
    }
    TaskManager::LoadTask(std::static_pointer_cast<Task>(traceTask));
    accept();
  }
}

void TaskSelector::compareClicked() {
  auto id = selectedTaskId();
  log_debugs << "Comparison Task: " << id;
  compareButton_->setEnabled(false);
  if( compareTask ) {
    if( !TaskManager::UpdateRecordToStartComparisonTask(id, compareTask) ) {
      log_errors << "update record failed";
      QMessageBox db_fail(QMessageBox::Warning, 
                "DB update failed",
                "DB update failed, please try again.", 
                QMessageBox::Close );
      db_fail.exec();
      return;
    }
    TaskManager::LoadTask(std::static_pointer_cast<Task>(compareTask));
    accept();
  }
}

uint32_t TaskSelector::datasetID() {
  if( !datasetList )
    return 0;  
  return std::stoi(datasetCombo_->currentText().toStdString());
}

uint64_t TaskSelector::cellID() {
  if( !cellList || cellList->size()<1 ) 
    return (uint64_t)0;
  return std::stoi(cellCombo_->currentText().toStdString());
}

void TaskSelector::itemEdited(QTableWidgetItem* item) {
  if (item->column() == (int)Columns::Notes) {
    auto row = item->row();
    auto id = taskTable_->item(row, (int)Columns::Id)->data(0).toInt();
    auto rsl = TaskManager::UpdateTaskNotes(id, item->data(0).toString().toStdString());
    if( !rsl ) {
      item->setData(0, "");
      QMessageBox db_fail(QMessageBox::Warning, 
                "DB update failed",
                "Notes update failed, please try again.", 
                QMessageBox::Close );
      db_fail.exec();
    }
  }
}

uint64_t TaskSelector::taskID() { 
  auto text = taskLineEdit_->text().trimmed();
  auto taskId = text.toInt();

  return (uint64_t)taskId; 
}

template <typename T>
QTableWidgetItem* makeTableItem(const T val,
                                Qt::ItemFlags flags =
                                    Qt::ItemIsEnabled | Qt::ItemIsSelectable) {
  QTableWidgetItem* item = new QTableWidgetItem();
  item->setData(0, val);
  item->setFlags(flags);
  return item;
}

void TaskSelector::updateTasks(const std::vector<TaskInfo>& tasks) {
  taskTable_->setSortingEnabled(false);
  taskTable_->setRowCount(tasks.size());
  taskTable_->blockSignals(true);
  for (size_t i = 0; i < tasks.size(); ++i) {
    auto& t = tasks[i];

    taskTable_->setItem(i, (int)Columns::Id, makeTableItem(quint64(t.id))); 
    taskTable_->setItem(i, (int)Columns::Cell, makeTableItem(quint64(t.cell)));
    taskTable_->setItem(i, (int)Columns::Parent, makeTableItem(quint64(t.parent)));
    taskTable_->setItem(i, (int)Columns::Progress, makeTableItem(QString::fromStdString(t.progress)));
    taskTable_->setItem(i, (int)Columns::Status, makeTableItem(QString::fromStdString(t.status)));
    taskTable_->setItem(i, (int)Columns::Path,
                        makeTableItem(QString::fromStdString(t.path)));
    taskTable_->setItem(i, (int)Columns::Notes,
                        makeTableItem(QString::fromStdString(t.notes)));
    // taskTable_->setItem(i, (int)Columns::Notes,
    //                     makeTableItem(QString::fromStdString(t.notes),
    //                                   Qt::ItemIsEnabled | Qt::ItemIsSelectable |
    //                                       Qt::ItemIsEditable));
  }

  taskTable_->setSortingEnabled(true);
  taskTable_->resizeColumnsToContents();
  // TODO
  taskTable_->sortByColumn((int)Columns::Parent, Qt::AscendingOrder);
  taskTable_->blockSignals(false);
}

void TaskSelector::getTasks() {
  taskTable_->setRowCount(0);
  auto taskId = taskID();
  if (taskId) 
    taskList = TaskManager::GetTaskinfoByID(taskId);
  else 
    taskList = TaskManager::GetTasklist(datasetID(), cellID(), tasktype(), taskstatus());  
  updateTasks(*taskList);
}

void TaskSelector::accept() {
  OmLocalPreferences::setDataset(datasetID());
  QDialog::accept();
}


void TaskSelector::updateTasktype() {  
  if( tasktype() == (int)om::task::TaskSelectType::TRACE ) {
    taskstatusCombo_->setItemData(1,33, Qt::UserRole-1);
    taskstatusCombo_->setItemData(2,33, Qt::UserRole-1);
    taskstatusCombo_->setCurrentIndex(1); 
  }
  else {
    taskstatusCombo_->setItemData(1,0, Qt::UserRole-1);
    taskstatusCombo_->setItemData(2,0, Qt::UserRole-1);
    taskstatusCombo_->setCurrentIndex(0);
  }
  updateTaskstatus();
}

void TaskSelector::updateTaskstatus() {  
  getTasks();
  updateEnabled();
}

int TaskSelector::tasktype() {
  return tasktypeCombo_->itemData(tasktypeCombo_->currentIndex()).toInt();
}

int TaskSelector::taskstatus() {
  return taskstatusCombo_->itemData(taskstatusCombo_->currentIndex()).toInt();
}

void TaskSelector::viewClicked() {
  auto id = selectedTaskId();
  log_debugs << "Viewing Task: " << id;

  if( viewTask ) {
    TaskManager::LoadTask(std::static_pointer_cast<Task>(viewTask));
    accept();
  }
}

void TaskSelector::editClicked() {
  auto id = selectedTaskId();
  log_debugs << "Editing Task: " << id;
  editButton_->setEnabled(false);
  if( editTask ) {
    TaskManager::LoadTask(std::static_pointer_cast<Task>(editTask));
    accept();
  }
}
