#include "gui/sidebars/left/notesEditor.h"
#include "task/task.h"
#include "task/taskManager.h"
#include "gui/exec.hpp"

using namespace om::task;

NotesEditor::NotesEditor(QWidget* parent) : QTextEdit(parent) {
  setMaximumHeight(100);
}
NotesEditor::~NotesEditor() {
}

void NotesEditor::resetNotes(std::shared_ptr<Task> task) {
  setText(task ? QString::fromStdString(task->Notes()) : tr(""));
}

void NotesEditor::focusOutEvent(QFocusEvent* e) {
  QTextEdit::focusOutEvent(e);
  auto task = TaskManager::currentTask();
  if (!task) {
    return;
  }
  auto rsl = TaskManager::UpdateTaskNotes(task->Id(), toPlainText().toStdString());
  if( !rsl ) {
    resetNotes(task);
    QMessageBox db_fail(QMessageBox::Warning, 
            "DB update failed",
            "Notes update failed, please try again.", 
            QMessageBox::Close );
    db_fail.exec();
    return;
  }
}
