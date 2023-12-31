#pragma once
#include "precomp.h"

#include "events/events.h"
#include "actions/omActions.h"
#include "tiles/cache/omTileCache.h"
#include "view2d/brush/omBrushOppTypes.h"

#include "tiles/cache/raw/omRawSegTileCache.hpp"
#include "utility/segmentationDataWrapper.hpp"

class OmBrushPaintUtils {
 public:
  static void PaintPts(OmBrushOppInfo* info, om::pt3d_list_t* pts,
                       const om::common::SegID segIDtoPaint) {
    const om::coords::GlobalBbox& segDataExtent =
        info->segmentation->Coords().Extent();

    std::set<om::coords::Global> voxelCoords;

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
                         segIDtoPaint);

    removeModifiedTiles();

    om::event::Redraw2dBlocking();
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

    for (auto& seg : SegmentationDataWrapper::GetPtrVec()) {
      seg->SliceCache().Clear();
    }

    OmTileCache::ClearSegmentation();
  }
};
