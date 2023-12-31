#pragma once
#include "precomp.h"

class TriStripCollector {
 private:
  std::vector<float> data_;
  std::vector<uint32_t> indices_;
  std::vector<uint32_t> strips_;
  std::size_t missing_;
  zi::rwmutex lock_;

  template <typename T>
  friend class OmMeshWriterTaskV2;

 public:
  TriStripCollector() : missing_(0), lock_() {}

  ~TriStripCollector() {}

  bool isComplete() const {
    zi::rwmutex::read_guard g(lock_);
    return missing_ == 0;
  }

  void registerPart() {
    zi::rwmutex::write_guard g(lock_);
    ++missing_;
  }

  // returns the number of missing parts
  std::size_t append(const std::vector<zi::vl::vec3d>& points,
                     const std::vector<zi::vl::vec3d>& normals,
                     const std::vector<uint32_t>& indices,
                     const std::vector<uint32_t>& starts,
                     const std::vector<uint32_t>& lengths, const double scale,
                     const zi::vl::vec3d& trans) {

    zi::rwmutex::write_guard g(lock_);

    ZI_ASSERT(missing_ > 0);

    uint32_t ilen = indices_.size();

    for (auto i = 0; i < starts.size(); ++i) {
      strips_.push_back(starts[i] + ilen);
      strips_.push_back(lengths[i]);
    }

    uint32_t vlen = data_.size() / 6;

    for (auto i = 0; i < indices.size(); ++i) {
      indices_.push_back(indices[i] + vlen);
    }

    for (auto i = 0; i < points.size(); ++i) {
      zi::vl::vec3d p = (points[i] * scale) + trans;
      zi::vl::vec3d n = zi::vl::norm(normals[i]);

      data_.push_back(static_cast<float>(p.at(2)));
      data_.push_back(static_cast<float>(p.at(1)));
      data_.push_back(static_cast<float>(p.at(0)));

      data_.push_back(static_cast<float>(n.at(2)));
      data_.push_back(static_cast<float>(n.at(1)));
      data_.push_back(static_cast<float>(n.at(0)));
    }

    --missing_;

    return missing_;
  }

  void clear() {
    zi::rwmutex::write_guard g(lock_);

    zi::containers::clear(data_);
    zi::containers::clear(indices_);
    zi::containers::clear(strips_);
  }
};
