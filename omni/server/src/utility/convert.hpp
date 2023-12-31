#pragma once

#include "common/common.h"
#include "common/enums.hpp"
#include "volume/volume.h"
#include "server_types.h"

namespace om {
namespace utility {

inline server::vector3d Convert(coords::Global vec) {
  server::vector3d ret;
  ret.x = vec.x;
  ret.y = vec.y;
  ret.z = vec.z;
  return ret;
}

inline coords::Global Convert(server::vector3d vec) {
  coords::Global ret;
  ret.x = vec.x;
  ret.y = vec.y;
  ret.z = vec.z;
  return ret;
}

inline server::vector3i Convert(Vector3i vec) {
  server::vector3i ret;
  ret.x = vec.x;
  ret.y = vec.y;
  ret.z = vec.z;
  return ret;
}

inline Vector3i Convert(server::vector3i vec) {
  Vector3i ret;
  ret.x = vec.x;
  ret.y = vec.y;
  ret.z = vec.z;
  return ret;
}

inline server::bbox Convert(coords::GlobalBbox bbox) {
  server::bbox ret;
  ret.min = Convert(bbox.getMin());
  ret.max = Convert(bbox.getMax());
  return ret;
}

inline coords::GlobalBbox Convert(server::bbox bbox) {
  coords::GlobalBbox ret;
  ret.set(Convert(bbox.min), Convert(bbox.max));
  return ret;
}

inline server::volType::type Convert(common::ObjectType type) {
  switch (type) {
    case common::ObjectType::CHANNEL:
      return server::volType::CHANNEL;
    case common::ObjectType::SEGMENTATION:
      return server::volType::SEGMENTATION;
    default:
      throw om::NotImplementedException("affinity graph");
  }
  throw ArgException("Bad volume type.");
}

inline common::ObjectType Convert(server::volType::type type) {
  switch (type) {
    case server::volType::CHANNEL:
      return common::ObjectType::CHANNEL;
    case server::volType::SEGMENTATION:
      return common::ObjectType::SEGMENTATION;
  }
  throw ArgException("Bad volume type.");
}

inline server::viewType::type Convert(om::common::ViewType type) {
  switch (type) {
    case common::ViewType::XY_VIEW:
      return server::viewType::XY_VIEW;
    case common::ViewType::XZ_VIEW:
      return server::viewType::XZ_VIEW;
    case common::ViewType::ZY_VIEW:
      return server::viewType::ZY_VIEW;
  }
  throw ArgException("Bad view type.");
}

inline om::common::ViewType Convert(server::viewType::type type) {
  switch (type) {
    case server::viewType::XY_VIEW:
      return common::ViewType::XY_VIEW;
    case server::viewType::XZ_VIEW:
      return common::ViewType::XZ_VIEW;
    case server::viewType::ZY_VIEW:
      return common::ViewType::ZY_VIEW;
  }
  throw ArgException("Bad view type.");
}

inline common::DataType Convert(server::dataType::type type) {
  switch (type) {
    case server::dataType::INT8:
      return common::DataType::INT8;
    case server::dataType::UINT8:
      return common::DataType::UINT8;
    case server::dataType::INT32:
      return common::DataType::INT32;
    case server::dataType::UINT32:
      return common::DataType::UINT32;
    case server::dataType::FLOAT:
      return common::DataType::FLOAT;
  }
  throw ArgException("Bad data type.");
}

inline server::dataType::type Convert(common::DataType type) {
  switch (type.index()) {
    case common::DataType::INT8:
      return server::dataType::INT8;
    case common::DataType::UINT8:
      return server::dataType::UINT8;
    case common::DataType::INT32:
      return server::dataType::INT32;
    case common::DataType::UINT32:
      return server::dataType::UINT32;
    case common::DataType::FLOAT:
      return server::dataType::FLOAT;
  }
  throw ArgException("Bad data type.");
}
}
}  // namespace om::utility::
