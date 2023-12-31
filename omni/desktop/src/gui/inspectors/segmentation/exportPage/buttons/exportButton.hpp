#pragma once
#include "precomp.h"

#include "datalayer/hdf5/omExportVolToHdf5.hpp"
#include "gui/widgets/omButton.hpp"
#include "gui/inspectors/segmentation/exportPage/pageExport.h"

namespace om {
namespace segmentationInspector {

class ExportButton : public OmButton<PageExport> {
 public:
  ExportButton(PageExport* d)
      : OmButton<PageExport>(d, "Export and reroot segments", "Export", false) {
  }

 private:
  void doAction() {
    const QString fileName =
        QFileDialog::getSaveFileName(this, tr("Export As"));

    if (fileName == nullptr) return;

    const SegmentationDataWrapper& sdw = mParent->GetSDW();

    OmExportVolToHdf5::Export(sdw.GetSegmentation(), fileName, true);
  }
};

}  // namespace segmentationInspector
}  // namespace om
