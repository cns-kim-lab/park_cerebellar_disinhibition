#include "gui/sidebars/right/displayTools/2d/2dpage.hpp"
#include "gui/sidebars/right/displayTools/3d/3dpage.hpp"
#include "gui/sidebars/right/displayTools/location/pageLocation.hpp"
#include "gui/sidebars/right/rightImpl.h"

DisplayTools::DisplayTools(om::sidebars::rightImpl* d, OmViewGroupState& vgs)
    : QWidget(d), vgs_(vgs) {
  QVBoxLayout* box = new QVBoxLayout(this);

  box->addWidget(new om::displayTools::PageLocation(this, GetViewGroupState()));
}

void DisplayTools::updateGui() {
  om::event::Redraw2d();
  om::event::Redraw3d();
}
