#pragma once
#include "precomp.h"

#include "task/task.h"
#include "common/common.h"
#include "yaml-cpp/yaml.h"

#include "network/sqlQuery.h" //jwgim
#include "utility/omTimer.hpp"

namespace YAML {
template <typename>
class convert;
}

namespace om {
namespace task {

class TracingTask : virtual public Task {
 public:
  TracingTask();
  TracingTask(uint32_t id, uint32_t cellId, const std::string& path,
              common::SegIDSet&& seed);
  TracingTask(om::network::SqlQuery::SqlResultset queryRsl);  //jwgim
  virtual ~TracingTask();

  virtual uint64_t Id() const override { return id_; }
  virtual uint64_t CellId() const override { return cellId_; }
  virtual std::string Notes() const override { return notes_; }
  virtual bool Reaping() const override { return false; }
  virtual bool Start() override;
  virtual bool Submit() override;
  virtual const std::vector<SegGroup>& SegGroups() const { return groups_; }
  virtual uint64_t ParentID() const { return parentID_; }
  virtual float Weight() const { return weight_; }
  virtual uint32_t WeightSum() const { return weightSum_; }
  virtual std::string Users() const { return users_; }
  virtual std::string Path() const { return path_; }
  virtual std::string Segments(SegGroup::GroupType gtype);
  virtual bool Save() override; 
  virtual bool Skip() override;
  virtual std::string Taskfrom() const override { return taskfrom_; }

 private:
  uint64_t id_;
  uint64_t parentID_;
  float weight_;
  uint32_t weightSum_;
  uint64_t cellId_;
  std::string path_;
  std::string users_;
  std::string notes_;
  common::SegIDSet seed_;
  std::vector<SegGroup> groups_;
  OmTimer timer;
  std::string taskfrom_;
  friend class YAML::convert<TracingTask>;
};

}  // namespace om::task::
}  // namespace om::

namespace YAML {;

template <>
struct convert<om::task::TracingTask> {
  static bool decode(const Node& node, om::task::TracingTask& t) {
    try {
      t.id_ = node["id"].as<uint64_t>();
      t.parentID_ = node["parent"].as<uint64_t>(0);
      t.weight_ = node["prior"]["weight"].as<float>(0);
      t.weightSum_ = node["weightsum"].as<uint32_t>(0);
      t.cellId_ = node["cell"].as<uint64_t>();
      t.path_ = node["data"]["channel"]["metadata"]["uri"].as<std::string>();
      if (t.path_.compare(t.path_.size() - 7 - 1, std::string::npos,
                          ".files/")) {
        t.path_ = t.path_.substr(0, t.path_.size() - 7);
      }
      t.users_ = node["users"].as<std::string>("");
      t.notes_ = node["wiki_notes"].as<std::string>("");
      
      auto seedYaml = node["prior"]["segments"];
      t.seed_.clear();
      for (const auto& s : seedYaml) {
        t.seed_.insert(s.first.as<uint32_t>());
      }
      om::task::SegGroup seed;
      seed.name = "seed";
      seed.type = om::task::SegGroup::GroupType::SEED;
      seed.segments = t.seed_;
      t.groups_.push_back(seed);
      return true;
    }
    catch (std::exception e) {
      log_debugs << std::string("Error Decoding TracingTask: ") + e.what();
      return false;
    }
  }
};
}