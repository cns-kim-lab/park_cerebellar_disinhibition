#pragma once
#include "precomp.h"

#include "segment/omSegment.h"
#include "cache/objects.hpp"
#include "segment/lists/omSegmentListsTypes.hpp"

class OmSegmentLists;

class OmSegmentListByMRU {
 private:
  OmSegmentLists& segmentLists_;

  om::cache::KeyMultiIndex<OmSegment*> lru_;
  std::vector<SegInfo> vec_;
  bool dirty_;

  zi::mutex lock_;

 public:
  OmSegmentListByMRU(OmSegmentLists& segmentLists)
      : segmentLists_(segmentLists), dirty_(true) {}

  void Touch(OmSegment* seg) {
    zi::guard g(lock_);
    lru_.touch(seg);
    dirty_ = true;
  }

  std::shared_ptr<GUIPageOfSegments> GetSegmentGUIPage(
      const GUIPageRequest& request) {
    zi::guard g(lock_);

    if (dirty_) {
      rebuildList();
    }

    return om::segLists::getPage(vec_, request.offset, request.numToGet);
  }

  size_t Size() {
    zi::guard g(lock_);
    return lru_.Size();
  }

 private:
  void rebuildList();
};
