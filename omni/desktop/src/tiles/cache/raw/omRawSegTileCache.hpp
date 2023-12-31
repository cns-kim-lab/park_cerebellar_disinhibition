#pragma once
#include "precomp.h"

#include "volume/omMipVolume.h"
#include "system/cache/omGetSetCache.hpp"

// mip, x, y, z, depth, plane
typedef std::tuple<int, int, int, int, int, om::common::ViewType>
    OmVolSliceKey_t;

struct OmVolSliceKey : public OmVolSliceKey_t {
  OmVolSliceKey() : OmVolSliceKey_t(-1, -1, -1, -1, -1, om::common::XY_VIEW) {}

  OmVolSliceKey(const om::coords::Chunk& chunkCoord, const int sliceDepth,
                const om::common::ViewType viewType)
      : OmVolSliceKey_t(chunkCoord.mipLevel(), chunkCoord.x, chunkCoord.y,
                        chunkCoord.z, sliceDepth, viewType) {}
};

class OmRawSegTileCache {
 private:
  OmMipVolume* const vol_;

  typedef OmGetSetCache<OmVolSliceKey, std::shared_ptr<uint32_t>> cache_t;
  std::unique_ptr<cache_t> cache_;

 public:
  OmRawSegTileCache(OmMipVolume* vol) : vol_(vol) {}

  void Load() {
    cache_.reset(new cache_t(om::common::CacheGroup::TILE_CACHE, "slice cache",
                             vol_->GetBytesPerSlice()));
  }

  void Clear() { cache_->Clear(); }

  std::shared_ptr<uint32_t> Get(const om::coords::Chunk& chunkCoord,
                                const int sliceDepth,
                                const om::common::ViewType viewType) {
    const OmVolSliceKey key(chunkCoord, sliceDepth, viewType);
    return cache_->Get(key);
  }

  void Set(const om::coords::Chunk& chunkCoord, const int sliceDepth,
           const om::common::ViewType viewType,
           std::shared_ptr<uint32_t> tile) {
    const OmVolSliceKey key(chunkCoord, sliceDepth, viewType);
    cache_->Set(key, tile);
  }
};
