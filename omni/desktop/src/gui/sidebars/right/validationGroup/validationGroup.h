#pragma once
#include "precomp.h"

#include "gui/widgets/omWidget.hpp"

class SetValid;
class SetNotValid;
class SetUncertain;
class SetNotUncertain;
class ShowValidatedButton;
class SegmentationDataWrapper;
class OmViewGroupState;

namespace om {
namespace sidebars {
class rightImpl;
}
}

class ValidationGroup : public OmWidget {
  Q_OBJECT;

 public:
  ValidationGroup(om::sidebars::rightImpl*, OmViewGroupState& vgs);
  QString getGroupNameFromGUI();
  bool isShowValidChecked();

  QString getName() { return "Validation"; }

  OmViewGroupState& GetViewGroupState() const;

  SegmentationDataWrapper GetSDW() const;

 private
Q_SLOTS:
  void changeMapColors();

 private:
  OmViewGroupState& vgs_;

  QButtonGroup* validGroup;
  QRadioButton* showValid;
  QRadioButton* dontShowValid;
  QLineEdit* mGroupName;

  SetValid* setSelectionValid;
  SetNotValid* setSelectionNotValid;

  SetUncertain* setSelectionUncertain;
  SetNotUncertain* setSelectionNotUncertain;

  ShowValidatedButton* showValidatedButton;

  QWidget* addSelectedSegmentButtons();
};
