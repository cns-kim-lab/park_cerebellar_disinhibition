#pragma once

#include "precomp.h"
#include "zi/utility.h"

namespace om {
namespace utility {

class rand : private om::SingletonBase<rand> {
 private:
  boost::mt19937 gen_;

  zi::spinlock lock_;

 public:
  // return rand int in range [min, max]
  static inline int GetRandomInt(const int min, const int max) {
    zi::guard g(instance().lock_);

    boost::uniform_int<> dist(min, max);
    boost::variate_generator<boost::mt19937&, boost::uniform_int<>> rrand(
        instance().gen_, dist);
    return rrand();
  }

 private:
  rand() : gen_(boost::mt19937(std::time(0))) {}

  friend class zi::singleton<rand>;
};

}  // namespace utility
}  // namespace om