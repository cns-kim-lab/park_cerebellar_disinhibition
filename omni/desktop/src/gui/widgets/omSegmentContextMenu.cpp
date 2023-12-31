#include "actions/omActions.h"
#include "common/logging.h"
#include "events/events.h"
#include "gui/inspectors/inspectorProperties.h"
#include "gui/inspectors/segmentInspector.h"
#include "gui/widgets/omAskYesNoQuestion.hpp"
#include "gui/widgets/omSegmentContextMenu.h"
#include "gui/widgets/omTellInfo.hpp"
#include "gui/widgets/progress.hpp"
#include "gui/widgets/progressBarDialog.hpp"
#include "project/omProject.h"
#include "segment/omSegmentIterator.h"
#include "segment/omSegmentSelector.h"
#include "segment/omSegmentUtils.hpp"
#include "system/cache/omCacheManager.h"
#include "system/omStateManager.h"
#include "utility/dataWrappers.h"
#include "view3d.old/omSegmentPickPoint.h"
#include "viewGroup/omSplitting.hpp"
#include "viewGroup/omViewGroupState.h"

/////////////////////////////////
///////          Context Menu Methods

void OmSegmentContextMenu::Refresh(const SegmentDataWrapper& sdw,
                                   OmViewGroupState& vgs) {
  sdw_ = sdw;
  vgs_ = &vgs;

  doRefresh();
}

void OmSegmentContextMenu::Refresh(const SegmentDataWrapper& sdw,
                                   OmViewGroupState& vgs,
                                   const om::coords::Global coord) {
  sdw_ = sdw;
  vgs_ = &vgs;
  coord_ = coord;

  doRefresh();
}

void OmSegmentContextMenu::Refresh(const OmSegmentPickPoint& pickPoint,
                                   OmViewGroupState& vgs) {
  sdw_ = pickPoint.sdw;
  coord_ = pickPoint.coord;
  vgs_ = &vgs;

  doRefresh();
}

void OmSegmentContextMenu::doRefresh() {
  // clear old menu actions
  clear();

  addSelectionNames();
  addSeparator();

  addSelectionAction();
  addSeparator();

  addColorActions();
  addSeparator();

  if (!isValid()) {
    addDendActions();
    addSeparator();
  }

  addGroupActions();
  addSeparator();

  addDisableAction();
  addPropertiesActions();

  addSeparator();
}

bool OmSegmentContextMenu::isValid() const {
  return sdw_.FindRoot()->IsValidListType();
}

bool OmSegmentContextMenu::isUncertain() const {
  return om::common::SegListType::UNCERTAIN == sdw_.FindRoot()->GetListType();
}

void OmSegmentContextMenu::addSelectionNames() {
  const QString segStr =
      QString("Segment %1 (Root %2)").arg(sdw_.GetID()).arg(sdw_.FindRootID());
  addAction(segStr);

  QString validStr;
  if (isValid()) {
    validStr = "Valid in " + sdw_.GetSegmentationName();
  } else {
    validStr = "Not valid in " + sdw_.GetSegmentationName();
  }
  addAction(validStr);
}

/*
 *  adds Un/Select Segment Action
 */
void OmSegmentContextMenu::addSelectionAction() {
  if (sdw_.isSelected()) {
    addAction("Select Only This Segment", this, SLOT(unselectOthers()));
    addAction("Deselect Only This Segment", this, SLOT(unselect()));
  } else {
    addAction("Select Only This Segment", this, SLOT(unselectOthers()));
    addAction("Select Segment", this, SLOT(select()));
  }
}

/*
 *  Merge Segments
 */
void OmSegmentContextMenu::addDendActions() {
  addAction("Merge Selected Segments", this, SLOT(mergeSegments()));
  addAction("Split Segments", this, SLOT(splitSegments()));
  addAction("Cut Segment(s)", this, SLOT(cutSegments()));
}

/////////////////////////////////
///////          Context Menu Slots Methods

void OmSegmentContextMenu::select() {
  OmSegmentSelected::AugmentSelection(sdw_);
}

void OmSegmentContextMenu::unselect() {
  OmSegmentSelector sel(sdw_.MakeSegmentationDataWrapper(), this, "view3d");
  sel.augmentSelectedSet(sdw_.GetID(), false);
  sel.sendEvent();
}

void OmSegmentContextMenu::unselectOthers() {
  OmSegmentSelector sel(sdw_.MakeSegmentationDataWrapper(), this, "view3d");
  sel.selectNoSegments();
  sel.selectJustThisSegment(sdw_.GetID(), true);
  sel.sendEvent();
}

void OmSegmentContextMenu::mergeSegments() {
  OmActions::JoinSegments(sdw_.MakeSegmentationDataWrapper());
}

void OmSegmentContextMenu::splitSegments() {

  vgs_->Splitting().EnterSplitMode();

  vgs_->Splitting().SetFirstSplitPoint(sdw_, coord_);
}

void OmSegmentContextMenu::cutSegments() { OmActions::CutSegment(sdw_); }

void OmSegmentContextMenu::addColorActions() {
  addAction("Randomize Root Segment Color", this, SLOT(randomizeColor()));
  addAction("Randomize Segment Color", this, SLOT(randomizeSegmentColor()));
  addAction("Set As Segment Palette Color", this, SLOT(setSelectedColor()));
}

void OmSegmentContextMenu::addGroupActions() {
  addAction("Set Segment Valid", this, SLOT(setValid()));
  addAction("Set Segment Not Valid", this, SLOT(setNotValid()));
}

void OmSegmentContextMenu::setSelectedColor() {
  OmSegmentSelected::SetSegmentForPainting(sdw_);
}

void OmSegmentContextMenu::randomizeColor() {
  OmSegment* segment = sdw_.FindRoot();
  segment->reRandomizeColor();

  OmCacheManager::TouchFreshness();
  om::event::Redraw2d();
}

void OmSegmentContextMenu::randomizeSegmentColor() {
  OmSegment* segment = sdw_.GetSegment();
  segment->reRandomizeColor();

  OmCacheManager::TouchFreshness();
  om::event::Redraw2d();
}

void OmSegmentContextMenu::setValid() {
  if (sdw_.IsSegmentValid()) {
    OmActions::ValidateSegment(sdw_, om::common::SetValid::SET_VALID);
    om::event::SegmentModified();
  }
}

void OmSegmentContextMenu::setNotValid() {
  if (sdw_.IsSegmentValid()) {
    OmActions::ValidateSegment(sdw_, om::common::SetValid::SET_NOT_VALID);
    om::event::SegmentModified();
  }
}

void OmSegmentContextMenu::showProperties() {
  const om::common::SegID rootSegID = sdw_.FindRootID();
  SegmentDataWrapper sdw(sdw_.GetSegmentationID(), rootSegID);

  const QString title = QString("Segmentation %1: Segment %2")
                            .arg(sdw.GetSegmentationID())
                            .arg(rootSegID);

  om::event::UpdateSegmentPropBox(new SegmentInspector(sdw, this), title);
}

void OmSegmentContextMenu::addPropertiesActions() {
  addAction("Properties", this, SLOT(showProperties()));
  addAction("List Children", this, SLOT(printChildren()));
}

void OmSegmentContextMenu::printChildren() {
  std::shared_ptr<std::deque<std::string> > children =
      OmSegmentUtils::GetChildrenInfo(sdw_);

  OmAskYesNoQuestion fileExport("Export children list to file?");

  if (fileExport.Ask()) {
    const QString fnp =
        QFileDialog::getSaveFileName(this, "Children list file name");

    if (nullptr == fnp) {
      return;
    }

    om::gui::progressBarDialog* dialog =
        new om::gui::progressBarDialog(nullptr);
    dialog->push_back(zi::run_fn(zi::bind(
        OmSegmentContextMenu::writeChildrenFile, fnp, dialog, children)));

  } else {
    FOR_EACH(iter, *children) { log_infos << iter->c_str(); }
  }
}

void OmSegmentContextMenu::writeChildrenFile(
    const QString fnp, om::gui::progressBarDialog* dialog,
    std::shared_ptr<std::deque<std::string> > children) {
  try {
    QFile file(fnp);
    om::file::old::openFileWO(file);
    om::file::old::writeStrings(file, *children, dialog);

    dialog->TellDone("wrote file " + fnp);
  }
  catch (...) {
    dialog->TellDone("failed writing file " + fnp);
  }
}

void OmSegmentContextMenu::addDisableAction() {}

void OmSegmentContextMenu::disableSegment() {}
