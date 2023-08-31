#pragma once
#include "precomp.h"

#include "zi/utility.h"
#include "task/cell.h"
#include "task/taskInfo.hpp"
#include "task/dataset.h"
#include "events/listeners.h"
#include "network/http/httpCache.hpp"

#include "network/sqlQuery.h"

namespace om {
namespace task {

class Task;
class TracingTask;
class ComparisonTask;
class ViewingTask;
class EditingTask;

enum class TaskSelectType {
    TRACE,
    COMPARE,
};
enum class TaskSelectStatus {
    NORMAL,
    ONGOING,
    SKIPPED,
    COMPLETED,
};

int confirmSaveAndClose();

class TaskManager : private om::SingletonBase<TaskManager>,
                    public om::event::ConnectionEventListener {
 public:
  static const std::shared_ptr<Task>& currentTask() {
    return instance().currentTask_;
  }
  typedef std::shared_ptr<network::http::TypedGetRequest<TracingTask>>
      TracingTaskRequest;
  typedef std::shared_ptr<network::http::TypedGetRequest<ComparisonTask>>
      ComparisonTaskRequest;
  typedef std::shared_ptr<network::http::TypedGetRequest<std::vector<TaskInfo>>>
      TaskInfosRequest;
  typedef std::shared_ptr<network::http::TypedGetRequest<std::vector<Dataset>>>
      DatasetsRequest;
  typedef std::shared_ptr<network::http::TypedGetRequest<std::vector<Cell>>>
      CellsRequest;

  static bool LoadTask(std::shared_ptr<Task> task);
  static bool AttemptFinishTask();
  static bool SubmitTask(bool byshortcut);
  static std::shared_ptr<Task> FindInterruptedTask();
  static void Refresh();

  void ConnectionChangeEvent();

  //jwgim  
  typedef std::shared_ptr<TracingTask> TraceTask;
  typedef std::shared_ptr<ComparisonTask> CompareTask;
  typedef std::shared_ptr<ViewingTask> ViewTask;
  typedef std::shared_ptr<EditingTask> EditTask;

  static std::vector<std::string>* GetDatasetIDs();
  static std::vector<std::string>* GetCellIDs(uint32_t dataset_id);
  static std::vector<TaskInfo>* GetTaskinfoByID(uint64_t task_id);
  static bool UpdateRecordToStartTraceTask(uint64_t task_id, bool by_id, int taskstatus, TraceTask task);
  static std::vector<TaskInfo>* GetTasklist(uint32_t dataset_id, uint64_t cell_id, int tasktype, int taskstatus);
  static TraceTask GetTracingTask(uint64_t task_id, bool by_id, int taskstatus);
  static CompareTask GetComparisonTask(uint64_t task_id, bool by_id, int taskstatus);
  static bool UpdateRecordToStartComparisonTask(uint64_t task_id, CompareTask task);
  static bool UpdateTaskNotes(uint64_t task_id, std::string notes);
  static ViewTask GetViewingTask(uint64_t task_id);
  static EditTask GetEditingTask(uint64_t task_id);
  
  static bool AttemptSkipTask();

 private:
 std::shared_ptr<Task> currentTask_;
  TaskManager() : currentTask_(nullptr) {}
  ~TaskManager();  
  
  static std::vector<TaskInfo>* GetOngoingTraceTaskList(uint32_t dataset_id, uint64_t cell_id);
  static std::vector<TaskInfo>* GetCompletedTraceTaskList(uint32_t dataset_id, uint64_t cell_id);
  static std::vector<TaskInfo>* GetSkippedTraceTaskList(uint32_t dataset_id, uint64_t cell_id);
  static std::vector<TaskInfo>* GetNormalTraceTaskList(uint32_t dataset_id, uint64_t cell_id);
  static void FillTaskinfolistBySqlResultSet(om::network::SqlQuery::SqlResultset rsl);
  static TraceTask GetTracingTaskAnyway(uint64_t task_id);
  static TraceTask GetTracingTaskOngoing(uint64_t task_id);
  static TraceTask GetTracingTaskSkipped(uint64_t task_id);
  static TraceTask GetTracingTaskCompleted(uint64_t task_id);
  static TraceTask GetTracingTaskNormal(uint64_t task_id);
  static bool UpdateTraceTaskOngoing(uint64_t task_id, TraceTask task);
  static bool UpdateTraceTaskSkipped(uint64_t task_id, TraceTask task);
  static bool UpdateTraceTaskCompleted(uint64_t task_id, TraceTask task);
  static bool UpdateTraceTaskNormal(uint64_t task_id, TraceTask task);
  static bool UpdateTraceTaskAuto(uint64_t task_id, TraceTask task);

  static std::vector<TaskInfo>* GetNormalCompareTaskList(uint64_t cell_id);
  static std::vector<TaskInfo>* GetCompletedCompareTaskList(uint64_t cell_id);
  static CompareTask GetComparisonTaskNormal(uint64_t task_id);
  static CompareTask GetComparisonTaskCompleted(uint64_t task_id);
  static CompareTask GetComparisonTaskAnyway(uint64_t task_id);
  
  std::vector<std::string> datasetIDs;
  std::vector<std::string> cellIDs;
  std::vector<TaskInfo> taskList;    

  friend class zi::singleton<TaskManager>;
};

}  // namespace om::task::
}  // namespace om::
