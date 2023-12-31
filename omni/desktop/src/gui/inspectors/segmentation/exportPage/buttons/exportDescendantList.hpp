#pragma once
#include "precomp.h"

#include "segment/omSegmentIterator.h"
#include "datalayer/fs/omFile.hpp"
#include "gui/inspectors/segmentation/exportPage/pageExport.h"
#include "gui/widgets/omButton.hpp"
#include "segment/omSegments.h"
#include "utility/dataWrappers.h"
#include "segment/omSegment.h"

namespace om {
namespace segmentationInspector {

class ExportDescendantList : public OmButton<PageExport> {
 public:
  ExportDescendantList(PageExport* d)
      : OmButton<PageExport>(d, "Export Segment Descendant List",
                             "Export Segment Descendant List", false) {}

 private:
  void doAction() {
    const SegmentationDataWrapper& sdw = mParent->GetSDW();

    OmSegments* segments = sdw.Segments();

    const QString outFile =
        OmProject::OmniFile() + ".segmentsDescendantChildren.txt";

    QFile file(outFile);

    om::file::old::openFileWO(file);

    log_infos << "writing segment file " << qPrintable(outFile);

    QTextStream out(&file);

    for (om::common::SegID i = 1; i <= segments->maxValue(); ++i) {
      OmSegment* seg = segments->GetSegment(i);

      if (!seg) {
        continue;
      }

      out << i << ": ";

      if (seg->getParent()) {
        out << "child\n";
        continue;
      }

      QString ids = getIds(i, segments);
      out << ids << "\n";
    }

    log_infos << "\tdone!";
  }

 private:
  QString getIds(const om::common::SegID segID, OmSegments* segments) {
    OmSegmentIterator iter(*segments);
    iter.iterOverSegmentID(segID);

    OmSegment* seg = iter.getNextSegment();

    QStringList ids;

    while (nullptr != seg) {
      ids << QString::number(seg->value());
      seg = iter.getNextSegment();
    }

    return ids.join(",");
  }
};

}  // namespace segmentationInspector
}  // namespace om
