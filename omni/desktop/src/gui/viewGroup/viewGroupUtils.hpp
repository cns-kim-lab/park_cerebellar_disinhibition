#pragma once
#include "precomp.h"

#include "common/common.h"
#include "gui/mainWindow/mainWindow.h"
#include "gui/viewGroup/viewGroupWidgetInfo.h"
#include "gui/widgets/omTellInfo.hpp"
#include "utility/dataWrappers.h"
#include "view2d/omView2d.h"
#include "view3d.old/omView3d.h"
#include "viewGroup/omViewGroupState.h"
#include "volume/omSegmentation.h"

namespace om {
namespace gui {

struct DockWidgetPair {
  QDockWidget* dock;
  QDockWidget* dockToTabify;
};

class ViewGroupUtils {
 private:
  MainWindow* const mainWindow_;

  OmViewGroupState& vgs_;

 public:
  ViewGroupUtils(MainWindow* mainWindow, OmViewGroupState& vgs)
      : mainWindow_(mainWindow), vgs_(vgs) {}

  ~ViewGroupUtils() {}

  int GetID();

  QList<QDockWidget*> findDockWidgets(const QString& name);
  QList<QDockWidget*> findDockWidgets(const QRegExp& regExp);

  QString viewGroupName() { return "ViewGroup" + QString::number(GetID()); }

  QString makeObjectName() { return "3d_" + viewGroupName(); }

  QString getViewName(const std::string& volName,
                      const om::common::ViewType viewType) {
    return QString::fromStdString(volName) + " -- " +
           getViewTypeAsStr(viewType) + " View";
  }

  QString getViewTypeAsStr(const om::common::ViewType viewType) {
    switch (viewType) {
      case om::common::XY_VIEW:
        return "XY";
      case om::common::XZ_VIEW:
        return "XZ";
      case om::common::ZY_VIEW:
        return "ZY";
      default:
        throw om::ArgException("unknown viewtype");
    }
  }

  QString makeObjectName(const om::common::ObjectType voltype,
                         const om::common::ViewType viewType) {
    QString name;

    if (om::common::CHANNEL == voltype) {
      name = "channel_";
    } else if (om::common::SEGMENTATION == voltype) {
      name = "segmentation_";
    } else if (om::common::AFFINITY == voltype) {
      name = "affinity_";
    }

    name += getViewTypeAsStr(viewType) + "_" + viewGroupName();

    return name;
  }

  QString makeObjectName(ViewGroupWidgetInfo& vgw) {
    if (VIEW2D_CHAN == vgw.widgetType) {
      return makeObjectName(om::common::CHANNEL, vgw.viewType);
    }

    if (VIEW2D_SEG == vgw.widgetType) {
      return makeObjectName(om::common::SEGMENTATION, vgw.viewType);
    }

    return makeObjectName();
  }

  QString makeComplimentaryObjectName(ViewGroupWidgetInfo& vgw) {
    if (VIEW2D_CHAN == vgw.widgetType) {
      return makeObjectName(om::common::SEGMENTATION, vgw.viewType);
    }

    if (VIEW2D_SEG == vgw.widgetType) {
      return makeObjectName(om::common::CHANNEL, vgw.viewType);
    }

    return "";
  }

  QDockWidget* getDockWidget(const om::common::ObjectType voltype,
                             const om::common::ViewType viewType) {
    return getDockWidget(makeObjectName(voltype, viewType));
  }

  QDockWidget* getDockWidget(const QString& objName) {
    QList<QDockWidget*> widgets = findDockWidgets(objName);

    if (widgets.isEmpty()) {
      return nullptr;
    } else if (widgets.size() > 1) {
      throw om::ArgException("too many widgets");
    }

    return widgets[0];
  }

  bool doesDockWidgetExist(const om::common::ObjectType voltype,
                           const om::common::ViewType viewType) {
    return doesDockWidgetExist(makeObjectName(voltype, viewType));
  }

  bool doesDockWidgetExist(const QString& objName) {
    QList<QDockWidget*> widgets = findDockWidgets(objName);

    if (widgets.isEmpty()) {
      return false;
    }

    return true;
  }

  QList<QDockWidget*> getAllDockWidgets() {
    QRegExp rx(".*" + viewGroupName() + "$");
    QList<QDockWidget*> widgets = findDockWidgets(rx);

    return widgets;
  }

  QDockWidget* getBiggestDockWidget() {
    QDockWidget* biggest = nullptr;
    uint64_t biggest_area = 0;

    Q_FOREACH(QDockWidget * dock, getAllDockWidgets()) {
      const uint64_t area = static_cast<uint64_t>(dock->width()) *
                            static_cast<uint64_t>(dock->height());

      if (area > biggest_area) {
        biggest_area = area;
        biggest = dock;
      }
    }

    return biggest;
  }

  bool canShowChannel(const ChannelDataWrapper& cdw) {
    if (!cdw.IsChannelValid()) {
      return false;
    }

    if (cdw.IsBuilt()) {
      return true;
    }

    OmTellInfo("channel " + om::string::num(cdw.id()) + " is not built");
    return false;
  }

  bool canShowSegmentation(const SegmentationDataWrapper& sdw) {
    if (!sdw.IsSegmentationValid()) {
      return false;
    }

    if (sdw.IsBuilt()) {
      return true;
    }

    OmTellInfo("segmentation " + om::string::num(sdw.id()) + " is not built");
    return false;
  }

  void wireDockWithView2d(QWidget* widget, DockWidgetPair d) {
    OmView2d* w = reinterpret_cast<OmView2d*>(widget);

    setComplimentaryDockWidget(w, d.dock, d.dockToTabify);

    connectVisibilityChange(w, d.dock);
  }

  void connectVisibilityChange(OmView2d* w, QDockWidget* dock);

  void setComplimentaryDockWidget(OmView2d* w, QDockWidget* dock,
                                  QDockWidget* complimentaryDock);

  ViewGroupWidgetInfo CreateView3d() {
    QString name = "3D View";

    ViewGroupWidgetInfo vgw(name, VIEW3D);

    if (doesDockWidgetExist(makeObjectName(vgw))) {
      delete getDockWidget(makeObjectName(vgw));
    }

    vgw.widget = new OmView3d(mainWindow_, vgs_);

    return vgw;
  }

  ViewGroupWidgetInfo CreateView2dChannel(const ChannelDataWrapper& cdw,
                                          const om::common::ViewType viewType) {
    if (!cdw.IsValidWrapper()) {
      throw ArgException("Invalid ChannelDataWrapper");
    }
    OmChannel& chan = *cdw.GetChannel();

    const QString name = getViewName(chan.GetName(), viewType);

    ViewGroupWidgetInfo vgw(name, VIEW2D_CHAN, viewType);

    if (doesDockWidgetExist(makeObjectName(vgw))) {
      delete getDockWidget(makeObjectName(vgw));
    }

    vgw.widget =
        new OmView2d(viewType, mainWindow_, vgs_, chan, name.toStdString());

    return vgw;
  }

  ViewGroupWidgetInfo CreateView2dSegmentation(
      const SegmentationDataWrapper& sdw, const om::common::ViewType viewType) {
    if (!sdw.IsValidWrapper()) {
      throw ArgException("Invalid SegmentationDataWrapper");
    }

    const QString name = getViewName(sdw.GetName().toStdString(), viewType);

    ViewGroupWidgetInfo vgw(name, VIEW2D_SEG, viewType);

    if (doesDockWidgetExist(makeObjectName(vgw))) {
      delete getDockWidget(makeObjectName(vgw));
    }

    vgw.widget = new OmView2d(viewType, mainWindow_, vgs_,
                              *sdw.GetSegmentation(), name.toStdString());

    return vgw;
  }
};

}  // namespace gui
}  // namespace om
