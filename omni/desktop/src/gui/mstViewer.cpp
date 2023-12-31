#include "utility/dataWrappers.h"
#include "gui/mstViewer.hpp"
#include "volume/omSegmentation.h"
#include "segment/omSegments.h"
#include "segment/omSegment.h"

MstViewerImpl::MstViewerImpl(QWidget* parent, SegmentationDataWrapper sdw)
    : QTableWidget(parent), sdw_(sdw) {
  populate();
}

void MstViewerImpl::populate() {
  if (!sdw_.IsValidWrapper()) {
    throw om::ArgException("Invalid SegmentationDataWrapper");
  }
  auto& edges = sdw_.GetSegmentation()->MST();

  QStringList headerLabels;
  headerLabels << "Edge"
               << "Node 1"
               << "Node 2"
               << "threshold"
               << "Node 1 size"
               << "Node 2 size";
  setColumnCount(headerLabels.size());
  setHorizontalHeaderLabels(headerLabels);

  setRowCount(edges.size());

  for (int i = 0; i < edges.size(); ++i) {
    const om::common::SegID node1ID = edges[i].node1ID;
    const om::common::SegID node2ID = edges[i].node2ID;
    const float threshold = edges[i].threshold;

    OmSegment* node1 = sdw_.Segments()->GetSegment(node1ID);
    OmSegment* node2 = sdw_.Segments()->GetSegment(node2ID);

    int colNum = 0;
    setCell(i, colNum, i);
    setCell(i, colNum, node1ID);
    setCell(i, colNum, node2ID);
    setCell(i, colNum, threshold);
    setCell(i, colNum, static_cast<quint64>(node1->size()));
    setCell(i, colNum, static_cast<quint64>(node2->size()));
  }

  setSortingEnabled(true);  // don't enable sorting until done inserting
  sortItems(0);             // sort by edge number
}
