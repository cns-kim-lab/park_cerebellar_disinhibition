#include "gtest/gtest.h"

#include "common/common.h"
#include "coordinates/coordinates.h"

#include <algorithm>

using namespace om::coords;

namespace om {
namespace test {

TEST(Coords_VolumeSystem, UpdateRootLevel) {
  VolumeSystem vs(Vector3i(1024));
  vs.UpdateRootLevel();
  ASSERT_EQ(3, vs.RootMipLevel());

  VolumeSystem vs2(Vector3i(1024), Vector3i::ZERO, Vector3i::ONE, 256);
  vs2.UpdateRootLevel();
  ASSERT_EQ(2, vs2.RootMipLevel());
}

TEST(Coords_VolumeSystem, MipLevelDataDimensions) {
  VolumeSystem vs(Vector3i(1024, 128, 8), Vector3i::ZERO, Vector3i(7, 8, 40), 16);
  ASSERT_EQ(Vector3i(1024, 128, 16), vs.MipLevelDataDimensions(0));
  ASSERT_EQ(Vector3i(512, 64, 8), vs.MipLevelDataDimensions(1));
  ASSERT_EQ(Vector3i(256, 32, 4), vs.MipLevelDataDimensions(2));
  ASSERT_EQ(Vector3i(128, 16, 2), vs.MipLevelDataDimensions(3));
  ASSERT_EQ(Vector3i(64, 8, 1), vs.MipLevelDataDimensions(4));
  ASSERT_EQ(Vector3i(32, 4, 1), vs.MipLevelDataDimensions(5));
  ASSERT_EQ(Vector3i(16, 2, 1), vs.MipLevelDataDimensions(6));
}

TEST(Coords_VolumeSystem, MipLevelDimensionsInMipChunks) {
  VolumeSystem vs(Vector3i(1024));
  ASSERT_EQ(Vector3i(4), vs.MipLevelDimensionsInMipChunks(1));
  ASSERT_EQ(Vector3i(2), vs.MipLevelDimensionsInMipChunks(2));
  ASSERT_EQ(Vector3i(1), vs.MipLevelDimensionsInMipChunks(3));
}

TEST(Coords_VolumeSystem, Extent) {
  VolumeSystem vs(Vector3i(1024));
  ASSERT_EQ(GlobalBbox(Global::ZERO, Global(1023)), vs.Extent());
  VolumeSystem vs2(Vector3i(1024, 512, 256), Vector3i(0, 512, 768),
                   Vector3i(1, 2, 3));
  ASSERT_EQ(GlobalBbox(Global(0, 512, 768), Global(1023, 1534, 1533)),
            vs2.Extent());
}

TEST(Coords_VolumeSystem, DimsRoundedToNearestChunk) {
  VolumeSystem vs(Vector3i(1000));
  ASSERT_EQ(Vector3i(1024), vs.DimsRoundedToNearestChunk(0));
}

TEST(Coords_VolumeSystem, RootMipChunkCoordinate) {
  VolumeSystem vs(Vector3i(1024));
  ASSERT_EQ(Chunk(3, Vector3i::ZERO), vs.RootMipChunkCoordinate());
}

TEST(Coords_VolumeSystem, MipChunkCoords) {
  VolumeSystem vs(Vector3i(256));
  std::shared_ptr<std::vector<Chunk> > chunks = vs.MipChunkCoords();
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(1, 0, 0, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(0, 0, 0, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(0, 0, 0, 1)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(0, 0, 1, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(0, 1, 0, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(0, 0, 1, 1)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(0, 1, 1, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(0, 1, 0, 1)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(0, 1, 1, 1)));
}

TEST(Coords_VolumeSystem, MipChunkCoords_level) {
  VolumeSystem vs(Vector3i(1024));
  std::shared_ptr<std::vector<Chunk> > chunks = vs.MipChunkCoords(2);
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(2, 0, 0, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(2, 0, 0, 1)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(2, 0, 1, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(2, 1, 0, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(2, 0, 1, 1)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(2, 1, 1, 0)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(2, 1, 0, 1)));
  ASSERT_NE(chunks->end(),
            std::find(chunks->begin(), chunks->end(), Chunk(2, 1, 1, 1)));
}

TEST(Coords_VolumeSystem, ContainsMipChunk) {
  VolumeSystem vs(Vector3i(1024));
  ASSERT_TRUE(vs.ContainsMipChunk(Chunk(2, 1, 1, 1)));
  ASSERT_FALSE(vs.ContainsMipChunk(Chunk(3, 1, 1, 1)));
}
}
}  // namespace om::test::
