#include "events/details/preferenceEvent.h"
#include "gl.h"
#include "common/logging.h"
#include "utility/glInclude.h"
#include "mesh/drawer/omMeshDrawer.h"
#include "mesh/io/omMeshMetadata.hpp"
#include "mesh/omMeshManager.h"
#include "mesh/omMeshManagers.hpp"
#include "mesh/omVolumeCuller.h"
#include "segment/omSegmentCenter.hpp"
#include "segment/omSegmentSelected.hpp"
#include "segment/omSegmentUtils.hpp"
#include "system/omAppState.hpp"
#include "system/omLocalPreferences.hpp"
#include "system/omPreferenceDefinitions.h"
#include "system/omPreferences.h"
#include "system/omStateManager.h"
#include "omView3d.h"
#include "viewGroup/omViewGroupState.h"
#include "viewGroup/omViewGroupView2dState.hpp"
#include "widgets/omChunkExtentWidget.h"
#include "widgets/omInfoWidget.h"
#include "widgets/omPercDone.hpp"
#include "widgets/omSelectionWidget.h"
#include "widgets/omViewBoxWidget.h"
#include "widgets/annotationsWidget.h"

DECLARE_ZiARG_bool(noView3dThrottle);

namespace om {
namespace v3d {
namespace old {
enum widgets {
  selection = 0,
  viewbox,
  info,
  chunk_extent,
  perc_done,
  annotations
};
}
}  // namespace v3d
}  // namespace om

/*
 *  Constructs View3d widget that shares with the primary widget.
 */
OmView3d::OmView3d(QWidget* parent, OmViewGroupState& vgs)
#ifdef ZI_OS_MACOS
    : QGLWidget(QGLFormat(QGL::DoubleBuffer | QGL::DepthBuffer), parent,
                vgs->get3dContext())
#else
    : QGLWidget(QGLFormat(QGL::DoubleBuffer | QGL::DepthBuffer), parent)
#endif
      ,
      mView3dUi(this, vgs),
      vgs_(vgs),
      meshesFound_(false),
      segmentations_(SegmentationDataWrapper::GetPtrVec()) {
  // set keyboard policy
  setFocusPolicy(Qt::ClickFocus);
  setAttribute(Qt::WA_AcceptTouchEvents);

  // setup widgets
  widgets_.push_back(new OmSelectionWidget(this));  // index = 0
  widgets_.push_back(new OmViewBoxWidget(this, vgs));
  widgets_.push_back(new OmInfoWidget(this));
  widgets_.push_back(new OmChunkExtentWidget(this));
  widgets_.push_back(new OmPercDone(this));
  widgets_.push_back(new AnnotationsWidget(this, vgs));

  // update enabled state of widgets
  UpdateEnabledWidgets();

  mDrawTimer.stop();
  connect(&mDrawTimer, SIGNAL(timeout()), this, SLOT(updateGL()));

  mElapsed.reset(new QTime());
  mElapsed->start();

  grabGesture(Qt::PanGesture);
  grabGesture(Qt::PinchGesture);
  grabGesture(Qt::SwipeGesture);
}

OmView3d::~OmView3d() {
  if (mDrawTimer.isActive()) {
    mDrawTimer.stop();
  }

  FOR_EACH(iter, segmentations_) {
    OmSegmentation* vol = *iter;
    vol->MeshManagers().ClearMeshCaches();
  }
}

/////////////////////////////////
///////          Accessor Methods

OmCamera& OmView3d::GetCamera() { return mCamera; }

/////////////////////////////////
///////          GL Event Methods

void OmView3d::initializeGL()
    // The initializeGL() function is called just once, before paintGL() is
    // called.
{

  glShadeModel(GL_SMOOTH);  // shading mathod: GL_SMOOTH or GL_FLAT
  glPixelStorei(GL_UNPACK_ALIGNMENT, 4);  // 4-byte pixel alignment

  // enable /disable features
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  // glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
  // glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_LIGHTING);
  glEnable(GL_NORMALIZE);  // normalize normals for lighting
                           // glEnable(GL_TEXTURE_2D);

  // glEnable(GL_CULL_FACE);  // enable culling
  // glCullFace(GL_BACK);  // specify backface culling

  // set material properties
  glEnable(GL_COLOR_MATERIAL);  // cause material to track current color
  glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);  // cause ambient and
                                                      // diffust to track color

  float black[4] = {0, 0, 0, 0};
  glMaterialfv(GL_FRONT, GL_AMBIENT, black);
  glMaterialfv(GL_FRONT, GL_SPECULAR, black);

  // set drawing properties

  SetBackgroundColor();    // background color
  glClearStencil(0);       // clear stencil buffer
  glClearDepth(1.0f);      // 0 is mynear, 1 is myfar
  glDepthFunc(GL_LEQUAL);  // drawn if depth value is less than or equal
                           // than previous stored depth value

  SetBlending();
  glEnable(GL_BLEND);  // enable blending for transparency
  // glBlendFunc(GL_SRC_ALPHA, GL_ONE);  // set blend function
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  // glBlendFunc(GL_ONE_MINUS_DST_ALPHA, GL_DST_ALPHA);

  initLights();

  Vector4i viewport(0, 0, 400, 300);
  mCamera.SetViewport(viewport);  // set viewport

  SetCameraPerspective();  // camera props
}

/*
 *  Window resize event
 */
void OmView3d::resizeGL(int width, int height) {
  mCamera.ApplyReshape(Vector2i(width, height));
}

/*
 *  Paint window event.
 */
void OmView3d::paintGL() {
  Draw(DRAWOP_LEVEL_ALL | DRAWOP_RENDERMODE_RENDER | DRAWOP_DRAW_WIDGETS);
}

/*
 * Interface to the real updateGL.
 */
void OmView3d::myUpdate() {
  if (ZiARG_noView3dThrottle) {
    updateGL();
  } else {
    doTimedDraw();
  }
}

void OmView3d::doTimedDraw() {
  if (mElapsed->elapsed() > 1000) {
    mElapsed->restart();
    updateGL();
  }

  if (mDrawTimer.isActive()) {
    mDrawTimer.stop();
    mDrawTimer.start(100);
    mDrawTimer.setSingleShot(true);
  } else {
    mDrawTimer.start(100);
    mDrawTimer.setSingleShot(true);
  }
}

/////////////////////////////////
///////          QEvent Methods

void OmView3d::mousePressEvent(QMouseEvent* event) {
  try {
    mView3dUi.MousePressed(event);
  }
  catch (...) {
  }
}

void OmView3d::mouseReleaseEvent(QMouseEvent* event) {
  mView3dUi.MouseRelease(event);
}

void OmView3d::mouseMoveEvent(QMouseEvent* event) {
  mView3dUi.MouseMove(event);
}

void OmView3d::mouseDoubleClickEvent(QMouseEvent* event) {
  mView3dUi.MouseDoubleClick(event);
}

void OmView3d::mouseWheelEvent(QWheelEvent* event) {
  mView3dUi.MouseWheel(event);
}

void OmView3d::keyPressEvent(QKeyEvent* event) { mView3dUi.KeyPress(event); }

void OmView3d::wheelEvent(QWheelEvent* event) { mouseWheelEvent(event); }

/////////////////////////////////
///////          Omni Event

/*
 *  Calls function for relevant preferences and redraws,
 *  otherwise event is ignored.
 */
void OmView3d::PreferenceChangeEvent(om::event::PreferenceEvent* event) {
  switch (event->GetPreference()) {

    case om::PREF_VIEW3D_HIGHLIGHT_ENABLED_BOOL:
    case om::PREF_VIEW3D_SHOW_VIEWBOX_BOOL:
    case om::PREF_VIEW3D_SHOW_INFO_BOOL:
    case om::PREF_VIEW3D_SHOW_CHUNK_EXTENT_BOOL:
      UpdateEnabledWidgets();
      break;

    case om::PREF_VIEW3D_BACKGROUND_COLOR_V3F:
      SetBackgroundColor();
      break;

    case om::PREF_VIEW3D_TRANSPARENT_UNSELECTED_BOOL:
      SetBlending();
      break;

    case om::PREF_VIEW3D_CAMERA_FAR_PLANE_FLT:
    case om::PREF_VIEW3D_CAMERA_NEAR_PLANE_FLT:
    case om::PREF_VIEW3D_CAMERA_FOV_FLT:
      // SetCameraPerspective();
      break;

    case om::PREF_VIEW3D_TRANSPARENT_ALPHA_FLT:
      break;

    default:
      return;
  }

  myUpdate();
}

void OmView3d::SegmentModificationEvent(om::event::SegmentEvent*) {
  myUpdate();
}

void OmView3d::ViewBoxChangeEvent() { myUpdate(); }

void OmView3d::View3dRedrawEvent() { myUpdate(); }

void OmView3d::View3dRedrawEventFromCache() { myUpdate(); }

void OmView3d::View3dRecenter() {
  boost::optional<float> distance =
      OmSegmentCenter::ComputeCameraDistanceForSelectedSegments();

  if (!distance) {
    distance = 100.0f;
  }

  mCamera.SetDistance(*distance);
  const om::coords::Global coord = vgs_.View2dState().GetScaledSliceDepth();
  mCamera.SetFocus(coord);

  updateGL();
}

/////////////////////////////////
///////          Gl Actions

/*
 *  Returns a vector names of closest picked result for given draw options.
 *
 * causes localized redraw (but all depth info stored in selection buffer)
 *
 */
bool OmView3d::pickPoint(const Vector2i& point2di,
                         std::vector<uint32_t>& rNamesVec) {
  // clear name vector
  rNamesVec.clear();

  // setup selection mode
  om::gl::old::startPicking(point2di.x, point2di.y,
                            mCamera.GetPerspective().array);

  // render selectable points
  Draw(DRAWOP_LEVEL_ALL | DRAWOP_SEGMENT_FILTER_SELECTED |
       DRAWOP_RENDERMODE_SELECTION);
  Draw(DRAWOP_LEVEL_ALL | DRAWOP_SEGMENT_FILTER_UNSELECTED |
       DRAWOP_RENDERMODE_SELECTION);

  // get number of hits
  int hits = om::gl::old::stopPicking();

  // if hits < 0, then buffer overflow
  if (hits < 0) {
    log_infos << "OmView3d::PickPoint: hit buffer overflow: " << hits;
    return false;
  }

  // if no hits, success
  if (hits == 0) {
    return true;
  }

  // number of names in closest hit
  int numNames;

  // pointer to closest hit names
  int* pNames;
  om::gl::old::processHits(hits, &pNames, &numNames);

  // add names from array to names vec
  for (int i = 0; i < numNames; i++) {
    rNamesVec.push_back(pNames[i]);
  }

  // success
  return true;
}

SegmentDataWrapper OmView3d::PickPoint(const Vector2i& point2di) {
  std::vector<uint32_t> result;
  const bool valid_pick = pickPoint(point2di, result);

  // if valid and return count
  if (!valid_pick || (result.size() != 3)) {
    return SegmentDataWrapper();
  }

  // ensure valid om::common::SegIDSet
  const om::common::ID segmentationID = result[0];
  const om::common::SegID segmentID = result[1];
  SegmentDataWrapper sdw(segmentationID, segmentID);

  if (!sdw.IsSegmentValid()) {
    return SegmentDataWrapper();
  }

  return sdw;
}

/*
 *  Unproject a 2d point to a 3d point using the depth buffer.
 *  Returns if unproject is valid (not valid if no depth value at pixel).
 */

bool OmView3d::UnprojectPoint(Vector2i point2di, Vector3f& point3d) {
  // apply camera modelview matrix
  mCamera.ApplyModelview();

  // unproject point2di
  double point3dv[3];
  if (om::gl::old::unprojectPixel(point2di.x, point2di.y, point3dv) < 0)
    return false;

  // return point3d
  point3d = Vector3f(point3dv[0], point3dv[1], point3dv[2]);
  return true;
}

/////////////////////////////////
///////          Widget Methods

void OmView3d::UpdateEnabledWidgets() {
  // set widgets enabled
  bool highlight_widget_state =
      OmPreferences::GetBoolean(om::PREF_VIEW3D_HIGHLIGHT_ENABLED_BOOL);
  widgets_[om::v3d::old::selection].enabled = highlight_widget_state;

  bool viewbox_widget_state =
      OmPreferences::GetBoolean(om::PREF_VIEW3D_SHOW_VIEWBOX_BOOL);
  widgets_[om::v3d::old::viewbox].enabled = viewbox_widget_state;

  bool info_widget_state =
      OmPreferences::GetBoolean(om::PREF_VIEW3D_SHOW_INFO_BOOL);
  widgets_[om::v3d::old::info].enabled = info_widget_state;

  bool extent_widget =
      OmPreferences::GetBoolean(om::PREF_VIEW3D_SHOW_CHUNK_EXTENT_BOOL);
  widgets_[om::v3d::old::chunk_extent].enabled = extent_widget;

  widgets_[om::v3d::old::perc_done].enabled = true;
  widgets_[om::v3d::old::annotations].enabled = true;
}

/////////////////////////////////
///////          Draw Methods

/*
 *  Root of drawing tree.
 *  Called from myUpdate() and picking calls.
 */
void OmView3d::Draw(OmBitfield cullerOptions) {
  mElapsed->restart();
  // clear buffer
  glClearStencil(0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

  // save the init modelview
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix();

  // apply camera modelview matrix
  mCamera.ApplyModelview();

  percVolDone_.clear();

  // if drawing volumes
  if (cullerOptions & DRAWOP_LEVEL_VOLUME) {
    // if in rendering mode
    if (cullerOptions & DRAWOP_RENDERMODE_RENDER) {
      // draw selected and write to stencil (for use with highlighting outline)
      glEnable(GL_STENCIL_TEST);
      glStencilFunc(GL_ALWAYS, 1, 0xFFFF);
      glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);
      DrawVolumes(cullerOptions | DRAWOP_SEGMENT_FILTER_SELECTED);
      glDisable(GL_STENCIL_TEST);

      // draw unselected (i.e. enabled) segments
      // if transparent unselected, disable writing to depth buffer
      if (OmPreferences::GetBoolean(
              om::PREF_VIEW3D_TRANSPARENT_UNSELECTED_BOOL)) {
        glDepthMask(GL_FALSE);
      }

      DrawVolumes(cullerOptions | DRAWOP_SEGMENT_FILTER_UNSELECTED |
                  DRAWOP_SEGMENT_COLOR_TRANSPARENT);

      // always renable writing to depth buffer
      glDepthMask(GL_TRUE);
    }

    // if in selection mode
    if (cullerOptions & DRAWOP_RENDERMODE_SELECTION) {
      DrawVolumes(cullerOptions);
    }
  }

  if (cullerOptions & DRAWOP_DRAW_WIDGETS) {
    DrawWidgets();
  }

  // pop to init modelview
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix();
}

/*
 *  Draw VolumeManager to using this View3d's camera.
 */
void OmView3d::DrawVolumes(OmBitfield cullerOptions) {
  // draw focus axis
  mCamera.DrawFocusAxis();

  const OmSegmentation* seg = vgs_.Segmentation().GetSegmentation();
  // setup culler to current projection-modelview matrix
  OmVolumeCuller culler(mCamera.GetProjModelViewMatrix(),
                        om::coords::Norm(mCamera.GetPosition(), seg->Coords()),
                        om::coords::Norm(mCamera.GetFocus(), seg->Coords()));

  meshesFound_ = false;

  // Draw meshes!
  FOR_EACH(iter, segmentations_) {
    OmSegmentation* vol = *iter;

    if (!vol->IsBuilt()) {
      continue;
    }

    if (vol->MeshManager(1)->Metadata()->IsBuilt()) {
      meshesFound_ = true;
    } else {
      continue;
    }

    std::shared_ptr<OmVolumeCuller> newCuller = culler.GetTransformedCuller(
        vol->Coords().NormToGlobalMat(), vol->Coords().GlobalToNormMat());

    OmMeshDrawer& meshDrawer = vol->MeshDrawer();

    boost::optional<std::pair<float, float> > percVolDone =
        meshDrawer.Draw(vgs_, newCuller, cullerOptions);

    if (percVolDone) {
      percVolDone_.push_back(*percVolDone);
    }
  }
}

/////////////////////////////////
///////          Draw Settings

void OmView3d::SetBackgroundColor() {
  Vector3f bg_color =
      OmPreferences::GetVector3f(om::PREF_VIEW3D_BACKGROUND_COLOR_V3F);
  glClearColor(bg_color.r, bg_color.g, bg_color.b, 1);
}

void OmView3d::SetCameraPerspective() {
  float mynear = OmPreferences::GetFloat(om::PREF_VIEW3D_CAMERA_NEAR_PLANE_FLT);
  float myfar = OmPreferences::GetFloat(om::PREF_VIEW3D_CAMERA_FAR_PLANE_FLT);
  float fov = OmPreferences::GetFloat(om::PREF_VIEW3D_CAMERA_FOV_FLT);
  myfar = 10000000.0;
  Vector4<float> perspective(fov, (float)(400) / 300, mynear, myfar);

  mCamera.SetPerspective(perspective);
  mCamera.ResetModelview();
}

void OmView3d::SetBlending() {
  if (OmPreferences::GetBoolean(om::PREF_VIEW3D_TRANSPARENT_UNSELECTED_BOOL)) {
    glEnable(GL_BLEND);
  } else {
    glDisable(GL_BLEND);
  }
}

/*
 *  Draw all enabled widgets.
 */
void OmView3d::DrawWidgets() {
  FOR_EACH(iter, widgets_) {
    if (iter->enabled) {
      iter->Draw();
    }
  }
}

/////////////////////////////////
///////
///////         Utility Functions
///////

/*
 * Initialize lights
 * http://www.songho.ca/opengl/gl_vbo.html
 */
void OmView3d::initLights() {
  // set up light colors (ambient, diffuse, specular)
  GLfloat lightKa[] = {.2f, .2f, .2f, 1.0f};  // ambient light
  GLfloat lightKd[] = {.7f, .7f, .7f, 1.0f};  // diffuse light
  GLfloat lightKs[] = {1, 1, 1, 1};           // specular light
  glLightfv(GL_LIGHT0, GL_AMBIENT, lightKa);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, lightKd);
  glLightfv(GL_LIGHT0, GL_SPECULAR, lightKs);

  float specReflection[] = {0.8f, 0.8f, 0.8f, 1.0f};
  glMaterialfv(GL_FRONT, GL_SPECULAR, specReflection);

  glMateriali(GL_FRONT, GL_SHININESS, 96);

  // position the light
  float lightPos[4] = {0, 0, 1000, 1};  // positional light
  glLightfv(GL_LIGHT0, GL_POSITION, lightPos);

  glEnable(GL_LIGHT0);  // enable light source after configuration
}

QSize OmView3d::sizeHint() const {
  const QSize s = OmAppState::GetViewBoxSizeHint();

  // TODO: offset is only 76 if tabs are present in the upper-right dock
  // widget...
  const int offset = 76;

  return QSize(s.width(), s.height() - offset);
}

bool OmView3d::event(QEvent* e) {
  if (e->type() == QEvent::Gesture) {
    return mView3dUi.GestureEvent(static_cast<QGestureEvent*>(e));
  }

  return QGLWidget::event(e);
}

void OmView3d::DoZoom(const int direction) {
  const float dist = mCamera.GetDistance();
  mCamera.SetDistance(dist - (.3 * dist * direction));
  updateGL();
}
