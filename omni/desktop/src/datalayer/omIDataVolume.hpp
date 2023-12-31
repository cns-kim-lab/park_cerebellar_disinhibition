#pragma once
#include "precomp.h"

#include "common/common.h"
#include "coordinates/chunk.h"

template <typename T>
class IDataVolume {
 public:
  virtual ~IDataVolume() {}

  virtual void Load() = 0;
  virtual void Create(const std::map<int, Vector3i>&) = 0;
  virtual T* GetPtr(const int level) const = 0;
  virtual T* GetChunkPtr(const om::coords::Chunk& coord) const = 0;
  virtual int GetBytesPerVoxel() const = 0;
};
