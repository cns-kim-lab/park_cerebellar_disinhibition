#pragma once
#include "precomp.h"

#include "common/common.h"

enum WIDGET_TYPE {
  VIEW2D_CHAN,
  VIEW2D_SEG,
  VIEW3D
};

class ViewGroupWidgetInfo {

 public:
  ViewGroupWidgetInfo(const QString& in_name, const WIDGET_TYPE in_widgetType)
      : name(in_name), widgetType(in_widgetType), dir_(Qt::Horizontal) {}

  ViewGroupWidgetInfo(const QString& in_name, const WIDGET_TYPE in_widgetType,
                      const om::common::ViewType in_viewType)
      : name(in_name),
        widgetType(in_widgetType),
        viewType(in_viewType),
        dir_(Qt::Horizontal) {}

  QWidget* widget;
  const QString name;
  const WIDGET_TYPE widgetType;

  om::common::ViewType viewType;

  Qt::Orientation Dir() const { return dir_; }

  void Dir(const Qt::Orientation dir) { dir_ = dir; }

 private:
  Qt::Orientation dir_;
};
