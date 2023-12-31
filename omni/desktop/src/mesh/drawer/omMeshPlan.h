#pragma once
#include "precomp.h"

#include "coordinates/chunk.h"
#include "segment/omSegment.h"

struct LargestSegmentFirst {
  bool operator()(const OmSegment* a, const OmSegment* b) const {
    return a->size() > b->size();
  }
};

typedef std::multimap<OmSegment*, om::coords::Chunk, LargestSegmentFirst>
    OmMeshPlanStruct;

class OmMeshPlan : public OmMeshPlanStruct {
 private:
  uint64_t voxelCount_;

 public:
  OmMeshPlan() : voxelCount_(0) {}

  void Add(OmSegment* seg, const om::coords::Chunk& coord) {
    insert(std::make_pair(seg, coord));
    voxelCount_ += seg->size();
  }

  uint64_t TotalVoxels() const { return voxelCount_; }
};
