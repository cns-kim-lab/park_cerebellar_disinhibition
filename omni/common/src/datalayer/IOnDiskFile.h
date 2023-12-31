#pragma once

#include "datalayer/file.h"

namespace om {
namespace datalayer {

template <typename T> class IOnDiskFile {
 public:
  virtual ~IOnDiskFile() {}

  virtual uint64_t Size() const = 0;
  virtual void Flush() {}
  virtual T* GetPtr() const = 0;
  virtual T* GetPtrWithOffset(const int64_t offset) const = 0;
  virtual file::path GetBaseFileName() const = 0;
};
}
}
