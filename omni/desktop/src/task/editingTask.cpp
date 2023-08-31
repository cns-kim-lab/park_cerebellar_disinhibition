#include "editingTask.h"
#include "project/omProject.h"
#include "system/omAppState.hpp"
#include "utility/segmentationDataWrapper.hpp"
#include "segment/omSegments.h"
#include "segment/selection.hpp"
#include "segment/omSegmentUtils.hpp"
#include "system/account.h"
#include "gui/mainWindow/mainWindow.h"
#include "viewGroup/omViewGroupState.h"
#include "gui/viewGroup/viewGroup.h"
#include "segment/omSegmentCenter.hpp"
#include "segment/lists/omSegmentLists.h"
#include "segment/omSegmentSelector.h"
#include "chunks/uniqueValues/omChunkUniqueValuesManager.hpp"
#include "segment/lowLevel/children.hpp"

#include "taskManager.h"

namespace om {
namespace task {

EditingTask::EditingTask() : id_(0), cellId_(0) {}

EditingTask::EditingTask(om::network::SqlQuery::SqlResultset rsl) {
  rsl->first();
  groups_.clear();

  id_ = rsl->getUInt64("id");
  cellId_ = rsl->getUInt64("cell_id");
  notes_ = rsl->getString("notes");
  path_ = rsl->getString("path");
  
  taskfrom_ = "Unknown";
  if( !rsl->isNull("spawning_coordinate") ) 
    taskfrom_ = rsl->getString("spawning_coordinate");

  om::task::SegGroup segset;
  om::common::SegID segid;
  std::stringstream ss(rsl->getString("seeds"));
  while( ss >> segid ) {
    segments_.insert(segid);
    if( ss.peek() == ' ' )
      ss.ignore();
  }
  segset.name = "seeds";
  segset.type = om::task::SegGroup::GroupType::SEED;
  segset.segments = segments_;
  groups_.push_back(segset);
}

EditingTask::~EditingTask() {}

bool EditingTask::Start() {
  if( path_.empty() || !OmAppState::OpenProject(path_, om::system::Account::username()) )
    return false;
  
  const SegmentationDataWrapper sdw(1);
  if (!sdw.IsValidWrapper()) 
    return false;
  sdw.Segments()->Selection().UpdateSegmentSelection(segments_, true);
  
  timer.start();
  return true;
}

bool EditingTask::Submit() {
  if( !OmProject::IsOpen() ) {
    log_errors << "not opened";
    return false;
  }

  uint32_t duration = (uint32_t)timer.s_elapsed();
  std::string segstr = "";
  const SegmentationDataWrapper sdw(1);
  if (!sdw.IsValidWrapper()) {
    log_errors << "not valid wrapper";
    return false;
  }
  const auto& rootIDs = sdw.Segments()->Selection().GetSelectedSegmentIDs();
  const auto& segments = OmSegmentUtils::GetAllChildrenSegments(*sdw.Segments(), rootIDs);
  for (OmSegment* seg : *segments) 
    segstr += std::to_string(seg->value()) + " ";
  
  std::string sentence = "CALL omni_submit_editing_task(" + std::to_string(Id()) 
                        + "," + std::to_string(om::system::Account::userid()) 
                        + ",\"" + segstr + "\"," + std::to_string(duration) + ");";
  
  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

bool EditingTask::Save() {
  if( !OmProject::IsOpen() )
    return false;
  return true;
}

bool EditingTask::Skip() {
  if( !OmProject::IsOpen() )
    return false;
  return true;
}


}  // namespace om::task::
}  // namespace om::
