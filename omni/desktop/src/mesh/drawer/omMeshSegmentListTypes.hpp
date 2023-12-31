#pragma once
#include "precomp.h"

#include "common/common.h"
#include "mesh/drawer/omSegmentPointers.h"

// segmentation ID, segment ID, mip level, x, y, z
typedef std::tuple<om::common::ID, om::common::SegID, int, int, int, int>
    OmMeshSegListKey;

class OmSegPtrListValid {
 public:
  OmSegPtrListValid() : isValid(false), freshness(0), isFetching(false) {}
  explicit OmSegPtrListValid(const bool isFetching)
      : isValid(false), freshness(0), isFetching(isFetching) {}
  OmSegPtrListValid(const OmSegPtrList& L, const uint32_t f)
      : isValid(true), list(L), freshness(f), isFetching(false) {}

  bool isValid;
  OmSegPtrList list;
  uint32_t freshness;
  bool isFetching;
};
