// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_COMPOSITING_SCENE_H_
#define FLUTTER_LIB_UI_COMPOSITING_SCENE_H_

#include <cstdint>
#include <memory>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace flutter {

class Scene : public RefCountedDartWrappable<Scene> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Scene);

 public:
  ~Scene() override;
  static void create(Dart_Handle scene_handle,
                     std::shared_ptr<flutter::Layer> rootLayer,
                     uint32_t rasterizerTracingThreshold,
                     bool checkerboardRasterCacheImages,
                     bool checkerboardOffscreenLayers);

  std::shared_ptr<flutter::LayerTree> takeLayerTree();

  Dart_Handle toImageSync(uint32_t width,
                          uint32_t height,
                          Dart_Handle raw_image_handle);

  Dart_Handle toImage(uint32_t width,
                      uint32_t height,
                      Dart_Handle raw_image_handle);

  void dispose();

 private:
  Scene(std::shared_ptr<flutter::Layer> rootLayer,
        uint32_t rasterizerTracingThreshold,
        bool checkerboardRasterCacheImages,
        bool checkerboardOffscreenLayers);

  void RasterizeToImage(uint32_t width,
                        uint32_t height,
                        Dart_Handle raw_image_handle);

  // This is a shared_ptr to support flattening the layer tree from the UI
  // thread onto the raster thread - allowing access to the texture registry
  // required to render TextureLayers.
  //
  // No longer valid after calling `takeLayerTree`.
  std::shared_ptr<flutter::LayerTree> layer_tree_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_COMPOSITING_SCENE_H_
