#pragma once
#include "precomp.h"

/*
 * OmTextureIDs are a wrapper for GLuint texture IDs.
 *
 * They associate a texture ID with the corresponding TileCoord,
 * and keep track of the size of the texture in memory.
 *
 * A TextureID is associated with a TextureIDCache that keeps track of how
 * much GL video memory is in use.
 *
 * Rachel Shearer - rshearer@mit.edu - 3/17/09
 */

#include "utility/glInclude.h"
#include "common/common.h"
#include "common/colors.h"

class QGLContext;

class OmTextureID {
 public:
  OmTextureID(const int tileDim, std::shared_ptr<uint8_t>);
  OmTextureID(const int tileDim, std::shared_ptr<om::common::ColorARGB>);

  virtual ~OmTextureID();

  int GetWidth() const { return tileDim_; }

  int GetHeight() const { return tileDim_; }

  GLuint GetTextureID() const {
    if (!textureID_) {
      throw om::IoException("texture not yet built");
    }
    return *textureID_;
  }

  void* GetTileData() const;

  uint8_t* GetTileDataUChar() const;

  bool NeedToBuildTexture() const { return (flag_ != OMTILE_GOOD); }

  QImage::Format GetQTimageFormat() const {
    switch (flag_) {
      case OMTILE_NEEDCOLORMAP:
        return QImage::Format_ARGB32_Premultiplied;
      case OMTILE_NEEDTEXTUREBUILT:
        return QImage::Format_Indexed8;
      default:
        throw om::ArgException("unknown flag");
    }
  }

  GLint GetGLinternalFormat() const {
    switch (flag_) {
      case OMTILE_NEEDCOLORMAP:
        return GL_RGBA8;
      case OMTILE_NEEDTEXTUREBUILT:
        return GL_LUMINANCE;
      default:
        throw om::ArgException("unknown flag");
    }
  }

  GLenum GetGLdataFormat() const {
    switch (flag_) {
      case OMTILE_NEEDCOLORMAP:
        return GL_BGRA;
      case OMTILE_NEEDTEXTUREBUILT:
        return GL_LUMINANCE;
      default:
        throw om::ArgException("unknown flag");
    }
  }

  GLenum GetPixelDataType() const {
    switch (flag_) {
      case OMTILE_NEEDCOLORMAP:
        return GL_UNSIGNED_INT_8_8_8_8;
      case OMTILE_NEEDTEXTUREBUILT:
        return GL_UNSIGNED_BYTE;
      default:
        throw om::ArgException("unknown flag");
    }
  }

  void TextureBindComplete(QGLContext const* context, const GLuint textureID);

  QGLContext const* Context() const { return context_; }

 private:
  const int tileDim_;

  bool is8bit_;
  std::shared_ptr<uint8_t> tile8_;
  std::shared_ptr<om::common::ColorARGB> tile32_;

  enum OmTileFlag {
    OMTILE_NEEDCOLORMAP,
    OMTILE_NEEDTEXTUREBUILT,
    OMTILE_GOOD
  };
  OmTileFlag flag_;

  boost::optional<GLuint> textureID_;

  QGLContext const* context_;
};
