#include "utility/yaml/omBaseTypes.hpp"
#include "datalayer/archive/segmentation.h"
#include "utility/yaml/mipVolume.hpp"
#include "segment/omSegment.h"
#include "segment/omSegments.h"
#include "segment/omSegmentsImpl.h"
#include "segment/selection.hpp"
#include "segment/io/omValidGroupNum.hpp"
#include "project/details/omSegmentationManager.h"
#include "utility/yaml/genericManager.hpp"
#include "datalayer/archive/dummy.hpp"

namespace YAMLold {

Emitter& operator<<(Emitter& out, const OmSegmentationManager& m) {
  out << BeginMap;
  genericManager::Save(out, m.manager_);
  out << EndMap;
  return out;
}

void operator>>(const Node& in, OmSegmentationManager& m) {
  genericManager::Load(in, m.manager_);
}

Emitter& operator<<(Emitter& out, const OmSegmentation& seg) {
  out << BeginMap;
  mipVolume<const OmSegmentation> volArchive(seg);
  volArchive.Store(out);

  out << Key << "Segments" << Value << (*seg.segments_);
  out << Key << "Num Edges" << Value << seg.mst_->size();

  DummyGroups dg;
  out << Key << "Groups" << Value << dg;

  out << EndMap;

  return out;
}

void operator>>(const Node& in, OmSegmentation& seg) {
  mipVolume<OmSegmentation> volArchive(seg);
  volArchive.Load(in);

  in["Segments"] >> (*seg.segments_);
  // in["Num Edges"] >> seg.mst_->size();

  seg.LoadVolDataIfFoldersExist();

  // seg.mst_->Read();
  // seg.validGroupNum_->Load();
  // seg.segments_->StartCaches();
  seg.segments_->refreshTree();
}

Emitter& operator<<(Emitter& out, const OmSegments& sc) {
  out << BeginMap;

  out << Key << "Num Segments" << Value << sc.GetNumSegments();
  out << Key << "Max Value" << Value << sc.maxValue();
  out << (*sc.impl_);

  out << EndMap;
  return out;
}

void operator>>(const Node& in, OmSegments& sc) { in >> (*sc.impl_); }

Emitter& operator<<(Emitter& out, const OmSegmentsImpl& sc) {
  out << Key << "Enabled Segments" << Value << std::set<om::common::SegID>();
  out << Key << "Selected Segments" << Value << sc.Selection().selected_;

  out << Key << "Segment Custom Names" << Value << sc.segmentCustomNames_;
  out << Key << "Segment Notes" << Value << sc.segmentNotes_;
  return out;
}

void operator>>(const Node& in, OmSegmentsImpl& sc) {
  // uint32_t maxValue;
  // in["Num Segments"] >> sc.mNumSegs;
  // in["Max Value"] >> maxValue;
  // sc.maxValue_.set(maxValue);

  // in["Enabled Segments"] >> sc.enabledSegments_->enabled_;
  in["Selected Segments"] >> sc.Selection().selected_;

  in["Segment Custom Names"] >> sc.segmentCustomNames_;
  in["Segment Notes"] >> sc.segmentNotes_;
}

Emitter& operator<<(Emitter& out, const DummyGroups& g) {
  out << BeginMap;
  genericManager::Save(out, g.mGroupManager);
  out << Key << "Group Names" << Value << g.mGroupsByName;
  out << EndMap;
  return out;
}

Emitter& operator<<(Emitter& out, const DummyGroup& g) {
  out << BeginMap;
  out << Key << "Id" << Value << g.GetID();
  out << Key << "Note" << Value << g.GetNote();
  out << Key << "Custom Name" << Value << g.GetCustomName();
  out << Key << "Name" << Value << g.mName;
  out << Key << "Ids" << Value << g.mIDs;
  out << EndMap;
  return out;
}

}  // namespace YAMLold
