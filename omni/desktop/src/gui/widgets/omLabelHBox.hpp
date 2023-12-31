#pragma once
#include "precomp.h"

#include "common/common.h"

namespace om {
enum Side {
  LEFT_SIDE,
  RIGHT_SIDE
};
}

class OmLabelHBox : public QGroupBox {
 private:
  QHBoxLayout* layout_;
  QLabel* label_;

 public:
  OmLabelHBox(QWidget* parent, QWidget* w, const om::Side labelSide,
              const QString& text)
      : QGroupBox(parent),
        layout_(new QHBoxLayout(this)),
        label_(new QLabel(this)) {
    switch (labelSide) {
      case om::Side::LEFT_SIDE:
        layout_->addWidget(label_);
        layout_->addWidget(w);
        break;
      case om::Side::RIGHT_SIDE:
        layout_->addWidget(w);
        layout_->addWidget(label_);
        break;
      default:
        throw om::ArgException("unknown side");
    }

    setContentsMargins(0, 0, 0, 0);

    if ("" != text) {
      label_->setText(text);
    }
  }

  QLabel* Label() { return label_; }
};
