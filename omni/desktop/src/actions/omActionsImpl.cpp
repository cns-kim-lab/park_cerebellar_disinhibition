#include "actions/details/omActionImpls.hpp"
#include "actions/details/omSegmentSplitAction.h"
#include "actions/details/omSegmentShatterAction.h"
#include "actions/details/omSegmentUncertainAction.h"
#include "actions/details/omSegmentValidateAction.h"
#include "actions/details/omVoxelSetValueAction.h"
#include "actions/omActionsImpl.h"
#include "actions/omSelectSegmentParams.hpp"
#include "segment/actions/omCutSegmentRunner.hpp"
#include "segment/actions/omJoinSegmentsRunner.hpp"
#include "segment/actions/omSetSegmentValidRunner.hpp"
#include "segment/omFindCommonEdge.hpp"
#include "segment/omSegmentSelector.h"
#include "system/omLocalPreferences.hpp"
#include "threads/taskManager.hpp"
#include "utility/dataWrappers.h"
#include "viewGroup/omSplitting.hpp"
#include "viewGroup/omViewGroupState.h"

OmActionsImpl::OmActionsImpl() : threadPool_(new om::thread::ThreadPool()) {
  threadPool_->start(1);
}

OmActionsImpl::~OmActionsImpl() { threadPool_->join(); }

// project-related
void OmActionsImpl::Save() { (new OmProjectSaveAction())->RunNow(); }

void OmActionsImpl::Close() { (new OmProjectCloseAction())->RunNow(); }

// MST-related
void OmActionsImpl::ChangeMSTthreshold(const SegmentationDataWrapper sdw,
                                       const double threshold) {
  (new OmSegmentationThresholdChangeAction(sdw, threshold))->Run();
}

void OmActionsImpl::ChangeSizethreshold(const SegmentationDataWrapper sdw,
                                        const double threshold) {
  (new OmSegmentationSizeThresholdChangeAction(sdw, threshold))->Run();
}

// painting-related
void OmActionsImpl::SetVoxel(const om::common::ID segmentationID,
                             const om::coords::Global voxel,
                             const om::common::SegID segmentID) {
  (new OmVoxelSetValueAction(segmentationID, voxel, segmentID))->Run();
}

void OmActionsImpl::SetVoxels(const om::common::ID segmentationID,
                              const std::set<om::coords::Global> voxels,
                              const om::common::SegID segmentID) {
  (new OmVoxelSetValueAction(segmentationID, voxels, segmentID))->Run();
}

// segment-related
void OmActionsImpl::ValidateSegment(const SegmentDataWrapper sdw,
                                    const om::common::SetValid valid,
                                    const bool dontCenter) {
  OmSetSegmentValidRunner validator(sdw, valid);
  validator.Validate();
  validator.JumpToNextSegment(dontCenter);
}

void OmActionsImpl::ValidateSelectedSegments(const SegmentationDataWrapper sdw,
                                             const om::common::SetValid valid) {
  OmSetSegmentsValidRunner validator(sdw, valid);
  validator.Validate();
  validator.JumpToNextSegment();
}

void OmActionsImpl::UncertainSegment(const SegmentDataWrapper sdw,
                                     const bool uncertain) {
  if (!sdw.IsValidWrapper()) {
    return;
  }

  bool shouldJump =
      OmLocalPreferences::GetShouldJumpToNextSegmentAfterValidate();
  const om::common::SegID nextSegmentIDtoJumpTo =
      OmSegmentUtils::GetNextSegIDinWorkingList(sdw);

  setUncertain(sdw, uncertain);

  if (shouldJump && uncertain && nextSegmentIDtoJumpTo) {
    OmSegmentSelector sel(sdw.MakeSegmentationDataWrapper(), nullptr,
                          "jump after validate");
    sel.selectJustThisSegment(nextSegmentIDtoJumpTo, true);
    sel.AutoCenter(true);
    sel.sendEvent();
  }
}

void OmActionsImpl::UncertainSegmentation(const SegmentationDataWrapper sdw,
                                          const bool uncertain) {
  bool shouldJump =
      OmLocalPreferences::GetShouldJumpToNextSegmentAfterValidate();
  const om::common::SegID nextSegmentIDtoJumpTo =
      OmSegmentUtils::GetNextSegIDinWorkingList(sdw);

  setUncertain(sdw, uncertain);

  if (shouldJump && uncertain && nextSegmentIDtoJumpTo) {
    OmSegmentSelector sel(sdw, nullptr, "jump after validate");
    sel.selectJustThisSegment(nextSegmentIDtoJumpTo, true);
    sel.AutoCenter(true);
    sel.sendEvent();
  }
}

void OmActionsImpl::setUncertain(const SegmentDataWrapper& sdw,
                                 const bool uncertain) {
  om::common::SegIDSet set;
  set.insert(sdw.FindRootID());

  std::shared_ptr<std::set<OmSegment*> > children =
      OmSegmentUtils::GetAllChildrenSegments(*sdw.Segments(), set);

  (new OmSegmentUncertainAction(sdw.MakeSegmentationDataWrapper(), children,
                                uncertain))->Run();
}

void OmActionsImpl::setUncertain(const SegmentationDataWrapper& sdw,
                                 const bool uncertain) {
  if (!sdw.IsValidWrapper()) {
    log_errors << "Unable to setUncertain.  Invalid SegmentationDataWrapper";
    return;
  }
  OmSegments* segments = sdw.Segments();

  std::shared_ptr<std::set<OmSegment*> > children =
      OmSegmentUtils::GetAllChildrenSegments(
          *segments, segments->Selection().GetSelectedSegmentIDs());

  (new OmSegmentUncertainAction(sdw, children, uncertain))->Run();
}

void OmActionsImpl::JoinSegmentsWrapper(const SegmentationDataWrapper sdw) {
  OmJoinSegmentsRunner joiner(sdw);
  joiner.Join();
}

void OmActionsImpl::JoinSegmentsSet(const SegmentationDataWrapper sdw,
                                    const om::common::SegIDSet ids) {
  OmJoinSegmentsRunner joiner(sdw, ids);
  joiner.Join();
}

void OmActionsImpl::FindAndSplitSegments(const SegmentationDataWrapper sdw,
                                         OmSegment* seg1, OmSegment* seg2) {
  if (seg1 == seg2) {
    log_infos << "can't split--same segment";
    return;
  }

  om::segment::UserEdge edge =
      OmFindCommonEdge::FindClosestCommonEdge(sdw.Segments(), seg1, seg2);

  if (!edge.valid) {
    log_infos << "edge was not splittable";
    return;
  }

  (new OmSegmentSplitAction(sdw, edge))->Run();
}

void OmActionsImpl::ShatterSegment(const SegmentationDataWrapper sdw,
                                   OmSegment* seg) {
  (new OmSegmentShatterAction(SegmentDataWrapper(sdw, seg->value())))->Run();
}

void OmActionsImpl::CutSegment(const SegmentDataWrapper sdw) {
  OmCutSegmentRunner::CutSegmentFromParent(sdw);
}

void OmActionsImpl::SelectSegments(
    std::shared_ptr<OmSelectSegmentsParams> params) {
  (new OmSegmentSelectAction(params))->Run();
}
