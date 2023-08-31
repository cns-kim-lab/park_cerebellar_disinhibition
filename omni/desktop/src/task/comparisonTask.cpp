#include "chunk/voxelGetter.hpp"
#include "chunks/uniqueValues/omChunkUniqueValuesManager.hpp"
#include "comparisonTask.h"
#include "network/http/http.hpp"
#include "project/omProject.h"
#include "segment/lists/omSegmentLists.h"
#include "segment/lowLevel/children.hpp"
#include "segment/omSegments.h"
#include "segment/omSegmentSelector.h"
#include "segment/omSegmentUtils.hpp"
#include "segment/selection.hpp"
#include "segment/types.hpp"
#include "system/account.h"
#include "system/cache/omCacheManager.h"
#include "system/omAppState.hpp"
#include "users/omUsers.h"
#include "utility/segmentationDataWrapper.hpp"
#include "utility/volumeWalker.hpp"
#include "volume/omSegmentation.h"
#include "volume/isegmentation.hpp"

namespace om {
namespace task {

ComparisonTask::ComparisonTask(uint64_t id, uint64_t cellId,
                               const std::string& path,
                               std::vector<SegGroup>&& namedGroups)
    : id_(id), cellId_(cellId), path_(path), namedGroups_(namedGroups) {}

ComparisonTask::~ComparisonTask() {}

ComparisonTask::ComparisonTask(om::network::SqlQuery::SqlResultset rsl) {
  rsl->first();
  
  if( rsl->rowsCount() < 4 ) { 
    log_errors << "Comparison data is not enough";
    return;
  }
  
  id_ = rsl->getUInt64("id");
  cellId_ = rsl->getUInt64("cell_id");
  notes_ = rsl->getString("notes");
  path_ = rsl->getString("path");
  groupId_ = rsl->getUInt64("group_id");
  
  parentID_ = 0;  //temp
  weight_ = 0.0f;
  weightSum_ = 0;
  users_ = "";  
  std::string fakemask = "A";

  taskfrom_ = "Unknown";
  if( !rsl->isNull("spawning_coordinate") ) 
    taskfrom_ = rsl->getString("spawning_coordinate");

  common::SegIDSet segall;
  common::SegIDSet segset;
  om::common::SegID segid;
  om::task::SegGroup group_data;
  size_t total_size = 0;
  char line_delim = ';';

  segall.clear();
  std::string seed_str = rsl->getString("seeds");
  std::stringstream stream_seed(seed_str);
  segset.clear();  
  while( stream_seed >> segid ) {
    segset.insert(segid);
    if( stream_seed.peek() == ' ' )
      stream_seed.ignore();
  }
  group_data.name = "seed";
  group_data.type = om::task::SegGroup::GroupType::SEED;
  group_data.segments = segset;
  namedGroups_.push_back(group_data);
  segall.insert(segset.begin(), segset.end());

  do {    
    std::string group_str = rsl->getString("segment_groups");
    std::string size_str = rsl->getString("segment_group_sizes");
    uint32_t record_type = rsl->getUInt("type");

    std::stringstream stream_group(group_str);
    std::stringstream stream_size(size_str);
    std::string each_group;
    std::string each_size;
    if( record_type == 0 ) {  //agreed
      segset.clear();
      while( stream_group >> segid ) {
        segset.insert(segid);
        if( stream_group.peek() == ' ' )
          stream_group.ignore();
      }
      group_data.name = "agreed:" + size_str + "%";
      group_data.type = om::task::SegGroup::GroupType::AGREED;
      group_data.size = (unsigned int)(stof(size_str)*100.0);
      group_data.segments = segset;
      namedGroups_.push_back(group_data);
      segall.insert(segset.begin(), segset.end());
      total_size += group_data.size;
    }
    else if( record_type == 1 ) { //user found
      while( std::getline(stream_group, each_group, line_delim) ) {
        segset.clear();
        std::stringstream stream_(each_group);
        while( stream_ >> segid ) {
          segset.insert(segid);
          if( stream_.peek() == ' ' )
            stream_.ignore();
        }
        std::getline(stream_size, each_size, line_delim);
        //group_data.name = rsl->getString("name") + ":" + each_size + "%";
        group_data.name = fakemask + ":" + each_size + "%";
        group_data.type = om::task::SegGroup::GroupType::USER_FOUND;
        group_data.size = (unsigned int)(stof(each_size)*100.0);
        group_data.segments = segset;
        namedGroups_.push_back(group_data);
        segall.insert(segset.begin(), segset.end());
        total_size += group_data.size;
      }
      fakemask = "B";
    }
    else { //dust
      segset.clear();
      while( stream_group >> segid ) {
        segset.insert(segid);
        if( stream_group.peek() == ' ' )
          stream_group.ignore();
      }
      group_data.name = "dust";
      group_data.type = om::task::SegGroup::GroupType::DUST;
      group_data.size = (unsigned int)(stof(size_str)*100.0);
      group_data.segments = segset;
      namedGroups_.push_back(group_data);
      segall.insert(segset.begin(), segset.end());
      total_size += group_data.size;
    }
  } while(rsl->next());

  group_data.name = "all";
  group_data.type = om::task::SegGroup::GroupType::ALL;
  group_data.segments = segall;
  group_data.size = total_size;
  namedGroups_.push_back(group_data);  
}

bool ComparisonTask::Start() {
  if (!OmAppState::OpenProject(path_, om::users::defaultUser)) {
    return false;
  }
  const SegmentationDataWrapper sdw(1);
  if (!sdw.IsValidWrapper()) {
    return false;
  }

  log_debugs << "Starting Comparison Task.";

  timer.start();
  OmSegmentation* segmentation = sdw.GetSegmentation();
  OmSegments& segments = segmentation->Segments();

  segmentation->ClearUserChangesAndSave();
  sdw.SegmentLists()->RefreshGUIlists();

  auto seedIter = std::find_if(
      namedGroups_.begin(), namedGroups_.end(),
      [](const SegGroup& g) { return g.type == SegGroup::GroupType::SEED; });
  auto agreedIter = std::find_if(
      namedGroups_.begin(), namedGroups_.end(),
      [](const SegGroup& g) { return g.type == SegGroup::GroupType::AGREED; });
  std::map<SegGroup::GroupType, std::string> typeString{
      {SegGroup::GroupType::SEED, "Seed"},
      {SegGroup::GroupType::AGREED, "Agreed"}};
  common::SegIDSet allRoots;
  for (auto iter : {seedIter, agreedIter}) {
    if (iter != namedGroups_.end()) {
      for (const auto& id : iter->segments) {
        if (id <= 0 || id > segments.maxValue()) {
          log_errors << "Invalid segment id " << id << " in "
                     << typeString[iter->type] << " segment group.";
          continue;
        }
        auto rootID = segments.FindRootID(id);
        if (rootID) {
          allRoots.insert(rootID);
        }
      }
    }
  }
  if (allRoots.size() > 0) {
    segments.Selection().UpdateSegmentSelection(allRoots, true);
  } else {
    // clear any pre-existing selection (which could exist if the previous task
    // happened to be in the same volume)
    segments.Selection().UpdateSegmentSelection({}, true);
    log_errors << "No segments in Seed segments group.";
  }

  om::event::Redraw2d();
  om::event::Redraw3d();
  return true;
}

bool ComparisonTask::chunkHasUserSegments(
    OmChunkUniqueValuesManager& uniqueValues, const om::coords::Chunk& chunk,
    const std::unordered_map<common::SegID, int>& segFlags) {

  const auto uv = uniqueValues.Get(chunk);
  for (auto& segID : uv) {
    if (segFlags.find(segID) != segFlags.end()) {
      return true;
    }
  }
  return false;
}

bool ComparisonTask::Submit() {
  if (!OmProject::IsOpen()) 
    return false;

  uint32_t duration = (uint32_t)timer.s_elapsed();  //jwgim
  std::string segstr = "";

  std::unordered_map<common::SegID, int> segIDs;
  const SegmentationDataWrapper sdw(1);
  if (!sdw.IsValidWrapper()) 
    return false;
  const auto& rootIDs = sdw.Segments()->Selection().GetSelectedSegmentIDs();
  const auto& segments = OmSegmentUtils::GetAllChildrenSegments(*sdw.Segments(), rootIDs);
  for (OmSegment* seg : *segments) 
    segstr += std::to_string(seg->value()) + " ";
  
  std::string sentence = "CALL omni_submit_comparison_task(" + std::to_string(Id()) 
                        + "," + std::to_string(GroupID()) 
                        + "," + std::to_string(om::system::Account::userid()) 
                        + "," + std::to_string(duration) 
                        + ",\"" + segstr + "\");";

  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

bool ComparisonTask::Save() {
  return Skip();
}

bool ComparisonTask::Skip() {
  if (!OmProject::IsOpen()) 
    return false;

  std::string sentence = "CALL omni_skip_comparison_task(" + std::to_string(Id()) 
                        + "," + std::to_string(GroupID()) 
                        + "," + std::to_string(om::system::Account::userid()) + ");";
  return network::SqlQuery::ExecuteUpdateProcedure(sentence);
}

}  // namespace om::task::
}  // namespace om::
