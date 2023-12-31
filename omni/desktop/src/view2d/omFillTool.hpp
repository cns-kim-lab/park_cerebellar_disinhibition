#pragma once
#include "precomp.h"

#include "view2d/omView2dConverters.hpp"
#include "volume/omSegmentation.h"

class OmFillTool {
 private:
  const SegmentDataWrapper sdw_;
  const uint32_t newSegID_;
  OmSegmentation& vol_;
  const om::coords::GlobalBbox segDataExtent_;
  OmSegments& segments_;

  zi::semaphore semaphore_;

 public:
  OmFillTool(const SegmentDataWrapper& sdw)
      : sdw_(sdw),
        newSegID_(sdw.GetID()),
        vol_(*sdw.GetSegmentation()),
        segDataExtent_(vol_.Coords().Extent()),
        segments_(vol_.Segments()) {}

  ~OmFillTool() {}

  void Fill(const om::coords::Global& v) {
    if (!segDataExtent_.contains(v)) {
      return;
    }

    const om::common::SegID segIDtoReplace =
        segments_.FindRootID(vol_.GetVoxelValue(v));

    vol_.SetVoxelValue(v, newSegID_);

    std::deque<om::coords::Global> voxels;

    voxels.push_back(om::coords::Global(v.x - 1, v.y, v.z));
    voxels.push_back(om::coords::Global(v.x + 1, v.y, v.z));
    voxels.push_back(om::coords::Global(v.x, v.y - 1, v.z));
    voxels.push_back(om::coords::Global(v.x, v.y + 1, v.z));

    semaphore_.set(0);

    FOR_EACH(iter, voxels) {
      OmView2dManager::AddTaskBack(zi::run_fn(
          zi::bind(&OmFillTool::doFill, this, *iter, segIDtoReplace)));
    }

    semaphore_.acquire(voxels.size());

    clearCaches();

    om::event::Redraw2d();
  }

 private:
  void doFill(const om::coords::Global voxelLocStart,
              const om::common::SegID segIDtoReplace) {
    std::deque<om::coords::Global> voxels;
    voxels.push_back(voxelLocStart);

    om::coords::Global v;

    while (!voxels.empty()) {
      v = voxels.back();
      voxels.pop_back();

      if (!segDataExtent_.contains(v)) {
        continue;
      }

      const om::common::SegID curSegID = vol_.GetVoxelValue(v);

      if (newSegID_ == curSegID) {
        continue;
      }

      if (segIDtoReplace != curSegID &&
          segIDtoReplace != segments_.FindRootID(curSegID)) {
        continue;
      }

      vol_.SetVoxelValue(v, newSegID_);

      // TODO: assumes om::common::XY_VIEW for now
      voxels.push_back(om::coords::Global(v.x - 1, v.y, v.z));
      voxels.push_back(om::coords::Global(v.x + 1, v.y, v.z));
      voxels.push_back(om::coords::Global(v.x, v.y - 1, v.z));
      voxels.push_back(om::coords::Global(v.x, v.y + 1, v.z));
    }

    semaphore_.release(1);
  }

  void clearCaches() {
    vol_.SliceCache().Clear();
    OmTileCache::ClearSegmentation();
  }
};
