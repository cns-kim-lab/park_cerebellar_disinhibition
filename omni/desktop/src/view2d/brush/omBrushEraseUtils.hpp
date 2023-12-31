#pragma once
#include "precomp.h"

#include "events/events.h"
#include "actions/omActions.h"
#include "tiles/cache/omTileCache.h"
#include "view2d/brush/omBrushOppTypes.h"

#include "system/cache/omRawSegTileCache.hpp"
#include "utility/segmentationDataWrapper.hpp"

class OmBrushEraseUtils {
 public:
  static void ErasePts(OmBrushOppInfo* info, om::pt3d_list_t* pts,
                       const om::common::SegID segIDtoErase) {
    const om::coords::GlobalBbox& segDataExtent =
        info->segmentation->Coords().GetDataExtent();

    std::set<Vector3i> voxelCoords;

    OmChunksAndPts chunksAndPts(info->segmentation);

    FOR_EACH(iter, *pts) {
      if (!segDataExtent.contains(*iter)) {
        continue;
      }

      chunksAndPts.AddPtAbsVoxelLoc(*iter);
    }

    OmSliceCache sliceCache(info->segmentation, info->viewType);

    virtual std::shared_ptr<om::common::SegIDSet>
        segIDsAndPts = sliceCache.GetSegIDs(chunksAndPts, info->depth);

    FOR_EACH(iter, *pts) {
      if (!segDataExtent.contains(*iter)) {
        continue;
      }

      voxelCoords.insert(*iter);
    }

    if (!voxelCoords.size()) {
      return;
    }

    OmActions::SetVoxels(info->segmentation->GetID(), voxelCoords,
                         segIDtoErase);

    removeModifiedTiles();

    om::event::Redraw2d();
  }

 private:
  static void removeModifiedTiles() {
    // const int chunkDim = info->chunkDim;

    // std::map<om::coords::Chunk, std::set<Vector3i> > ptsInChunks;

    // FOR_EACH(iter, voxelCoords)
    // {
    //     const om::coords::Chunk chunkCoord(0,
    //                                   iter->x / chunkDim,
    //                                   iter->y / chunkDim,
    //                                   iter->z / chunkDim);

    //     const Vector3i chunkPos(iter->x % chunkDim,
    //                             iter->y % chunkDim,
    //                             iter->z % chunkDim);

    //     OmTileCache::RemoveDataCoord(Vector3i(iter->x / chunkDim,
    //                                           iter->y / chunkDim,
    //                                           iter->z % chunkDim));

    //     ptsInChunks[chunkCoord].insert(chunkPos);
    // }

    const auto& segset = SegmentationDataWrapper::ValidIDs();

    FOR_EACH(iter, segset) {
      SegmentationDataWrapper sdw(*iter);
      OmSegmentation& seg = sdw.GetSegmentation();
      OmRawSegTileCache* sliceCache = seg.SliceCache();
      sliceCache->Clear();
    }

    OmTileCache::ClearSegmentation();
  }
};
