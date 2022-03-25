// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_surface.h"

#import "flutter/shell/platform/darwin/ios/ios_surface_gl.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_software.h"

#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#if SHELL_ENABLE_METAL
#import "flutter/shell/platform/darwin/ios/ios_surface_metal.h"
#endif  // SHELL_ENABLE_METAL

namespace flutter {

std::unique_ptr<IOSSurface> IOSSurface::Create(std::shared_ptr<IOSContext> context,
                                               fml::scoped_nsobject<CALayer> layer) {
  FML_DCHECK(layer);
  FML_DCHECK(context);

#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
// EAGLContext first deprecated in tvOS 12.0 --> ignore for now, this will at one point also need be fixed for iOS-12

  if ([layer.get() isKindOfClass:[CAEAGLLayer class]]) {
    return std::make_unique<IOSSurfaceGL>(
        fml::scoped_nsobject<CAEAGLLayer>(
            reinterpret_cast<CAEAGLLayer*>([layer.get() retain])),  // EAGL layer
        std::move(context)                                          // context
    );
  }
#endif

#if SHELL_ENABLE_METAL
  if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunguarded-availability-new"
    if ([layer.get() isKindOfClass:[CAMetalLayer class]]) {
      return std::make_unique<IOSSurfaceMetal>(
          fml::scoped_nsobject<CAMetalLayer>(
              reinterpret_cast<CAMetalLayer*>([layer.get() retain])),  // Metal layer
          std::move(context)                                           // context
      );
    }
  }
#pragma GCC diagnostic pop
#endif  // SHELL_ENABLE_METAL

  return std::make_unique<IOSSurfaceSoftware>(std::move(layer),   // layer
                                              std::move(context)  // context
  );
}

IOSSurface::IOSSurface(std::shared_ptr<IOSContext> ios_context)
    : ios_context_(std::move(ios_context)) {
  FML_DCHECK(ios_context_);
}

IOSSurface::~IOSSurface() = default;

std::shared_ptr<IOSContext> IOSSurface::GetContext() const {
  return ios_context_;
}

}  // namespace flutter
