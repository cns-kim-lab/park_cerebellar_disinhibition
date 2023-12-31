#pragma once
#include "precomp.h"

#include "common/common.h"
#include "gui/widgets/omAskYesNoQuestion.hpp"
#include "system/omConnect.hpp"

class OmUndoStack : private QObject {
  Q_OBJECT;

 private:
  QUndoStack undoStack_;
  std::unique_ptr<QShortcut> undoShortcut_;

 private
Q_SLOTS:
  void push(QUndoCommand* cmd) { undoStack_.push(cmd); }

  void clear() { undoStack_.clear(); }

  void undo() {
    OmAskYesNoQuestion asker("Undo the following action?:\n" +
                             undoStack_.undoText());

    if (asker.Ask()) {
      undoStack_.undo();
    }
  }

Q_SIGNALS:
  void signalPush(QUndoCommand* cmd);
  void signalClear();
  void signalUndo();

 public:
  OmUndoStack() {
    om::connect(this, SIGNAL(signalPush(QUndoCommand*)), this,
                SLOT(push(QUndoCommand*)));

    om::connect(this, SIGNAL(signalClear()), this, SLOT(clear()));

    om::connect(this, SIGNAL(signalUndo()), this, SLOT(undo()));
  }

  void SetGlobalShortcut(QWidget* parent) {
    undoShortcut_.reset(new QShortcut(parent));
    undoShortcut_->setKey(Qt::CTRL + Qt::Key_Z);
    undoShortcut_->setContext(Qt::ApplicationShortcut);

    om::connect(undoShortcut_.get(), SIGNAL(activated()), this, SLOT(undo()));
  }

  ~OmUndoStack() {}

  inline QUndoStack* Get() { return &undoStack_; }

  inline void Push(QUndoCommand* cmd) { signalPush(cmd); }

  inline void Clear() { signalClear(); }

  inline void Undo() { signalUndo(); }
};
