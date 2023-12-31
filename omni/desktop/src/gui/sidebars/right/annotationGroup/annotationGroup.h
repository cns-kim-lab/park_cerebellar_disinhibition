#pragma once
#include "precomp.h"

#include "common/common.h"
#include "gui/widgets/omWidget.hpp"

class OmViewGroupState;

namespace om {
namespace sidebars {

class rightImpl;

class AnnotationGroup : public OmWidget {
  Q_OBJECT;

 public:
  AnnotationGroup(rightImpl *, OmViewGroupState &);

  QString getName() { return "Annotations"; }

 private:
  OmViewGroupState &vgs_;
};

}  // namespace sidebars
}  // namespace om