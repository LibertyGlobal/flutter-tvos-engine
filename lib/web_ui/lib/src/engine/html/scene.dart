// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../vector_math.dart';
import '../window.dart';
import 'surface.dart';

class SurfaceScene implements ui.Scene {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a Scene object, use a [SceneBuilder].
  SurfaceScene(this.webOnlyRootElement);

  final DomElement? webOnlyRootElement;

  /// Creates a raster image representation of the current state of the scene.
  /// This is a slow operation that is performed on a background thread.
  @override
  Future<ui.Image> toImage(int width, int height) {
    throw UnsupportedError('toImage is not supported on the Web');
  }

  /// Releases the resources used by this scene.
  ///
  /// After calling this function, the scene is cannot be used further.
  @override
  void dispose() {}
}

/// A surface that creates a DOM element for whole app.
class PersistedScene extends PersistedContainerSurface {
  PersistedScene(PersistedScene? super.oldLayer) {
    transform = Matrix4.identity();
  }

  @override
  void recomputeTransformAndClip() {
    // The scene clip is the size of the entire window.
    final ui.Size screen = window.physicalSize;
    localClipBounds = ui.Rect.fromLTRB(0, 0, screen.width, screen.height);
    projectedClip = null;
  }

  /// Cached inverse of transform on this node. Unlike transform, this
  /// Matrix only contains local transform (not chain multiplied since root).
  Matrix4? _localTransformInverse;

  @override
  Matrix4? get localTransformInverse =>
      _localTransformInverse ??= Matrix4.identity();

  @override
  DomElement createElement() {
    return defaultCreateElement('flt-scene');
  }

  @override
  void apply() {}
}
