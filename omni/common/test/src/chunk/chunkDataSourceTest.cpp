#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include "chunk/cachedDataSource.hpp"
#include "utility/UUID.hpp"
#include "volume/volume.h"

using namespace om::chunk;

namespace om {
namespace test {

#define URI \
  "/omniweb_data/x06/y59/x06y59z28_s1587_13491_6483_e1842_13746_6738.omni"

TEST(Chunk_FileDataSource, GetChunk) {
  file::Paths p(URI);
  volume::Volume channel(p.Channel(1));
  volume::Volume segmentation(p.Segmentation(1));
  auto& chanSource = channel.ChunkDS();
  auto& segSource = segmentation.ChunkDS();

  chanSource.Get(coords::Chunk(0, Vector3i(1)));
  chanSource.Get(coords::Chunk(1, Vector3i(0)));

  segSource.Get(coords::Chunk(0, Vector3i(1)));
  segSource.Get(coords::Chunk(1, Vector3i(0)));
}

TEST(Chunk_FileDataSource, PutChunk) {
  // volume::Volume segmentation(std::string(URI) +
  // "segmentations/segmentation1");
  // auto segSource = segmentation.ChunkDS();

  // coords::Chunk coord(0, Vector3i(1));

  // chunk::ChunkVar chunk =
  //     chunk::Chunk<uint32_t>(coord, segmentation.coordSystem());

  // TODO: Set data

  // Not yet implemented
  // segSource->Put(coord, chunk);

  // chunk::ChunkVar gotten = segSource->Get(coord);

  // TODO: Compare results
}

#undef URI
}
}  // namespace om::test::
