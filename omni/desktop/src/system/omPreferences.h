#pragma once
#include "precomp.h"

/*
 * Preferences model adopted from:
 * http://www.misfitcode.com/misfitmodel3d/
 *
 * Brett Warne - bwarne@mit.edu - 4/8/09
 */

#include "common/common.h"
#include "events/events.h"
#include "system/omPreferenceDefinitions.h"
#include "zi/omUtility.h"
#include "datalayer/archive/project.h"

class OmProjectImpl;

namespace om {
namespace prefs {
class View3d;
}
}

class OmPreferences : private om::singletonBase<OmPreferences> {
 public:
  static void Delete() {
    instance().stringPrefs_.clear();
    instance().floatPrefs_.clear();
    instance().intPrefs_.clear();
    instance().boolPrefs_.clear();
    instance().v3fPrefs_.clear();
  }

  static std::string GetString(const om::PrefEnum key) {
    return instance().stringPrefs_.value(key).toStdString();
  }

  static void SetString(const om::PrefEnum key, const std::string& value) {
    instance().stringPrefs_[key] = QString::fromStdString(value);
    postEvent(key);
  }

  static float GetFloat(const om::PrefEnum key) {
    return instance().floatPrefs_.value(key);
  }

  static void SetFloat(const om::PrefEnum key, const float value) {
    instance().floatPrefs_[key] = value;
    postEvent(key);
  }

  static int GetInteger(const om::PrefEnum key) {
    return instance().intPrefs_.value(key);
  }

  static void SetInteger(const om::PrefEnum key, const int value) {
    instance().intPrefs_[key] = value;
    postEvent(key);
  }

  static bool GetBoolean(const om::PrefEnum key) {
    return instance().boolPrefs_.value(key);
  }

  static void SetBoolean(const om::PrefEnum key, const bool value) {
    instance().boolPrefs_[key] = value;
    postEvent(key);
  }

  static Vector3f GetVector3f(const om::PrefEnum key) {
    return instance().v3fPrefs_.value(key);
  }

  static void SetVector3f(const om::PrefEnum key, const Vector3f& value) {
    instance().v3fPrefs_[key] = value;
    postEvent(key);
  }

  static om::prefs::View3d V3dPrefs();

 private:
  OmPreferences() {}
  ~OmPreferences() {}

  QHash<int, QString> stringPrefs_;
  QHash<int, float> floatPrefs_;
  QHash<int, int> intPrefs_;
  QHash<int, bool> boolPrefs_;
  QHash<int, Vector3f> v3fPrefs_;

  static void postEvent(const om::PrefEnum key) {
    om::event::PreferenceChange(key);
  }

  friend class zi::singleton<OmPreferences>;

  friend YAMLold::Emitter& YAMLold::operator<<(YAMLold::Emitter&,
                                               const OmPreferences&);
  friend void YAMLold::operator>>(const YAMLold::Node&, OmPreferences&);
  friend YAMLold::Emitter& YAMLold::operator<<(YAMLold::Emitter&,
                                               const OmProjectImpl&);
  friend void YAMLold::operator>>(const YAMLold::Node&, OmProjectImpl&);
  friend QDataStream& operator<<(QDataStream&, const OmPreferences&);
  friend QDataStream& operator>>(QDataStream&, OmPreferences&);
  friend QDataStream& operator<<(QDataStream&, const OmProjectImpl&);
  friend QDataStream& operator>>(QDataStream&, OmProjectImpl&);
};
