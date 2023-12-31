#pragma once
#include "precomp.h"

#include "common/common.h"
#include "project/omProject.h"

class OmProjectSaveActionImpl {
 public:
  OmProjectSaveActionImpl() {}

  void Execute() { OmProject::Save(); }

  void Undo() {}

  std::string Description() const { return "Saved"; }

  QString classNameForLogFile() const { return "OmProjectSaveAction"; }

 private:
  template <typename T>
  friend class OmActionLoggerThread;
};
