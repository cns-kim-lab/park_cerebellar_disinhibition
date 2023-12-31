#pragma once
#include "precomp.h"

#include "system/cache/omCacheBase.h"
#include "system/cache/omCacheManager.h"
#include "cache/lockedObjects.hpp"

/**
 * simple locked-protected cache of fixed-sized objects
 *
 * will be memory-limited by OmCacheManager
 *
 * Michael Purcaro 02/2011
 **/

template <typename KEY, typename PTR>
class OmGetSetCache : public OmCacheBase {
 private:
  const om::common::CacheGroup cacheGroup_;
  const int64_t entrySize_;

  zi::spinlock lock_;

  std::map<KEY, PTR> cache_;

  std::deque<KEY> mru_;  // most recent keys at end of list

  om::cache::LockedKeyMultiIndex<KEY> full_mru_;

 public:
  OmGetSetCache(const om::common::CacheGroup cacheGroup,
                const std::string& cacheName, const int64_t entrySize)
      : OmCacheBase(cacheName, cacheGroup),
        cacheGroup_(cacheGroup),
        entrySize_(entrySize) {
    OmCacheManager::AddCache(cacheGroup_, this);
  }

  virtual ~OmGetSetCache() { OmCacheManager::RemoveCache(cacheGroup_, this); }

  void Clear() {
    {
      zi::guard g(lock_);
      cache_.clear();
      mru_.clear();
    }
    full_mru_.clear();
  }

  inline PTR Get(const KEY& key) {
    zi::guard g(lock_);
    mru_.push_back(key);
    return cache_[key];
  }

  inline void Set(const KEY& key, const PTR& ptr) {
    zi::guard g(lock_);
    mru_.push_back(key);
    cache_[key] = ptr;
  }

  void Clean() {
    std::deque<KEY> mru;
    {
      zi::guard g(lock_);
      mru_.swap(mru);
    }

    // merge in keys got/set since last clean
    full_mru_.touch(mru);
  }

  void RemoveOldest(const int64_t numBytesToRemove) {
    if (full_mru_.empty()) {
      return;
    }

    const int numToRemove = numBytesToRemove / entrySize_;

    for (int i = 0; i < numToRemove; ++i) {
      if (full_mru_.empty()) {
        return;
      }
      auto key = full_mru_.remove_oldest();
      if (key) {
        zi::guard g(lock_);
        cache_.erase(key.get());
      }
    }
  }

  // cache of fixed-object sizes, so compute size
  int64_t GetCacheSize() const {
    int64_t numSlices;
    {
      zi::guard g(lock_);
      numSlices = cache_.size();
    }
    return numSlices * entrySize_;
  }

  void CloseDownThreads() { Clear(); }
};
