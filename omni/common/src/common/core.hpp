#pragma once

#include "precomp.h"

namespace om {
namespace common {

typedef uint32_t ID;
typedef uint32_t SegID;

enum ObjectType {
  CHANNEL,
  SEGMENTATION,
  AFFINITY
};
}
}  // namespace om::common::
