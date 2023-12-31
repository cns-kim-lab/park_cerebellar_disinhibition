#pragma once
#include "precomp.h"

#include "chunks/uniqueValues/omChunkUniqueValuesPerThreshold.hpp"
#include "chunks/uniqueValues/omThresholdsInChunk.hpp"
#include "chunks/omChunkItemContainer.hpp"

class OmChunkUniqueValuesManager {
 private:
  typedef OmChunkItemContainer<OmSegmentation, OmThresholdsInChunk> cont_t;
  std::unique_ptr<cont_t> chunks_;

  void UpdateFromVolResize() { chunks_->UpdateFromVolResize(); }

  friend class OmSegmentation;

 public:
  OmChunkUniqueValuesManager(OmSegmentation* segmentation)
      : chunks_(new cont_t(segmentation)) {}

  ChunkUniqueValues Values(const om::coords::Chunk& coord,
                           const double threshold) {
    OmThresholdsInChunk* thresholdsInChunk = chunks_->Get(coord);
    return thresholdsInChunk->Get(threshold)->Values();
  }

  ChunkUniqueValues Get(const om::coords::Chunk& coord) {
    return Values(coord, 1);
  }

  ChunkUniqueValues RereadChunk(const om::coords::Chunk& coord,
                                const double threshold) {
    OmThresholdsInChunk* thresholdsInChunk = chunks_->Get(coord);
    return thresholdsInChunk->Get(threshold)->RereadChunk();
  }

  void Clear() { chunks_->Clear(); }
};
