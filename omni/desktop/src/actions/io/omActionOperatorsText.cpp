#include "actions/io/omActionOperatorsText.h"

#include "actions/details/omSegmentJoinActionImpl.hpp"
#include "actions/details/omSegmentSelectActionImpl.hpp"
#include "actions/details/omSegmentSplitActionImpl.hpp"
#include "actions/details/omSegmentCutActionImpl.hpp"
#include "actions/details/omSegmentValidateActionImpl.hpp"
#include "actions/details/omSegmentUncertainActionImpl.hpp"
#include "actions/details/omSegmentationThresholdChangeActionImpl.hpp"
#include "actions/details/omSegmentationSizeThresholdChangeActionImpl.hpp"
#include "actions/details/omVoxelSetValueActionImpl.hpp"
#include "actions/details/omProjectCloseActionImpl.hpp"

QTextStream& operator<<(QTextStream& out, const SegmentationDataWrapper& sdw) {
  out << QString::number(sdw.GetSegmentationID());
  return out;
}

QTextStream& operator<<(QTextStream& out, const om::common::SegIDSet& set) {
  const std::string nums = om::string::join(set);
  out << QString::fromStdString(nums);
  return out;
}

QTextStream& operator<<(QTextStream& out, const om::segment::UserEdge& e) {
  out << e.parentID << ", " << e.childID << ", " << e.threshold;
  return out;
}

QTextStream& operator<<(QTextStream& out, const OmVoxelSetValueActionImpl&) {
  return out;
}

QTextStream& operator<<(QTextStream& out, const OmProjectCloseActionImpl&) {
  return out;
}

QTextStream& operator<<(QTextStream& out, const OmProjectSaveActionImpl&) {
  return out;
}

QTextStream& operator<<(QTextStream& out, const OmSegmentJoinActionImpl& a) {
  out << a.segIDs_;
  return out;
}

QTextStream& operator<<(QTextStream& out, const OmSegmentSelectActionImpl& a) {
  out << a.params_->newSelectedIDs;
  return out;
}

QTextStream& operator<<(QTextStream& out, const OmSegmentSplitActionImpl& a) {
  out << a.mEdge;
  return out;
}

QTextStream& operator<<(QTextStream& out, const OmSegmentCutActionImpl& a) {
  out << "segment " << a.sdw_ << ": ";

  FOR_EACH(iter, a.edges_) { out << *iter << ";"; }
  return out;
}

QTextStream& operator<<(QTextStream& out, const OmSegmentUncertainActionImpl&) {
  return out;
}

QTextStream& operator<<(QTextStream& out,
                        const OmSegmentValidateActionImpl& a) {
  out << a.sdw_;
  out << a.valid_;
  return out;
}

QTextStream& operator<<(QTextStream& out,
                        const OmSegmentationThresholdChangeActionImpl& a) {
  out << "(new: ";
  out << a.threshold_;
  out << ", old: ";
  out << a.oldThreshold_;
  out << ", segmentation: ";
  out << a.sdw_;
  out << ")";

  return out;
}

QTextStream& operator<<(QTextStream& out,
                        const OmSegmentationSizeThresholdChangeActionImpl& a) {
  out << "(new: ";
  out << a.threshold_;
  out << ", old: ";
  out << a.oldThreshold_;
  out << ", segmentation: ";
  out << a.sdw_;
  out << ")";

  return out;
}
