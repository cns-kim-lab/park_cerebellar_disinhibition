#pragma once
#include "precomp.h"

#include "chunks/omRawChunk.hpp"
#include "chunks/omExtractSegTile.hpp"
#include "chunks/omSegChunk.h"
#include "segment/omSegments.h"
#include "utility/omChunkVoxelWalker.hpp"
#include "volume/build/omProcessSegmentationChunk.hpp"
#include "volume/omSegmentation.h"
#include "chunks/details/omPtrToChunkDataMemMapVol.h"

namespace om {
namespace segchunk {

using om::chunk::dataAccessor;
using om::chunk::ptrToChunkDataBase;
using om::chunk::ptrToChunkDataMemMapVol;

template <typename DATA>
class dataImpl : public dataInterface {
 private:
  OmSegmentation& vol_;
  OmSegChunk& chunk_;
  const om::coords::Chunk coord_;

  ptrToChunkDataBase* const ptrToChunkData_;

  const int elementsPerRow_;
  const int elementsPerSlice_;

 public:
  dataImpl(OmSegmentation& vol, OmSegChunk& chunk,
           const om::coords::Chunk& coord)
      : vol_(vol),
        chunk_(chunk),
        coord_(coord),
        ptrToChunkData_(new ptrToChunkDataMemMapVol<DATA>(vol, coord)),
        elementsPerRow_(128),
        elementsPerSlice_(128 * 128) {}

  ~dataImpl() { delete ptrToChunkData_; }

  std::shared_ptr<uint32_t> ExtractDataSlice32bit(
      const om::common::ViewType plane, const int depth) {
    dataAccessor<DATA> dataWrapper(ptrToChunkData_);
    DATA* data = dataWrapper.Data();

    OmExtractSegTile extractor(&vol_, coord_, plane, depth);
    return extractor.Extract(data);
  }

  void ProcessChunk(const bool computeSizes, OmSegments& segments) {
    OmProcessSegmentationChunk p(&chunk_, computeSizes, &segments);

    dataAccessor<DATA> dataWrapper(ptrToChunkData_);
    DATA* data = dataWrapper.Data();

    OmChunkVoxelWalker iter(128);

    for (iter.begin(); iter < iter.end(); ++iter) {
      const om::common::SegID val = static_cast<om::common::SegID>(*data++);

      if (val) {
        p.processVoxel(val, *iter);
      }
    }
  }

  void RefreshBoundingData(OmSegments& segments) {
    OmProcessSegmentationChunk p(&chunk_, false, &segments);

    dataAccessor<DATA> dataWrapper(ptrToChunkData_);
    DATA* data = dataWrapper.Data();

    OmChunkVoxelWalker iter(128);

    for (iter.begin(); iter < iter.end(); ++iter) {
      const om::common::SegID val = static_cast<om::common::SegID>(*data++);

      if (val) {
        p.processVoxel(val, *iter);
      }
    }
  }

  uint32_t SetVoxelValue(const om::coords::Data& voxel, const uint32_t val) {
    dataAccessor<DATA> dataWrapper(ptrToChunkData_);
    DATA* data = dataWrapper.Data();

    const int offset = voxel.ToChunkOffset();

    const uint32_t oldVal = data[offset];
    data[offset] = val;

    return oldVal;
  }

  uint32_t GetVoxelValue(const om::coords::Data& voxel) {
    dataAccessor<DATA> dataWrapper(ptrToChunkData_);
    DATA* data = dataWrapper.Data();

    return data[voxel.ToChunkOffset()];
  }

  void RewriteChunk(const std::unordered_map<uint32_t, uint32_t>& vals) {
    OmRawChunk<DATA> rawChunk(vol_, chunk_.GetCoordinate());
    rawChunk.SetDirty();

    DATA* d = rawChunk.Data();

    const int numVoxelsInChunk = chunk_.Mipping().NumVoxels();

    for (int i = 0; i < numVoxelsInChunk; ++i) {
      d[i] = vals.at(d[i]);
    }
  }

  std::shared_ptr<uint32_t> GetCopyOfChunkDataAsUint32() {
    dataAccessor<DATA> dataWrapper(ptrToChunkData_);
    DATA* data = dataWrapper.Data();

    return getChunkAs32bit(data);
  }

 private:
  template <typename T>
  std::shared_ptr<uint32_t> getChunkAs32bit(T*) const {
    OmRawChunk<T> rawChunk(vol_, chunk_.GetCoordinate());

    std::shared_ptr<T> data = rawChunk.SharedPtr();
    T* dataRaw = data.get();

    const int numVoxelsInChunk = chunk_.Mipping().NumVoxels();

    auto ret = om::mem::Malloc<uint32_t>::NumElements(numVoxelsInChunk,
                                                      om::mem::ZeroFill::DONT);
    std::copy(dataRaw, dataRaw + numVoxelsInChunk, ret.get());

    return ret;
  }

  std::shared_ptr<uint32_t> getChunkAs32bit(uint32_t*) const {
    OmRawChunk<uint32_t> rawChunk(vol_, chunk_.GetCoordinate());
    return rawChunk.SharedPtr();
  }

  std::shared_ptr<uint32_t> getChunkAs32bit(float*) const {
    throw om::IoException("can't deal with float data!");
  }
};

}  // namespace segchunk
}  // namespace om
