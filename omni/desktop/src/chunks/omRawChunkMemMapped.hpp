#pragma once
#include "precomp.h"

#include "common/common.h"

#include "volume/io/omVolumeData.h"
#include "volume/omMipVolume.h"

template <typename T>
class OmRawChunkMemMapped {
 private:
  OmMipVolume* const vol_;
  const om::coords::Chunk coord_;
  const uint64_t chunkOffset_;
  const QString fnp_;
  const uint64_t numBytes_;

  std::unique_ptr<QFile> file_;
  T* dataRaw_;

 public:
  OmRawChunkMemMapped(OmMipVolume* vol, const om::coords::Chunk& coord)
      : vol_(vol),
        coord_(coord),
        chunkOffset_(OmChunkOffset::ComputeChunkPtrOffsetBytes(vol, coord)),
        fnp_(OmFileNames::GetMemMapFileNameQT(vol, coord.mipLevel())),
        numBytes_(128 * 128 * 128 * vol_->GetBytesPerVoxel()),
        dataRaw_(nullptr) {
    mapData();
  }

  ~OmRawChunkMemMapped() {}

  inline T Get(const uint64_t index) const { return dataRaw_[index]; }

  uint64_t NumBytes() const { return numBytes_; }

  T* Data() const { return dataRaw_; }

 private:
  void mapData() {
    file_.reset(new QFile(fnp_));

    if (!file_->open(QIODevice::ReadOnly)) {
      throw om::IoException("could not open", fnp_);
    }

    uchar* map = file_->map(chunkOffset_, numBytes_);
    if (!map) {
      throw om::IoException("could not map", fnp_);
    }

    dataRaw_ = reinterpret_cast<T*>(map);

    file_->close();
  }
};
