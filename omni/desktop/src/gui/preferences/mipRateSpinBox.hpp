#pragma once
#include "precomp.h"

#include "view2d/om2dPreferences.hpp"
#include "gui/widgets/omDoubleSpinBox.hpp"
#include "events/events.h"

class MipRateSpinBox : public OmDoubleSpinBox {
 public:
  MipRateSpinBox(QWidget* p) : OmDoubleSpinBox(p, true) {
    setSingleStep(0.1);
    setMinimum(0);
    setMaximum(10);
    setValue(Om2dPreferences::MipRate());
  }

 private:
  void actUponValueChange(const double val) {
    Om2dPreferences::MipRate(val);
    om::event::Redraw2d();
  }
};
