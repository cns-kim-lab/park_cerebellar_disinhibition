#pragma once
#include "precomp.h"

#include "datalayer/fs/omFile.hpp"

#include "utility/omUUID.hpp"

/**
 * Auto-open a temporary, mem-mappable file;
 *   filename includes 16-character UUID
 *
 * Michael Purcaro (Feb 2011)
 */

template <class T>
class OmTempFile {
 private:
  const OmUUID uuid_;
  const std::string fnp_;

  std::unique_ptr<QFile> file_;
  T* data_;

 public:
  OmTempFile() : uuid_(OmUUID()), fnp_(makeFileName()), data_(nullptr) {
    if (om::file::old::exists(fnp_)) {  // should be VERY unlikely
      throw om::IoException("unique file already found");
    }

    // race here is possible, if VERY, VERY unlikely...

    om::file::old::openFileRW(file_, fnp_);
  }

  virtual ~OmTempFile() {
    file_.reset();
    om::file::old::rmFile(fnp_);
  }

  const std::string& FileName() const { return fnp_; }

  void ResizeNumBytes(const int64_t numBytes) {
    om::file::old::resizeFileNumBytes(file_.get(), numBytes);
  }

  void ResizeNumElements(const int64_t numElements) {
    ResizeNumBytes(numElements * sizeof(T));
  }

  T* Map() { return data_ = om::file::old::mapFile<T>(file_.get()); }

  int64_t NumBytes() const { return file_->size(); }

 private:
  std::string makeFileName() const { return OmFileNames::TempFileName(uuid_); }
};
