#pragma once
#include "precomp.h"

#include "common/common.h"
#include "coordinates/chunk.h"

template <typename VOL, typename T>
class OmChunkItemContainerMatrix {
 private:
  VOL* const vol_;

  const int x_;
  const int y_;
  const int z_;

  typedef boost::multi_array<T*, 3> array_t;
  array_t array_;

 public:
  OmChunkItemContainerMatrix(VOL* vol, const int x, const int y, const int z)
      : vol_(vol),
        x_(x),
        y_(y),
        z_(z),
        array_(array_t(boost::extents[x][y][z])) {}

  ~OmChunkItemContainerMatrix() {
    for (int x = 0; x < x_; ++x) {
      for (int y = 0; y < y_; ++y) {
        for (int z = 0; z < z_; ++z) {
          delete array_[x][y][z];
        }
      }
    }
  }

  T* Get(const om::coords::Chunk& coord) {
    const int x = coord.x;
    const int y = coord.y;
    const int z = coord.z;

    if (x >= x_ || y >= y_ || z >= z_) {
      std::ostringstream stm;
      stm << "invald coordinate: " << coord;
      throw om::ArgException(stm.str());
    }

    if (!array_[x][y][z]) {
      return array_[x][y][z] = new T(*vol_, coord);
    }

    return array_[x][y][z];
  }
};
