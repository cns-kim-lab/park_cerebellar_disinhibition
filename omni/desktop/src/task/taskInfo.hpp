#pragma once
#include "precomp.h"

#include "common/common.h"

namespace om {
namespace task {

struct TaskInfo {
  uint64_t id;
  float weight; 
  uint32_t inspected_weight;  
  std::string path;
  uint64_t cell;
  std::string users;
  uint64_t parent;
  std::string notes;
  std::string progress;
  std::string status;
  uint32_t allSize; 
  uint32_t agreedSize; 
  double agreement() const {  
    return allSize ? (double)agreedSize / (double)allSize : 0;
  }
};

}  // namespace om::task::
}  // namespace om::

namespace YAML {

template <>
struct convert<om::task::TaskInfo> {
  static bool decode(const Node& node, om::task::TaskInfo& t) {
    try {
      t.id = node["id"].as<uint64_t>();
      t.weight = node["weightsum"].as<float>();
      t.inspected_weight = node["inspected_weight"].as<uint32_t>();
      t.path = node["segmentation_path"].as<std::string>();
      t.cell = node["cell"].as<uint64_t>();
      t.users = node["users"].as<std::string>("");
      t.parent = node["parent"].as<uint64_t>(0);
      t.notes = node["wiki_notes"].as<std::string>("");
      t.allSize = node["allSize"].as<uint32_t>(0);
      t.agreedSize = node["agreedSize"].as<uint32_t>(0);
    }
    catch (std::exception e) {
      log_debugs << std::string("Error Decoding TaskInfo: ") + e.what();
      return false;
    }
    return true;
  }
};
}