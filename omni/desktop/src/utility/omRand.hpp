#pragma once
#include "precomp.h"

#include "zi/omUtility.h"

class OmRand : private om::singletonBase<OmRand> {
 private:
  boost::mt19937 gen_;

  zi::spinlock lock_;

 public:
  // return rand int in range [min, max]
  static inline int GetRandomInt(const int min, const int max) {
    zi::guard g(instance().lock_);

    boost::uniform_int<> dist(min, max);
    boost::variate_generator<boost::mt19937&, boost::uniform_int<> > rrand(
        instance().gen_, dist);
    return rrand();
  }

 private:
  OmRand() : gen_(boost::mt19937(std::time(0))) {}

  friend class zi::singleton<OmRand>;
};
