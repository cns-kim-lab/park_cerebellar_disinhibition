#include "taskManager.h"
#include "task/task.h"
#include "task/taskInfo.hpp"
#include "task/tracingTask.h"
#include "task/comparisonTask.h"
#include "task/viewingTask.h"
#include "task/editingTask.h"
#include "task/aggregate.hpp"
#include "system/account.h"
#include "network/http/http.hpp"
#include "network/uri.hpp"
#include "yaml-cpp/yaml.h"
#include "events/events.h"

namespace om {
namespace task {

TaskManager::~TaskManager() {
  taskList.clear();
  cellIDs.clear();
  datasetIDs.clear();
}

void TaskManager::ConnectionChangeEvent() {}

bool TaskManager::LoadTask(std::shared_ptr<Task> task) {
  if( instance().currentTask_ && task ) {
    auto& current = instance().currentTask_;
    log_infos << "Skip current task " << current->Id() << " for next task " << task->Id();
    if( !current->Skip() ) {
      QMessageBox db_fail(QMessageBox::Warning, "DB update failed",
                          "Skip failed, please try again.", QMessageBox::Close );
      db_fail.exec();
      return false;
    }
  }
  instance().currentTask_ = task;
  if (task) {
    log_infos << "Changed current task " << task->Id();
  } else {
    log_infos << "Changed current task nullptr";
  }
  om::event::TaskChange();
  if (!task) {
    return true;
  }

  if (!task->Start()) {
    log_debugs << "Failed starting task " << task->Id();
    instance().currentTask_ = nullptr;
    om::event::TaskChange();
    return false;
  }
  om::event::TaskStarted();
  return true;
}

bool TaskManager::AttemptFinishTask() {
  auto& current = instance().currentTask_;
  if (current) {
    log_debugs << "Finishing current task " << current->Id();
    // TODO: headless    
    QMessageBox box(
        QMessageBox::Question, "Submit current task?",
        "Would you like to submit your accomplishments on the current task?",
        QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel);
    int result = box.exec();
    switch( result ) {
      case QMessageBox::Cancel:
        return false;
      case QMessageBox::No:
        if( !current->Save() ) {
          QMessageBox db_fail(QMessageBox::Warning, "DB update failed",
                            "Save failed, please try again.", QMessageBox::Close );
          db_fail.exec();
          return false;
        }
        break;
      case QMessageBox::Yes:
        if( !current->Submit() ) { //jwgim
          QMessageBox db_fail(QMessageBox::Warning, "DB update failed",
                            "Submit failed, please try again.", QMessageBox::Close );
          db_fail.exec();
          return false;
        }
        break;
    }
  }
  return LoadTask(nullptr);
}

bool TaskManager::SubmitTask(bool byshortcut) {
  auto& current = instance().currentTask_;
  if (!current) {
    log_debugs << "No current task, by shortcut?" << byshortcut;
    auto rsl = LoadTask(nullptr);
    if (byshortcut) 
      return false;
    else
      return rsl;         
  }

  log_debugs << "Finishing current task " << current->Id();
  if (byshortcut) { //done by key shortcut
    log_debugs << " invoked by shortcut";
    QMessageBox box(
      QMessageBox::Question, "Submit current task?",
      "Would you like to submit your accomplishments on the current task?",
      QMessageBox::Yes | QMessageBox::Cancel);
    int result = box.exec();
    switch( result ) {
      case QMessageBox::Cancel:
        return false;
      case QMessageBox::Yes:
        break;
      default :
        return false;
    }      
  }
  if( !current->Submit() ) { 
    QMessageBox db_fail(QMessageBox::Warning, "DB update failed",
                      "Submit failed, please try again.", QMessageBox::Close );
    db_fail.exec();
    return false;
  }
  return LoadTask(nullptr);
}

void TaskManager::Refresh() {}

std::shared_ptr<Task> TaskManager::FindInterruptedTask() {
  return std::shared_ptr<Task>();
}


////////////////////////////////////////////////////////////////////////////////////////jwgim from here
bool TaskManager::AttemptSkipTask() {
  auto& current = instance().currentTask_;
  if (current) {
    log_debugs << "Skip current task " << current->Id();
    // TODO: headless
    
    if( !current->Skip() ) {
      QMessageBox db_fail(QMessageBox::Warning, "DB update failed",
                          "Skip failed, please try again.", QMessageBox::Close );
      db_fail.exec();
      return false;
    }
  }

  return LoadTask(nullptr);
}

std::vector<std::string>* TaskManager::GetDatasetIDs() { 
  instance().datasetIDs.clear();
  std::string sentence = "CALL omni_get_dataset_ids();";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() ) 
    return &(instance().datasetIDs);
  std::string str;
  do {
    str = std::to_string(rsl->getUInt("id")) + " : " + rsl->getString("name");
    instance().datasetIDs.push_back(str);
  } while(rsl->next());
  return &(instance().datasetIDs);
}

std::vector<std::string>* TaskManager::GetCellIDs(uint32_t dataset_id) {
  instance().cellIDs.clear();
  std::string sentence = "CALL omni_get_cell_ids(" + std::to_string(dataset_id) 
                      + "," + std::to_string(30) + ");";  //LIMIT 30

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() ) 
    return &(instance().cellIDs);
  std::string str;
  do {
    str = std::to_string(rsl->getUInt64("id")) + " : " + rsl->getString("name");
    //str = std::to_string(rsl->getUInt64("id")) + " : (omni)" + std::to_string(rsl->getUInt64("omni_id"));
    instance().cellIDs.push_back(str);
  } while(rsl->next());  
  return &(instance().cellIDs);
}

std::vector<TaskInfo>* TaskManager::GetTasklist(uint32_t dataset_id, uint64_t cell_id, int tasktype, int taskstatus) {
  if( tasktype == (int)TaskSelectType::TRACE ) {
    switch( taskstatus ) {
      case (int)TaskSelectStatus::NORMAL:
        return GetNormalTraceTaskList(dataset_id, cell_id);
      case (int)TaskSelectStatus::ONGOING:
        return GetOngoingTraceTaskList(dataset_id, cell_id);
      case (int)TaskSelectStatus::SKIPPED:
        return GetSkippedTraceTaskList(dataset_id, cell_id);
      case (int)TaskSelectStatus::COMPLETED:
        return GetCompletedTraceTaskList(dataset_id, cell_id);
    }
  }
  else {  
    switch( taskstatus ) {
      case (int)TaskSelectStatus::NORMAL:
        return GetNormalCompareTaskList(cell_id);
      case (int)TaskSelectStatus::ONGOING:
      case (int)TaskSelectStatus::SKIPPED:
        log_debugs << "not supported status";
        break;
      case (int)TaskSelectStatus::COMPLETED:
        return GetCompletedCompareTaskList(cell_id);
    }
  }
  return &(instance().taskList);
}

std::vector<TaskInfo>* TaskManager::GetTaskinfoByID(uint64_t task_id) {
  instance().taskList.clear();
  std::string sentence = "CALL omni_get_task_list_byid(" + std::to_string(task_id) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  FillTaskinfolistBySqlResultSet(rsl);
  return &(instance().taskList);
}

std::vector<TaskInfo>* TaskManager::GetOngoingTraceTaskList(uint32_t dataset_id, uint64_t cell_id) {
  instance().taskList.clear();
  std::string sentence ="CALL omni_get_trace_task_list_ongoing(" + std::to_string(cell_id)
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  FillTaskinfolistBySqlResultSet(rsl);
  return &(instance().taskList);
}

std::vector<TaskInfo>* TaskManager::GetCompletedTraceTaskList(uint32_t dataset_id, uint64_t cell_id) {
  instance().taskList.clear();
  std::string sentence = "CALL omni_get_trace_task_list_completed(" + std::to_string(cell_id) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";
  
  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  FillTaskinfolistBySqlResultSet(rsl);
  return &(instance().taskList);
}

std::vector<TaskInfo>* TaskManager::GetSkippedTraceTaskList(uint32_t dataset_id, uint64_t cell_id) {
  instance().taskList.clear();

  std::string sentence = "CALL omni_get_trace_task_list_skipped(" + std::to_string(cell_id) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  FillTaskinfolistBySqlResultSet(rsl);
  return &(instance().taskList);
}

std::vector<TaskInfo>* TaskManager::GetNormalTraceTaskList(uint32_t dataset_id, uint64_t cell_id) {
  instance().taskList.clear();
  std::string sentence = "CALL omni_get_trace_task_list_normal(" + std::to_string(cell_id)
                          + ", " + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  FillTaskinfolistBySqlResultSet(rsl);
  return &(instance().taskList);
}

std::vector<TaskInfo>* TaskManager::GetNormalCompareTaskList(uint64_t cell_id) {
  instance().taskList.clear();
  std::string sentence = "CALL omni_get_compare_task_list_normal(" + std::to_string(cell_id) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  FillTaskinfolistBySqlResultSet(rsl);
  return &(instance().taskList);
}

std::vector<TaskInfo>* TaskManager::GetCompletedCompareTaskList(uint64_t cell_id) {
  instance().taskList.clear();
  std::string sentence = "CALL omni_get_compare_task_list_completed(" + std::to_string(cell_id) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  FillTaskinfolistBySqlResultSet(rsl);
  return &(instance().taskList);
}

  void TaskManager::FillTaskinfolistBySqlResultSet(om::network::SqlQuery::SqlResultset rsl) {
  if( !rsl || !rsl->first() )
    return;
  TaskInfo t;
  uint8_t progress_;
  uint8_t status_;
  do {
    t.id = rsl->getUInt64("id");
    t.weight = 0.0f;
    t.inspected_weight = 0;
    t.path = rsl->getString("path");
    t.cell = rsl->getUInt64("cell_id");
    t.users = ""; //temp
    t.parent = rsl->getUInt64("parent_id");
    t.notes = rsl->getString("notes");
    progress_ = (uint8_t) rsl->getUInt("progress");
    status_ = (uint8_t) rsl->getUInt("status");

    if( progress_ == 0 )
      t.progress = "Trace,Ready";
    else if(progress_ == 1)
      t.progress = "Trace,ing";
    else if(progress_ == 2)
      t.progress = "Trace,Done";
    else if(progress_ == 3)
      t.progress = "Compare,Ready";
    else if(progress_ == 4)
      t.progress = "Compare,ing";
    else if(progress_ == 5)
      t.progress = "Compare,Done";
    else if(progress_ == 6)
      t.progress = "Completed";
    else 
      t.progress = "Unknown(" + std::to_string(progress_) + ")";

    if( status_ == 0 )
      t.status = "Normal";
    else if( status_ == 1 )
      t.status = "Stashed";
    else if( status_ == 2 )
      t.status = "Duplicated";
    else if( status_ == 3 )
      t.status = "Frozen";
    else if( status_ == 4 )
      t.status = "Buried";
    else
      t.status = "Unknown(" + std::to_string(status_) + ")";

    t.allSize = 0;
    t.agreedSize = 0;
    instance().taskList.push_back(t);
  } while( rsl->next() );
}

TaskManager::TraceTask TaskManager::GetTracingTask(uint64_t task_id, bool by_id, int taskstatus) {
  if( by_id ) 
    return GetTracingTaskAnyway(task_id);

  switch( taskstatus ) {
    case (int)TaskSelectStatus::NORMAL:
      return GetTracingTaskNormal(task_id);
    case (int)TaskSelectStatus::ONGOING:
      return GetTracingTaskOngoing(task_id);
    case (int)TaskSelectStatus::SKIPPED:
      return GetTracingTaskSkipped(task_id);
    case (int)TaskSelectStatus::COMPLETED:
      return GetTracingTaskCompleted(task_id);
  }
  return nullptr;
}

TaskManager::TraceTask TaskManager::GetTracingTaskAnyway(uint64_t task_id) {
  std::string sentence = "CALL omni_get_trace_task_info_anyway(" + std::to_string(task_id) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<TracingTask>(TracingTask(rsl));
}

TaskManager::TraceTask TaskManager::GetTracingTaskOngoing(uint64_t task_id) {
  std::string sentence = "CALL omni_get_trace_task_info_ongoing(" + std::to_string(task_id) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";
                        
  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<TracingTask>(TracingTask(rsl));  
}

TaskManager::TraceTask TaskManager::GetTracingTaskSkipped(uint64_t task_id) {
  std::string sentence = "CALL omni_get_trace_task_info_skipped(" + std::to_string(task_id)
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<TracingTask>(TracingTask(rsl));
}

TaskManager::TraceTask TaskManager::GetTracingTaskCompleted(uint64_t task_id) {
  std::string sentence = "CALL omni_get_trace_task_info_completed(" + std::to_string(task_id)
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<TracingTask>(TracingTask(rsl));
}

TaskManager::TraceTask TaskManager::GetTracingTaskNormal(uint64_t task_id) {
  std::string sentence = "CALL omni_get_trace_task_info_normal(" + std::to_string(task_id) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<TracingTask>(TracingTask(rsl));
}

bool TaskManager::UpdateRecordToStartTraceTask(uint64_t task_id, bool by_id, int taskstatus, TraceTask task) {
  if( by_id ) 
    return UpdateTraceTaskAuto(task_id, task);

  switch( taskstatus ) {
    case (int)TaskSelectStatus::NORMAL:
      return UpdateTraceTaskNormal(task_id, task);
    case (int)TaskSelectStatus::ONGOING:
      return UpdateTraceTaskOngoing(task_id, task);
    case (int)TaskSelectStatus::SKIPPED:
      return UpdateTraceTaskSkipped(task_id, task);
    case (int)TaskSelectStatus::COMPLETED:
      return UpdateTraceTaskCompleted(task_id, task);
  }
  return false;
}

bool TaskManager::UpdateTraceTaskOngoing(uint64_t task_id, TraceTask task) {
  std::string segments = task->Segments(SegGroup::GroupType::USER_FOUND);
  std::string sentence = "CALL omni_update_trace_task_ongoing(" + std::to_string(task_id) 
                        + "," + std::to_string(om::system::Account::userid())
                        + ",\"" + segments + "\");";

  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

bool TaskManager::UpdateTraceTaskSkipped(uint64_t task_id, TraceTask task) {
  std::string segments = task->Segments(SegGroup::GroupType::USER_FOUND);
  std::string sentence = "CALL omni_update_trace_task_skipped(" + std::to_string(task_id)
                        + "," + std::to_string(om::system::Account::userid())
                        + ",\"" + segments + "\");";

  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

bool TaskManager::UpdateTraceTaskCompleted(uint64_t task_id, TraceTask task) {
  std::string segments = task->Segments(SegGroup::GroupType::USER_FOUND);
  std::string sentence = "CALL omni_update_trace_task_completed(" + std::to_string(task_id)
                        + "," + std::to_string(om::system::Account::userid())
                        + ",\"" + segments + "\");";

  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

bool TaskManager::UpdateTraceTaskNormal(uint64_t task_id, TraceTask task) {
  std::string segments = task->Segments(SegGroup::GroupType::SEED);
  std::string sentence = "CALL omni_update_trace_task_normal(" + std::to_string(task_id)
                        + "," + std::to_string(om::system::Account::userid())
                        + ",\"" + segments + "\");";

  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

bool TaskManager::UpdateTraceTaskAuto(uint64_t task_id, TraceTask task) {
  std::string sentence = "CALL omni_update_trace_task_auto(" + std::to_string(task_id)
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}


TaskManager::CompareTask TaskManager::GetComparisonTask(uint64_t task_id, bool by_id, int taskstatus) {
  if( by_id )
    return GetComparisonTaskAnyway(task_id);

  switch( taskstatus ) {
    case (int)TaskSelectStatus::NORMAL:
      return GetComparisonTaskNormal(task_id);
    case (int)TaskSelectStatus::ONGOING:
    case (int)TaskSelectStatus::SKIPPED:
      break;
    case (int)TaskSelectStatus::COMPLETED:
      return GetComparisonTaskCompleted(task_id);
  }
  return nullptr;
}

TaskManager::CompareTask TaskManager::GetComparisonTaskNormal(uint64_t task_id) {
  std::string sentence = "CALL omni_get_compare_task_info_normal(" + std::to_string(task_id) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<ComparisonTask>(ComparisonTask(rsl));
}

TaskManager::CompareTask TaskManager::GetComparisonTaskCompleted(uint64_t task_id) {
  std::string sentence = "CALL omni_get_compare_task_info_completed(" + std::to_string(task_id) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<ComparisonTask>(ComparisonTask(rsl));
}

TaskManager::CompareTask TaskManager::GetComparisonTaskAnyway(uint64_t task_id) {
  std::string sentence = "CALL omni_get_compare_task_info_byid(" + std::to_string(task_id) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<ComparisonTask>(ComparisonTask(rsl));
}

bool TaskManager::UpdateRecordToStartComparisonTask(uint64_t task_id, CompareTask task) {
  std::string sentence = "CALL omni_update_to_start_comparison_task(" + std::to_string(task_id)
                        + "," + std::to_string(task->GroupID()) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";
                        
  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

bool TaskManager::UpdateTaskNotes(uint64_t task_id, std::string notes) {
  std::string sentence = "CALL omni_update_notes(" + std::to_string(task_id)
                        + ",\"" + notes + "\");";

  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

TaskManager::ViewTask TaskManager::GetViewingTask(uint64_t task_id) {
  std::string sentence = "CALL omni_get_view_task_info_byid(" + std::to_string(task_id) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<ViewingTask>(ViewingTask(rsl));
}

TaskManager::EditTask TaskManager::GetEditingTask(uint64_t task_id) {
  std::string sentence = "CALL omni_get_editing_task_info_byid(" + std::to_string(task_id) + ");";

  auto rsl = network::SqlQuery::ExecuteProcedure(sentence);
  if( !rsl || !rsl->first() )
    return nullptr;
  return std::make_shared<EditingTask>(EditingTask(rsl));
}


}  // namespace om::task::
}  // namespace om::