#pragma once
#include "precomp.h"

#include "chunks/omSegChunk.h"
#include "common/common.h"
#include "common/logging.h"
#include "mesh/drawer/omMeshSegmentListTask.h"
#include "mesh/drawer/omMeshSegmentListTypes.hpp"
#include "threads/taskManager.hpp"
#include "volume/omMipVolume.h"

#include "segment/omSegment.h"
#include "volume/omSegmentation.h"

class OmMeshSegmentList {
 private:
  static const int MAX_THREADS = 3;
  OmSegmentation* const segmentation_;

 public:
  OmMeshSegmentList(OmSegmentation* segmentation)
      : segmentation_(segmentation) {
    threadPool_.start(MAX_THREADS);
  }

  ~OmMeshSegmentList() {
    threadPool_.clear();
    threadPool_.stop();
  }

  boost::optional<OmSegPtrList> GetFromCacheIfReady(OmSegChunk* chunk,
                                                    OmSegment* rootSeg) {
    zi::guard g(lock_);

    OmSegPtrListValid& spList = mSegmentListCache[makeKey(chunk, rootSeg)];

    if (spList.isFetching) {  // coord already in queue to be fetched
      return boost::optional<OmSegPtrList>();
    }

    // remove from cache if freshness is too old
    const uint32_t currentFreshness = rootSeg->getFreshnessForMeshes();
    if (spList.isValid && currentFreshness != spList.freshness) {
      spList.list.clear();
      spList.isValid = false;
    }

    if (!spList.isValid) {  // add coord to list to be fetched
      spList = OmSegPtrListValid(true);

      std::shared_ptr<OmMeshSegmentListTask> task =
          std::make_shared<OmMeshSegmentListTask>(chunk, rootSeg, this,
                                                  segmentation_);

      threadPool_.push_back(task);
      return boost::optional<OmSegPtrList>();
    }

    // coord was valid
    return boost::optional<OmSegPtrList>(spList.list);
  }

  void AddToCache(OmSegChunk* chunk, OmSegment* rootSeg,
                  const OmSegPtrList& segmentsToDraw) {
    zi::guard g(lock_);

    mSegmentListCache[makeKey(chunk, rootSeg)] =
        OmSegPtrListValid(segmentsToDraw, rootSeg->getFreshnessForMeshes());
  }

 private:
  std::map<OmMeshSegListKey, OmSegPtrListValid> mSegmentListCache;
  om::thread::ThreadPool threadPool_;
  zi::mutex lock_;

  OmMeshSegListKey makeKey(OmSegChunk* chunk, OmSegment* rootSeg) {
    const om::coords::Chunk& c = chunk->GetCoordinate();
    return OmMeshSegListKey(segmentation_->GetID(), rootSeg->value(),
                            c.mipLevel(), c.x, c.y, c.z);
  }
};
