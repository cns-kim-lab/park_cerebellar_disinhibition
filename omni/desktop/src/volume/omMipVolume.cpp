#include "volume/omMipVolume.h"
#include "volume/io/omVolumeData.h"

OmMipVolume::OmMipVolume()
    : mVolDataType(om::common::DataType::UNKNOWN),
      mBuildState(MIPVOL_UNBUILT) {}

bool OmMipVolume::ContainsVoxel(const om::coords::Global& vox) {
  return coords_.Extent().contains(vox);
}

void OmMipVolume::addChunkCoordsForLevel(
    const int mipLevel, std::deque<om::coords::Chunk>* coords) const {
  const Vector3i dims = coords_.MipLevelDimensionsInMipChunks(mipLevel);

  for (int z = 0; z < dims.z; ++z) {
    for (int y = 0; y < dims.y; ++y) {
      for (int x = 0; x < dims.x; ++x) {
        coords->push_back(om::coords::Chunk(mipLevel, Vector3i(x, y, z)));
      }
    }
  }
}

std::shared_ptr<std::deque<om::coords::Chunk> > OmMipVolume::GetMipChunkCoords()
    const {
  std::deque<om::coords::Chunk>* coords = new std::deque<om::coords::Chunk>();

  for (int level = 0; level <= coords_.RootMipLevel(); ++level) {
    addChunkCoordsForLevel(level, coords);
  }

  return std::shared_ptr<std::deque<om::coords::Chunk> >(coords);
}

std::shared_ptr<std::deque<om::coords::Chunk> > OmMipVolume::GetMipChunkCoords(
    const int mipLevel) const {
  std::deque<om::coords::Chunk>* coords = new std::deque<om::coords::Chunk>();

  addChunkCoordsForLevel(mipLevel, coords);

  return std::shared_ptr<std::deque<om::coords::Chunk> >(coords);
}
