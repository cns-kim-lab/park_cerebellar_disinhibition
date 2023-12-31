#include "actions/omSelectSegmentParams.hpp"
#include "common/common.h"
#include "gui/segmentLists/details/segmentListBase.h"
#include "gui/segmentLists/elementListBox.hpp"
#include "gui/segmentLists/omSegmentListWidget.h"
#include "project/omProject.h"
#include "segment/lists/omSegmentLists.h"
#include "segment/lists/omSegmentListsTypes.hpp"
#include "segment/omSegmentCenter.hpp"
#include "segment/omSegmentSearched.hpp"
#include "segment/omSegmentSelector.h"
#include "segment/omSegmentUtils.hpp"
#include "segment/omSegments.h"
#include "system/omConnect.hpp"
#include "utility/segmentDataWrapper.hpp"
#include "utility/segmentationDataWrapper.hpp"
#include "volume/omSegmentation.h"

SegmentListBase::SegmentListBase(QWidget* parent, OmViewGroupState& vgs)
    : QWidget(parent), haveValidSDW(false), currentPageNum_(0), vgs_(vgs) {
  layout = new QVBoxLayout(this);

  segmentListWidget = new OmSegmentListWidget(this, vgs);
  layout->addWidget(segmentListWidget);

  setupPageButtons();
}

int SegmentListBase::getNumSegmentsPerPage() { return 100; }

quint32 SegmentListBase::getTotalNumberOfSegments() {
  assert(haveValidSDW);
  return Size();
}

void SegmentListBase::populateByPage() {
  assert(haveValidSDW);

  size_t totalPages = getTotalNumberOfSegments() / getNumSegmentsPerPage();

  if (currentPageNum_ < 0) {
    currentPageNum_ = 0;
  } else if (currentPageNum_ > totalPages) {
    currentPageNum_ = totalPages;
  }

  GUIPageRequest request;
  request.offset = currentPageNum_ * getNumSegmentsPerPage();
  request.numToGet = getNumSegmentsPerPage();
  request.startSeg = 0;

  std::shared_ptr<GUIPageOfSegments> segIDs = getPageSegments(request);

  currentPageNum_ = segIDs->pageNum;

  const bool shouldThisTabBeMadeActive =
      segmentListWidget->populate(false, SegmentDataWrapper(sdw_, 0), segIDs);

  if (shouldThisTabBeMadeActive) {
    makeTabActiveIfContainsJumpedToSegment();
  }

  ElementListBox::AddTab(getPreferredTabIndex(), this, getTabTitle());
}

void SegmentListBase::populateBySegment(
    const bool doScrollToSelectedSegment,
    const SegmentDataWrapper segmentJustSelected) {
  assert(haveValidSDW);

  GUIPageRequest request;
  request.offset = 0;
  request.numToGet = getNumSegmentsPerPage();
  request.startSeg = segmentJustSelected.GetSegmentID();

  std::shared_ptr<GUIPageOfSegments> segIDs = getPageSegments(request);

  currentPageNum_ = segIDs->pageNum;

  const bool shouldThisTabBeMadeActive = segmentListWidget->populate(
      doScrollToSelectedSegment, segmentJustSelected, segIDs);

  if (shouldThisTabBeMadeActive) {
    makeTabActiveIfContainsJumpedToSegment();
  }

  ElementListBox::AddTab(getPreferredTabIndex(), this, getTabTitle());
}

void SegmentListBase::setupPageButtons() {
  int x = 30, y = 30;
  startButton = new QPushButton("|<<");
  startButton->setFixedSize(x, y);
  prevButton = new QPushButton("<");
  prevButton->setFixedSize(x, y);
  nextButton = new QPushButton(">");
  nextButton->setFixedSize(x, y);
  endButton = new QPushButton(">>|");
  endButton->setFixedSize(x, y);

  searchEdit = new QLineEdit();
  searchEdit->setMaxLength(searchEdit->maxLength() * 10);

  om::connect(searchEdit, SIGNAL(returnPressed()), this, SLOT(searchChanged()));

  om::connect(startButton, SIGNAL(released()), this, SLOT(goToStartPage()));

  om::connect(prevButton, SIGNAL(released()), this, SLOT(goToPrevPage()));

  om::connect(nextButton, SIGNAL(released()), this, SLOT(goToNextPage()));

  om::connect(endButton, SIGNAL(released()), this, SLOT(goToEndPage()));

  om::connect(endButton, SIGNAL(released()), this, SLOT(goToEndPage()));

  QGroupBox* buttonBox = new QGroupBox("");
  buttonBox->setFlat(true);
  QHBoxLayout* buttons = new QHBoxLayout(buttonBox);

  buttons->addWidget(startButton);
  buttons->addWidget(prevButton);
  buttons->addWidget(nextButton);
  buttons->addWidget(endButton);
  layout->addWidget(buttonBox);

  QGroupBox* searchBox = new QGroupBox("");
  searchBox->setFlat(true);
  QHBoxLayout* searchLayout = new QHBoxLayout(searchBox);
  searchLayout->addWidget(searchEdit);
  layout->addWidget(searchBox);
}

void SegmentListBase::goToStartPage() {
  currentPageNum_ = 0;
  populateByPage();
}

void SegmentListBase::goToNextPage() {
  ++currentPageNum_;
  populateByPage();
}

void SegmentListBase::goToPrevPage() {
  --currentPageNum_;
  populateByPage();
}

void SegmentListBase::goToEndPage() {
  currentPageNum_ = (getTotalNumberOfSegments() / getNumSegmentsPerPage());
  populateByPage();
}

void SegmentListBase::makeSegmentationActive(const SegmentDataWrapper& sdw,
                                             const bool doScroll) {
  sdw_ = sdw.MakeSegmentationDataWrapper();
  haveValidSDW = true;
  populateBySegment(doScroll, sdw);
}

void SegmentListBase::rebuildSegmentList(const SegmentDataWrapper& sdw) {
  makeSegmentationActive(sdw, true);
}

void SegmentListBase::MakeSegmentationActive(
    const SegmentationDataWrapper& sdw) {
  sdw_ = sdw;
  haveValidSDW = true;
  populateByPage();
}

void SegmentListBase::RefreshPage(const SegmentationDataWrapper& sdw) {
  sdw_ = sdw;
  haveValidSDW = true;
  populateByPage();
}

void SegmentListBase::searchChanged() {
  const QString text = searchEdit->text();

  if (text.contains(",")) {
    const QStringList args = text.split(",", QString::SkipEmptyParts);
    searchMany(args);
    return;
  }

  const QStringList args = text.split(" ", QString::SkipEmptyParts);

  if (1 == args.size()) {
    searchOne(text);
    return;
  }

  searchMany(args);
}

void SegmentListBase::searchOne(const QString& text) {
  const om::common::SegID segID = text.toInt();
  SegmentDataWrapper sdw(sdw_, segID);

  if (!sdw.IsSegmentValid()) {
    return;
  }

  OmSegmentSearched::Set(sdw);

  OmSegmentSelector sel(sdw_, nullptr, "segmentlistbase");
  sel.selectJustThisSegment(segID, true);
  sel.AutoCenter(true);
  sel.sendEvent();

  makeSegmentationActive(sdw, true);
}

void SegmentListBase::searchMany(const QStringList& args) {
  OmSegmentSelector sel(sdw_, nullptr, "segmentlistbase");

  // TODO: allow modifiers (like "-" to remove a segment from the selection)

  FOR_EACH(iter, args) {
    const om::common::SegID segID = iter->toInt();
    SegmentDataWrapper sdw(sdw_, segID);

    if (!sdw.IsSegmentValid()) {
      continue;
    }

    sel.augmentSelectedSet(segID, true);
  }

  sel.AutoCenter(true);
  sel.sendEvent();
}

void SegmentListBase::userJustClickedInThisSegmentList() {
  ElementListBox::SetActiveTab(this);
}
