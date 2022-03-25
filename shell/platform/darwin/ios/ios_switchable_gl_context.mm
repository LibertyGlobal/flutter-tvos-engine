// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_switchable_gl_context.h"

#import <OpenGLES/EAGL.h>

namespace flutter {

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
// EAGLContext first deprecated in tvOS 12.0 --> ignore for now, this will at one point also need be fixed for iOS-12

IOSSwitchableGLContext::IOSSwitchableGLContext(EAGLContext* context) : context_(context){};

bool IOSSwitchableGLContext::SetCurrent() {
  FML_DCHECK_CREATION_THREAD_IS_CURRENT(checker);
  FML_DCHECK(context_ != nullptr);
  EAGLContext* current_context = EAGLContext.currentContext;
  previous_context_ = current_context;
  return [EAGLContext setCurrentContext:context_];
};

bool IOSSwitchableGLContext::RemoveCurrent() {
  FML_DCHECK_CREATION_THREAD_IS_CURRENT(checker);
  return [EAGLContext setCurrentContext:previous_context_];
};

#pragma GCC diagnostic pop
}
