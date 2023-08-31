#pragma once
#include "precomp.h"

#include "gui/widgets/omTellInfo.hpp"
#include "system/account.h"
#include "system/omConnect.hpp"
#include "task/taskManager.h"
#include "task/tracingTask.h"
#include "network/http/http.hpp"

namespace om {
namespace task {
class Dataset;
class TaskInfo;
}
}

class TaskSelector : public QDialog {
  Q_OBJECT;

 public:
  TaskSelector(QWidget* p = nullptr);

 public
Q_SLOTS:
  void updateEnabled();
  void updateList();
  void updateCells();
  void traceClicked();
  void compareClicked();
  void viewClicked(); //jwgim
  void editClicked(); //jwgim
  void itemEdited(QTableWidgetItem*);
  virtual void showEvent(QShowEvent* event = nullptr) override;
  void updateTasktype();  //jwgim
  void updateTaskstatus();  //jwgim
  
 protected:
  virtual void accept() override;

  virtual QSize sizeHint() const override;

 private:
  int selectedTaskId();
  void getTasks();
  void updateTasks(const std::vector<om::task::TaskInfo>& tasks);
  
  int oldCellSelection_;

  QComboBox* datasetCombo_;
  QComboBox* cellCombo_;
  QLineEdit* taskLineEdit_;
  QTableWidget* taskTable_;
  QPushButton* traceButton_;
  QPushButton* compareButton_;
  QPushButton* viewButton_;  //jwgim
  QPushButton* editButton_;  //jwgim
  QPushButton* closeButton_;
  QPushButton* refreshButton_;
  QComboBox* tasktypeCombo_;    //jwgim
  QComboBox* taskstatusCombo_;  //jwgim

  om::task::TaskManager::TaskInfosRequest tasksRequest_;
  om::task::TaskManager::TracingTaskRequest taskRequest_;
  om::task::TaskManager::ComparisonTaskRequest compTaskRequest_;
  om::task::TaskManager::DatasetsRequest datasetsRequest_;
  om::task::TaskManager::CellsRequest cellsRequest_;

  //jwgim
  std::vector<std::string>* datasetList;
  std::vector<std::string>* cellList;
  std::vector<om::task::TaskInfo>* taskList;
  om::task::TaskManager::TraceTask traceTask;
  om::task::TaskManager::CompareTask compareTask;
  om::task::TaskManager::ViewTask viewTask;
  om::task::TaskManager::EditTask editTask;

  uint32_t datasetID();
  uint64_t cellID();
  uint64_t taskID();
  int tasktype();
  int taskstatus();

  uint64_t datasetID_;
  uint64_t cellID_;
};
