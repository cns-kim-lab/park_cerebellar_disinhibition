#pragma once
#include "precomp.h"

#include "common/common.h"
#include "gui/toolbars/toolbarManager.h"
#include "segment/omSegmentSelected.hpp"
#include "system/omAppState.hpp"
#include "system/omConnect.hpp"
#include "system/omStateManager.h"
#include "viewGroup/omBrushSize.hpp"
#include "utility/segmentationDataWrapper.hpp"

#include "task/taskManager.h" //jwgim 180131
using namespace om::task;

class OmGlobalKeyPress : public QWidget {
  Q_OBJECT;

 private:
  QWidget* const parent_;

  //jwgim 180126 shortcut disable : a,b,m,k,l,period,comma
  // std::unique_ptr<QShortcut> a_;
  // std::unique_ptr<QShortcut> b_;
  // std::unique_ptr<QShortcut> comma_;
  std::unique_ptr<QShortcut> greater_;
  std::unique_ptr<QShortcut> j_;
  std::unique_ptr<QShortcut> less_;
  // std::unique_ptr<QShortcut> m_;
  std::unique_ptr<QShortcut> n_;
  // std::unique_ptr<QShortcut> period_;
  std::unique_ptr<QShortcut> r_;
  // std::unique_ptr<QShortcut> k_;
  // std::unique_ptr<QShortcut> l_;
  std::unique_ptr<QShortcut> v_;  //jwgim 180112
  std::unique_ptr<QShortcut> d_;  //jwgim 180131
  std::unique_ptr<QShortcut> p_;  //jwgim 180831
  // std::unique_ptr<QShortcut> slash_;

  void setShortcut(std::unique_ptr<QShortcut>& shortcut, const QKeySequence key,
                   const char* method) {
    shortcut.reset(new QShortcut(parent_));
    shortcut->setKey(key);
    shortcut->setContext(Qt::ApplicationShortcut);

    om::connect(shortcut.get(), SIGNAL(activated()), this, method);
  }

  void setTool(const om::tool::mode tool) {
    auto* tbm = OmAppState::GetToolBarManager();
    if (tbm) {
      tbm->SetTool(tool);
    }
  }

 private
Q_SLOTS:
  // void keyA() { setTool(om::tool::ANNOTATE); }
  // void keyB() { setTool(om::tool::PAN); }
  void keyN() { setTool(om::tool::SELECT); }
  // void keyM() { setTool(om::tool::PAINT); }
  // void keyComma() { setTool(om::tool::ERASE); }
  // void keyPeriod() { setTool(om::tool::FILL); }
  // void keyK() { setTool(om::tool::CUT); }
  // void keyL() { setTool(om::tool::LANDMARK); }
  void keyR() { OmSegmentSelected::RandomizeColor(); }

  void keyLess() {
    OmStateManager::BrushSize()->DecreaseSize();
    om::event::Redraw2d();
  }

  void keyGreater() {
    OmStateManager::BrushSize()->IncreaseSize();
    om::event::Redraw2d();
  }

  void keyJ() {
    for (const auto& id : SegmentationDataWrapper::ValidIDs()) {
      OmActions::JoinSegments(SegmentationDataWrapper(id));
    }

    om::event::Redraw2d();
    om::event::Redraw3d();
  }


  void keyV() { //jwgim 180112
    for (const auto& id : SegmentationDataWrapper::ValidIDs()) {
      OmActions::ValidateSelectedSegments(SegmentationDataWrapper(id), om::common::SetValid::SET_VALID);
    }
  }

  void keyD() { //jwgim 180131
    if (TaskManager::SubmitTask(true)) {
      OmActions::Save();
      OmAppState::OpenTaskSelector();
    }
  }

  void keyP() { //jwgim 180831
    if( !TaskManager::AttemptSkipTask() )
      return;    
    OmAppState::OpenTaskSelector();
  }

 public:
  OmGlobalKeyPress(QWidget* parent) : QWidget(parent), parent_(parent) {
    // setShortcut(a_, QKeySequence(Qt::Key_A), SLOT(keyA()));
    // setShortcut(b_, QKeySequence(Qt::Key_B), SLOT(keyB()));
    setShortcut(j_, QKeySequence(Qt::Key_J), SLOT(keyJ()));
    // setShortcut(comma_, QKeySequence(Qt::Key_Comma), SLOT(keyComma()));
    setShortcut(greater_, QKeySequence(Qt::Key_Greater), SLOT(keyGreater()));
    setShortcut(less_, QKeySequence(Qt::Key_Less), SLOT(keyLess()));
    // setShortcut(m_, QKeySequence(Qt::Key_M), SLOT(keyM()));
    setShortcut(n_, QKeySequence(Qt::Key_N), SLOT(keyN()));
    // setShortcut(period_, QKeySequence(Qt::Key_Period), SLOT(keyPeriod()));
    setShortcut(r_, QKeySequence(Qt::Key_R), SLOT(keyR()));
    // setShortcut(k_, QKeySequence(Qt::Key_K), SLOT(keyK()));
    // setShortcut(l_, QKeySequence(Qt::Key_L), SLOT(keyL()));
    setShortcut(v_, QKeySequence(Qt::Key_V), SLOT(keyV())); //jwgim 180112
    setShortcut(d_, QKeySequence(Qt::Key_D), SLOT(keyD())); //jwgim 180131
    setShortcut(p_, QKeySequence(Qt::Key_P), SLOT(keyP())); //jwgim 180831
    // setShortcut(slash_,   QKeySequence(Qt::Key_Slash),   SLOT(keySlash()));
  }
};
