#include "tracingTask.h"
#include "project/omProject.h"
#include "system/omAppState.hpp"
#include "utility/segmentationDataWrapper.hpp"
#include "segment/omSegments.h"
#include "segment/selection.hpp"
#include "segment/omSegmentUtils.hpp"
#include "system/account.h"
#include "network/http/http.hpp"
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

TracingTask::TracingTask() : id_(0), cellId_(0) {}

TracingTask::TracingTask(uint32_t id, uint32_t cellId, const std::string& path,
                         common::SegIDSet&& seed)
    : id_(id), cellId_(cellId), path_(path), seed_(seed) {}

TracingTask::TracingTask(om::network::SqlQuery::SqlResultset queryRsl) {  //jwgim 
  id_ = queryRsl->getUInt64("id");
  cellId_ = queryRsl->getUInt64("cell_id");
  path_ = queryRsl->getString("path");
  notes_ = queryRsl->getString("notes");
    
  parentID_ = 0;  //temp
  weight_ = 0.0f;
  weightSum_ = 0;
  users_ = "";
  taskfrom_ = "Unknown";
  if( !queryRsl->isNull("spawning_coordinate") ) 
    taskfrom_ = queryRsl->getString("spawning_coordinate");

  seed_.clear();
  om::task::SegGroup seed;  
  om::common::SegID segid;
  if( queryRsl->findColumn("segments")>0 && !queryRsl->isNull("segments") ) {
    std::stringstream ss(queryRsl->getString("segments"));
    while( ss >> segid ) {
      seed_.insert(segid);
      if( ss.peek() == ' ' )
        ss.ignore();
    }  
    seed.name = "tracing";
    seed.type = om::task::SegGroup::GroupType::USER_FOUND; 
    seed.segments = seed_;
    groups_.push_back(seed);
  }
  std::stringstream sstream(queryRsl->getString("seeds"));
  seed_.clear();
  while( sstream >> segid ) {
    seed_.insert(segid);
    if( sstream.peek() == ' ' )
      sstream.ignore();
  }  
  seed.name = "seeds";
  seed.type = om::task::SegGroup::GroupType::SEED;    
  seed.segments = seed_;
  groups_.push_back(seed);
}

TracingTask::~TracingTask() {}

bool TracingTask::Start() {
  if (path_.empty() ||
      !OmAppState::OpenProject(path_, om::system::Account::username())) {
    return false;
  }
  const SegmentationDataWrapper sdw(1);
  if (!sdw.IsValidWrapper()) {
    return false;
  }
  sdw.Segments()->Selection().UpdateSegmentSelection(seed_, true);

  timer.start();
  return true;
}

bool TracingTask::Submit() {
  if( !Save() ) 
    return false;

  std::string sentence = "CALL omni_submit_trace_task(" + std::to_string(Id()) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";
  
  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

std::string TracingTask::Segments(SegGroup::GroupType gtype) {
  std::string segment_str = "";
  switch( gtype ) {
    case SegGroup::GroupType::SEED: 
    case SegGroup::GroupType::USER_FOUND:
      break;
    case SegGroup::GroupType::ALL:
    case SegGroup::GroupType::AGREED:
    case SegGroup::GroupType::DUST:
    case SegGroup::GroupType::PARTIAL:
    case SegGroup::GroupType::USER_MISSED:
    default:
      log_infos <<  __FUNCTION__ << "," << (int)gtype << " not implemented yet";
      return segment_str;
  }

  int index =0;
  for( index=0; index < groups_.size(); index++ ) {
    if( groups_.at(index).type == gtype )
      break;
  }

  common::SegIDSet segments = groups_.at(index).segments;
  for( auto item:segments )
    segment_str += std::to_string(item) + " ";    

  return segment_str;
}

bool TracingTask::Save() {
  if (!OmProject::IsOpen()) 
    return false;

  uint32_t duration = (uint32_t)timer.s_elapsed();
  std::string segstr = "";
  const SegmentationDataWrapper sdw(1);
  if (!sdw.IsValidWrapper()) 
    return false;
  const auto& rootIDs = sdw.Segments()->Selection().GetSelectedSegmentIDs();
  const auto& segments = OmSegmentUtils::GetAllChildrenSegments(*sdw.Segments(), rootIDs);
  for (OmSegment* seg : *segments) 
    segstr += std::to_string(seg->value()) + " ";

  std::string sentence = "CALL omni_save_trace_task(" + std::to_string(Id()) 
                        + "," + std::to_string(om::system::Account::userid()) 
                        + ",\"" + segstr + "\"," + std::to_string(duration) + ");";

  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

bool TracingTask::Skip() {
  if (!OmProject::IsOpen()) 
    return false;
  if( !Save() ) 
    return false;

  std::string sentence = "CALL omni_skip_trace_task(" + std::to_string(Id()) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";
  
  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

}  // namespace om::task::
}  // namespace om::
