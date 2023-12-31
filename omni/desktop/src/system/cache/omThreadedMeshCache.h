
#pragma once
#include "precomp.h"

#include "mesh/omMesh.h"
#include "mesh/omMeshTypes.h"
#include "system/cache/omCacheBase.h"
#include "system/cache/omCacheManager.h"
#include "cache/lockedObjects.hpp"
#include "utility/lockedObjects.hpp"
#include "utility/omLockedPODs.hpp"
#include "threads/taskManager.hpp"

#include "common/enums.hpp"

/**
 *  Brett Warne - bwarne@mit.edu - 3/12/09
 */

class OmThreadedMeshCache : public OmCacheBase {
 private:
  typedef om::coords::Mesh key_t;
  typedef OmMeshPtr ptr_t;

  om::thread::ThreadPool threadPool_;
  LockedInt64 curSize_;

  om::cache::LockedCacheMap<key_t, ptr_t> cache_;
  om::cache::LockedKeySet<key_t> currentlyFetching_;
  LockedBool killingCache_;

  struct OldCache {
    std::map<key_t, ptr_t> map;
    om::cache::KeyMultiIndex<key_t> list;
  };
  om::utility::LockedList<std::shared_ptr<OldCache> > cachesToClean_;

  int numThreads() { return 2; }

 public:
  OmThreadedMeshCache(const om::common::CacheGroup group,
                      const std::string& name)
      : OmCacheBase(name, group) {
    OmCacheManager::AddCache(group, this);
    threadPool_.start(numThreads());
  }

  virtual ~OmThreadedMeshCache() {
    CloseDownThreads();
    OmCacheManager::RemoveCache(cacheGroup_, this);
  }

  virtual void Get(ptr_t& ptr, const key_t& key,
                   const om::common::Blocking blocking) {
    if (cache_.assignIfHadKey(key, ptr)) {
      return;
    }

    if (om::common::Blocking::BLOCKING == blocking) {
      ptr = loadItem(key);
      return;
    }

    if (zi::system::cpu_count == threadPool_.getTaskCount()) {
      return;  // restrict number of tasks to process
    }

    if (currentlyFetching_.insertSinceDidNotHaveKey(key)) {
      threadPool_.push_back(zi::run_fn(
          zi::bind(&OmThreadedMeshCache::handleCacheMissThread, this, key)));
    }
  }

  virtual ptr_t HandleCacheMiss(const key_t& key) = 0;

  void Remove(const key_t& key) {
    auto ptr = cache_.erase(key);
    if (!ptr || ptr.get() == ptr_t()) {
      return;
    }
    curSize_.sub(ptr.get()->NumBytes());
  }

  void RemoveOldest(const int64_t numBytesToRemove) {
    int64_t numBytesRemoved = 0;

    while (numBytesRemoved < numBytesToRemove) {
      if (cache_.empty()) {
        return;
      }

      auto ptr = cache_.remove_oldest();

      if (!ptr || ptr.get() == ptr_t()) {
        continue;
      }

      const int64_t removedBytes = ptr.get()->NumBytes();
      numBytesRemoved += removedBytes;
      curSize_.sub(removedBytes);
    }
  }

  void Clean() {
    if (cachesToClean_.empty()) {
      return;
    }

    // avoid contention on cacheToClean by swapping in new, empty list
    std::list<std::shared_ptr<OldCache> > oldCaches;
    cachesToClean_.swap(oldCaches);
  }

  void Clear() {
    cache_.clear();
    currentlyFetching_.clear();
    curSize_.set(0);
  }

  void ClearFetchQueue() {
    threadPool_.clear();
    currentlyFetching_.clear();
  }

  void InvalidateCache() {
    ClearFetchQueue();

    // add current cache to list to be cleaned later by OmCacheMan thread
    std::shared_ptr<OldCache> cache(new OldCache());

    cache_.swap(cache->map, cache->list);
    cachesToClean_.push_back(cache);

    curSize_.set(0);
  }

  int64_t GetCacheSize() const { return curSize_.get(); }

  void CloseDownThreads() {
    killingCache_.set(true);
    threadPool_.stop();
    cache_.clear();
    currentlyFetching_.clear();
  }

 private:
  void handleCacheMissThread(const key_t key) {
    if (killingCache_.get()) {
      return;
    }

    loadItem(key);
  }

  ptr_t loadItem(const key_t& key) {
    ptr_t ptr = HandleCacheMiss(key);
    const bool wasInserted = cache_.set(key, ptr);
    if (wasInserted) {
      curSize_.add(ptr->NumBytes());
    }
    return ptr;
  }
};
