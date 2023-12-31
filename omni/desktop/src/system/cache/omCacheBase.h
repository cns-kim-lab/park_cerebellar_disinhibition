#pragma once
#include "precomp.h"

/**
 * Base class of all caches.
 * Brett Warne - bwarne@mit.edu - 7/15/09
 */

#include "common/common.h"
#include "common/enums.hpp"

class OmCacheBase {
 protected:
  const std::string cacheName_;
  const om::common::CacheGroup cacheGroup_;

 public:
  OmCacheBase(const std::string& cacheName, const om::common::CacheGroup group)
      : cacheName_(cacheName), cacheGroup_(group) {}

  virtual ~OmCacheBase() {}

  om::common::CacheGroup Group() const { return cacheGroup_; }

  virtual void Clean() = 0;
  virtual void RemoveOldest(const int64_t numBytes) = 0;
  virtual void Clear() = 0;

  virtual int64_t GetCacheSize() const = 0;

  virtual void CloseDownThreads() = 0;

  virtual const std::string& GetName() const { return cacheName_; }

  friend std::ostream& operator<<(std::ostream& out, const OmCacheBase& in) {
    out << in.GetName() << " (" << in.Group() << ")";
    return out;
  }
};
