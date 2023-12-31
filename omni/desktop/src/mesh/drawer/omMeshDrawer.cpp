#include "mesh/drawer/omMeshDrawer.h"
#include "mesh/drawer/omMeshDrawerImpl.hpp"
#include "mesh/drawer/omMeshPlanCache.hpp"
#include "mesh/io/omMeshMetadata.hpp"
#include "mesh/omMeshManager.h"

OmMeshDrawer::OmMeshDrawer(OmSegmentation* segmentation)
    : segmentation_(segmentation),
      rootSegLists_(std::make_shared<OmMeshSegmentList>(segmentation)),
      cache_(std::make_shared<OmMeshPlanCache>(segmentation_,
                                               rootSegLists_.get())),
      numPrevRedraws_(0) {}

boost::optional<std::pair<float, float> > OmMeshDrawer::Draw(
    OmViewGroupState& vgs, std::shared_ptr<OmVolumeCuller> culler,
    const OmBitfield drawOptions) {
  if (!segmentation_->MeshManager(1)->Metadata()->IsBuilt()) {
    return boost::optional<std::pair<float, float> >();
  }

  std::shared_ptr<OmMeshPlan> sortedSegments =
      cache_->GetSegmentsToDraw(vgs, culler, drawOptions);

  updateNumPrevRedraws(culler);

  OmMeshDrawerImpl drawer(segmentation_, vgs, drawOptions,
                          sortedSegments.get());

  drawer.Draw(getAllowedDrawTime());

  if (drawer.RedrawNeeded()) {
    std::pair<float, float> p(drawer.NumVoxelsDrawn(),
                              drawer.TotalVoxelsPresent());
    return boost::optional<std::pair<float, float> >(p);
  } else {
    return boost::optional<std::pair<float, float> >();
  }
}

void OmMeshDrawer::updateNumPrevRedraws(
    std::shared_ptr<OmVolumeCuller> culler) {
  if (!culler_ || !culler_->equals(culler)) {
    culler_ = culler;
    numPrevRedraws_ = 0;
    return;
  }

  ++numPrevRedraws_;
}

int OmMeshDrawer::getAllowedDrawTime() {
  static const int maxElapsedDrawTimeMS = 50;  // attempt 20 fps...
  static const int maxAllowedDrawTime = 250;
  static const int numRoundsBeforeUpMaxTime = 10;

  if (numPrevRedraws_ < numRoundsBeforeUpMaxTime) {
    return maxElapsedDrawTimeMS;
  }

  const int maxRedrawMS =
      (numPrevRedraws_ / numRoundsBeforeUpMaxTime) * maxElapsedDrawTimeMS;
  if (maxRedrawMS > maxAllowedDrawTime) {
    return maxAllowedDrawTime;
  }

  return maxRedrawMS;
}
