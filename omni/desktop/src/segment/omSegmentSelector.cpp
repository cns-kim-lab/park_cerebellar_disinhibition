#include "actions/omActions.h"
#include "actions/omSelectSegmentParams.hpp"
#include "utility/set.hpp"
#include "project/omProject.h"
#include "segment/omSegments.h"
#include "segment/omSegmentSelected.hpp"
#include "segment/omSegmentSelector.h"
#include "segment/selection.hpp"
#include "volume/omSegmentation.h"
#include "utility/segmentationDataWrapper.hpp"

OmSegmentSelector::OmSegmentSelector(const SegmentationDataWrapper& sdw,
                                     void* sender, const std::string& cmt)
    : params_(std::make_shared<OmSelectSegmentsParams>()) {
  if (!sdw.IsSegmentationValid()) {
    throw om::ArgException(
        "Invalid SegmentationDataWrapper "
        "(OmSegmentSelector::OmSegmentSelector)");
  }

  segments_ = sdw.Segments();
  selection_ = &sdw.Segments()->Selection();

  params_->sdw = SegmentDataWrapper(sdw, 0);
  params_->sender = sender;
  params_->comment = cmt;
  params_->oldSelectedIDs = selection_->GetSelectedSegmentIDs();
  params_->newSelectedIDs = params_->oldSelectedIDs;
  params_->autoCenter = false;
  params_->shouldScroll = true;
  params_->addToRecentList = true;

  params_->augmentListOnly = false;
  params_->addOrSubtract = om::common::AddOrSubtract::ADD;
}

void OmSegmentSelector::selectNoSegments() { params_->newSelectedIDs.clear(); }

void OmSegmentSelector::selectJustThisSegment(
    const om::common::SegID segIDunknownLevel, const bool isSelected) {
  selectNoSegments();

  auto segID = segments_->FindRootID(segIDunknownLevel);
  if (!segID) {
    return;
  }

  if (params_->oldSelectedIDs.size() > 1) {
    params_->newSelectedIDs.insert(segID);
  } else {
    if (isSelected) {
      params_->newSelectedIDs.insert(segID);
    }
  }

  setSelectedSegment(segID);
}

void OmSegmentSelector::setSelectedSegment(const om::common::SegID segID) {
  params_->sdw.SetSegmentID(segID);
  OmSegmentSelected::Set(params_->sdw);
}

void OmSegmentSelector::InsertSegments(const om::common::SegIDSet& segIDs) {
  for (auto id : segIDs) {
    params_->newSelectedIDs.insert(segments_->FindRootID(id));
  }
}

void OmSegmentSelector::RemoveSegments(const om::common::SegIDSet& segIDs) {
  params_->newSelectedIDs.clear();

  for (auto id : segIDs) {
    params_->newSelectedIDs.insert(segments_->FindRootID(id));
  }
}

void OmSegmentSelector::augmentSelectedSet(
    const om::common::SegID segIDunknownLevel, const bool isSelected) {
  const om::common::SegID segID = segments_->FindRootID(segIDunknownLevel);

  if (!segID) {
    return;
  }

  if (isSelected) {
    params_->newSelectedIDs.insert(segID);
  } else {
    params_->newSelectedIDs.erase(segID);
  }

  setSelectedSegment(segID);
}

void OmSegmentSelector::selectJustThisSegment_toggle(
    const om::common::SegID segIDunknownLevel) {
  const om::common::SegID segID = segments_->FindRootID(segIDunknownLevel);
  if (!segID) {
    return;
  }

  const bool isSelected = selection_->IsSegmentSelected(segID);
  selectJustThisSegment(segID, !isSelected);
}

void OmSegmentSelector::augmentSelectedSet_toggle(
    const om::common::SegID segIDunknownLevel) {
  const om::common::SegID segID = segments_->FindRootID(segIDunknownLevel);
  if (!segID) {
    return;
  }

  const bool isSelected = selection_->IsSegmentSelected(segID);
  augmentSelectedSet(segID, !isSelected);
}

bool OmSegmentSelector::sendEvent() {
  if (params_->augmentListOnly) {
    if (om::common::AddOrSubtract::ADD == params_->addOrSubtract) {
      if (om::set::SetAContainsB(params_->oldSelectedIDs,
                                 params_->newSelectedIDs)) {
        // already added
        return false;
      }
    } else {
      if (om::set::SetsAreDisjoint(params_->oldSelectedIDs,
                                   params_->newSelectedIDs)) {
        // no segments to be removed are selected
        return false;
      }
    }

  } else {
    if (params_->oldSelectedIDs == params_->newSelectedIDs) {
      // no change in selected set
      return false;
    }
  }

  // log_debugs(segmentSelector) << params_->oldSelectedIDs << "\n";

  if (params_->augmentListOnly) {
    // disable undo option for now
    om::segment::Selection* selection = params_->sdw.Selection();

    if (om::common::AddOrSubtract::ADD == params_->addOrSubtract) {
      selection->AddToSegmentSelection(params_->newSelectedIDs);
    } else {
      selection->RemoveFromSegmentSelection(params_->newSelectedIDs);
    }
  } else {
    OmActions::SelectSegments(params_);
  }

  return true;
}

void OmSegmentSelector::ShouldScroll(const bool shouldScroll) {
  params_->shouldScroll = shouldScroll;
}

void OmSegmentSelector::AddToRecentList(const bool addToRecentList) {
  params_->addToRecentList = addToRecentList;
}

void OmSegmentSelector::AutoCenter(const bool autoCenter) {
  params_->autoCenter = autoCenter;
}

void OmSegmentSelector::AugmentListOnly(const bool augmentListOnly) {
  params_->augmentListOnly = augmentListOnly;
}

void OmSegmentSelector::AddOrSubtract(
    const om::common::AddOrSubtract addOrSubtract) {
  params_->addOrSubtract = addOrSubtract;
}
