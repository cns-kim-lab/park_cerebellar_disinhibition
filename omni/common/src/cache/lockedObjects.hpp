#pragma once

#include "precomp.h"
#include "common/common.h"
#include "zi/utility.h"
#include "cache/objects.hpp"

namespace om {
namespace cache {

template <typename KEY, typename VAL>
class LockedCacheMap {
 public:
  LockedCacheMap() {}

  virtual ~LockedCacheMap() {}

  inline bool assignIfHadKey(const KEY& k, VAL& v) {
    zi::guard g(lock_);
    iterator iter = map_.find(k);
    if (iter == map_.end()) {
      return false;
    }
    v = iter->second;
    return true;
  }

  inline boost::optional<VAL> remove_oldest() {
    zi::guard g(lock_);
    boost::optional<KEY> k = list_.remove_oldest();

    if (!k) {
      return boost::optional<VAL>();
    }

    iterator iter = map_.find(k.get());
    if (iter == map_.end()) {
      return boost::optional<VAL>();
    }
    VAL ret = iter->second;
    map_.erase(iter);
    return ret;
  }

  inline bool set(const KEY& k, const VAL& v) {
    zi::guard g(lock_);

    list_.touch(k);

    iterator iter = map_.lower_bound(k);

    if (iter != map_.end() && !(map_.key_comp()(k, iter->first))) {
      iter->second = v;
      return false;
    }

    map_.insert(iter, std::pair<KEY, VAL>(k, v));

    return true;
  }

  inline bool setPrefetch(const KEY& k, const VAL& v) {
    zi::guard g(lock_);

    list_.touchPrefetch(k);

    iterator iter = map_.lower_bound(k);

    if (iter != map_.end() && !(map_.key_comp()(k, iter->first))) {
      iter->second = v;
      return false;
    }

    map_.insert(iter, std::pair<KEY, VAL>(k, v));

    return true;
  }

  inline boost::optional<VAL> get(const KEY& k) {
    zi::guard g(lock_);
    list_.touch(k);
    iterator iter = map_.find(k);
    if (iter == map_.end()) {
      return boost::optional<VAL>();
    }
    return iter->second;
  }

  inline boost::optional<VAL> erase(const KEY& k) {
    zi::guard g(lock_);

    // list_.erase(k); // TODO: fixme!

    iterator iter = map_.find(k);
    if (iter == map_.end()) {
      return boost::optional<VAL>();
    }
    VAL ret = iter->second;
    map_.erase(iter);
    return ret;
  }

  inline size_t size() const {
    zi::guard g(lock_);
    return map_.size();
  }

  inline bool empty() {
    zi::guard g(lock_);
    return map_.empty();
  }

  inline void clear() {
    zi::guard g(lock_);
    map_.clear();
    list_.clear();
  }

  inline void swap(std::map<KEY, VAL>& newMap, KeyMultiIndex<KEY>& newList) {
    zi::guard g(lock_);
    map_.swap(newMap);
    list_.swap(newList);
  }

  inline bool contains(const KEY& key) {
    zi::guard g(lock_);
    return map_.count(key);
  }

 private:
  std::map<KEY, VAL> map_;
  typedef typename std::map<KEY, VAL>::iterator iterator;

  KeyMultiIndex<KEY> list_;

  zi::spinlock lock_;
};

template <typename KEY>
class LockedKeySet {
 public:
  virtual ~LockedKeySet() {}

  inline bool insertSinceDidNotHaveKey(const KEY k) {
    zi::guard g(lock_);
    std::pair<iterator, bool> p = set_.insert(k);
    return p.second;
  }

  inline void insert(const KEY& k) {
    zi::guard g(lock_);
    set_.insert(k);
  }

  inline void erase(const KEY& k) {
    zi::guard g(lock_);
    set_.erase(k);
  }

  inline void clear() {
    zi::guard g(lock_);
    set_.clear();
  }

 private:
  std::unordered_set<KEY> set_;
  typedef typename std::unordered_set<KEY>::iterator iterator;

  zi::spinlock lock_;
};

/**
 * based on
 *  http://www.boost.org/doc/libs/1_43_0/libs/multi_index/example/serialization.cpp
 *
 * oldest keys at front; newest at back
 *
 * pre-fectched keys will:
 *   --be added to front if key was not present in list_
 *   --not change order if key was present in list_
 **/
template <typename KEY>
class LockedKeyMultiIndex {
 public:
  virtual ~LockedKeyMultiIndex() {}

  inline boost::optional<KEY> remove_oldest() {
    zi::guard g(lock_);
    return list_.remove_oldest();
  }

  inline void touch(const KEY& key) {
    zi::guard g(lock_);
    list_.touch(key);
  }

  inline void touch(const std::list<KEY>& keys) {
    zi::guard g(lock_);
    list_.touch(keys);
  }

  inline void touch(const std::deque<KEY>& keys) {
    zi::guard g(lock_);
    list_.touch(keys);
  }

  inline void touchPrefetch(const KEY& key) {
    zi::guard g(lock_);
    list_.touchPrefetch(key);
  }

  inline bool empty() const {
    zi::guard g(lock_);
    return list_.empty();
  }

  inline void clear() {
    zi::guard g(lock_);
    list_.clear();
  }

 private:
  zi::spinlock lock_;

  KeyMultiIndex<KEY> list_;
};
}
}  // namespace om::cache::
