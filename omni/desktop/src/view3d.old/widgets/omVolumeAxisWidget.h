#pragma once
#include "precomp.h"

/*
 *
 *
 */

#include "omView3dWidget.h"

class OmSelectionWidget : public OmView3dWidget {

 public:
  OmSelectionWidget(OmView3d *view3d);
  virtual void Draw();

 private:
};
