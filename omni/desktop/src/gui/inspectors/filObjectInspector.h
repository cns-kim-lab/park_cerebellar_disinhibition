#pragma once
#include "precomp.h"

#include "project/omProject.h"

class FilterDataWrapper;

class FilObjectInspector : public QWidget {
  Q_OBJECT;

 public:
  FilObjectInspector(QWidget *parent, const FilterDataWrapper &fdw);

 private
Q_SLOTS:
  void sourceEditChangedChan();
  void sourceEditChangedSeg();
  void setFilAlpha(int);
  void saveFilterAlphaValue();

 private:
  QSlider *alphaSlider;

  std::shared_ptr<FilterDataWrapper> fdw_;

  QLineEdit *chanEdit;
  QLineEdit *segEdit;
  QLineEdit *tagsEdit;
  QPlainTextEdit *notesEdit;

  QGroupBox *makeFilterOptionsBox();
  QGroupBox *makeNotesBox();

  void set_initial_values();
  int GetSegmentationIDtoFilter();
  int getChannelIDtoFilter();
};
