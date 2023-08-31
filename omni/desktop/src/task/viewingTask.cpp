#include "viewingTask.h"
#include "project/omProject.h"
#include "system/omAppState.hpp"
#include "utility/segmentationDataWrapper.hpp"
#include "segment/omSegments.h"
#include "segment/selection.hpp"
#include "segment/omSegmentUtils.hpp"
#include "gui/mainWindow/mainWindow.h"
#include "viewGroup/omViewGroupState.h"
#include "gui/viewGroup/viewGroup.h"
#include "segment/omSegmentCenter.hpp"
#include "segment/lists/omSegmentLists.h"
#include "segment/omSegmentSelector.h"
#include "chunks/uniqueValues/omChunkUniqueValuesManager.hpp"
#include "segment/lowLevel/children.hpp"
#include "users/omUsers.h"

#include "taskManager.h"

namespace om {
namespace task {
ViewingTask::ViewingTask() : id_(0), cellId_(0) {}

ViewingTask::ViewingTask(om::network::SqlQuery::SqlResultset rsl) {
  rsl->first();
  if( rsl->isNull("segments") ) {
    log_errors << "ViewingTask : data is not enough";
    return;
  }
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
  std::stringstream ss(rsl->getString("segments"));
  while( ss >> segid ) {
    segments_.insert(segid);
    if( ss.peek() == ' ' )
      ss.ignore();
  }
  segset.name = "consensus";
  segset.type = om::task::SegGroup::GroupType::ALL;
  segset.segments = segments_;
  groups_.push_back(segset);
}

ViewingTask::~ViewingTask() {}

bool ViewingTask::Start() {
  if( path_.empty() || !OmAppState::OpenProject(path_, om::users::defaultUser) )
    return false;
  
  const SegmentationDataWrapper sdw(1);
  if (!sdw.IsValidWrapper()) 
    return false;
  sdw.Segments()->Selection().UpdateSegmentSelection(segments_, true);
  
  return true;
}

bool ViewingTask::Submit() {
  if( !OmProject::IsOpen() )
    return false;
  return true;
}

bool ViewingTask::Save() {
  if( !OmProject::IsOpen() )
    return false;
  return true;
}

bool ViewingTask::Skip() {
  if( !OmProject::IsOpen() )
    return false;
  return true;
}

}  // namespace om::task::
}  // namespace om::
