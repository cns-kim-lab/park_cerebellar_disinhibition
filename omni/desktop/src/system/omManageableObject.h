#pragma once
#include "precomp.h"

/*
 *
 * Brett Warne - bwarne@mit.edu - 3/3/09
 */

#include "common/common.h"
#include "datalayer/archive/segmentation.h"
#include "datalayer/archive/filter.h"

namespace YAMLold {
template <class T>
class mipVolume;
}

class OmManageableObject {
 public:
  OmManageableObject() : id_(1) {}

  explicit OmManageableObject(const om::common::ID id) : id_(id) {}

  inline om::common::ID GetID() const { return id_; }

  inline const QString& GetCustomName() const { return customName_; }

  inline void SetCustomName(const QString& name) { customName_ = name; }

  inline const QString& GetNote() const { return note_; }

  inline void SetNote(const QString& note) { note_ = note; }

 protected:
  om::common::ID id_;
  QString note_;
  QString customName_;

  template <class T>
  friend class OmMipVolumeArchive;
  friend class OmMipVolumeArchiveOld;
  template <class T>
  friend class YAMLold::mipVolume;
  friend void YAMLold::operator>>(const YAMLold::Node& in, OmFilter2d& f);
};
