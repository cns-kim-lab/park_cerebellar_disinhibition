#include "users/userSettings.h"

#include "datalayer/fs/omFile.hpp"

#include "task/taskManager.h" //jwgim
namespace om {

void userSettings::Load() {
  using namespace YAMLold;

  if (om::file::old::exists(filename_)) {
    Node in;
    om::yaml::util::Read(filename_, in);

    if( !om::task::TaskManager::currentTask() ) { //jwgim 
      om::yaml::util::OptionalRead(in, "threshold", threshold_,
                                  defaultThreshold_);
    }
    om::yaml::util::OptionalRead(in, "sizeThreshold", sizeThreshold_,
                                 defaultSizeThreshold_);
    om::yaml::util::OptionalRead(in, "showAnnotations", showAnnotations_,
                                 defaultShowAnnotations_);
  }
}

void userSettings::Save() {
  using namespace YAMLold;

  Emitter out;

  out << BeginDoc << BeginMap;
  out << Key << "threshold" << Value << threshold_;
  out << Key << "sizeThreshold" << Value << sizeThreshold_;
  out << Key << "showAnnotations" << Value << showAnnotations_;
  out << EndMap << EndDoc;

  om::yaml::util::Write(filename_, out);
}

}  // namespace om
