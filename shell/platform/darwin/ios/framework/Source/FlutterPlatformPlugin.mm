// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"

#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIKit.h>

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"

namespace {

#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
constexpr char kTextPlainFormat[] = "text/plain";
#endif
const UInt32 kKeyPressClickSoundId = 1306;

}  // namespace

namespace flutter {

// TODO(abarth): Move these definitions from system_chrome_impl.cc to here.
const char* const kOrientationUpdateNotificationName =
    "io.flutter.plugin.platform.SystemChromeOrientationNotificationName";
const char* const kOrientationUpdateNotificationKey =
    "io.flutter.plugin.platform.SystemChromeOrientationNotificationKey";
const char* const kOverlayStyleUpdateNotificationName =
    "io.flutter.plugin.platform.SystemChromeOverlayNotificationName";
const char* const kOverlayStyleUpdateNotificationKey =
    "io.flutter.plugin.platform.SystemChromeOverlayNotificationKey";

}  // namespace flutter

using namespace flutter;

@implementation FlutterPlatformPlugin {
  fml::WeakPtr<FlutterEngine> _engine;
  // Used to detect whether this device has live text input ability or not.
  UITextField* _textField;
}

- (instancetype)initWithEngine:(fml::WeakPtr<FlutterEngine>)engine {
  FML_DCHECK(engine) << "engine must be set";
  self = [super init];

  if (self) {
    _engine = engine;
  }

  return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* method = call.method;
  id args = call.arguments;
  if ([method isEqualToString:@"SystemSound.play"]) {
    [self playSystemSound:args];
    result(nil);
  } else if ([method isEqualToString:@"HapticFeedback.vibrate"]) {
    [self vibrateHapticFeedback:args];
    result(nil);
  } else if ([method isEqualToString:@"SystemChrome.setPreferredOrientations"]) {
    [self setSystemChromePreferredOrientations:args];
    result(nil);
  } else if ([method isEqualToString:@"SystemChrome.setApplicationSwitcherDescription"]) {
    [self setSystemChromeApplicationSwitcherDescription:args];
    result(nil);
  } else if ([method isEqualToString:@"SystemChrome.setEnabledSystemUIOverlays"]) {
    [self setSystemChromeEnabledSystemUIOverlays:args];
    result(nil);
  } else if ([method isEqualToString:@"SystemChrome.setEnabledSystemUIMode"]) {
    [self setSystemChromeEnabledSystemUIMode:args];
    result(nil);
  } else if ([method isEqualToString:@"SystemChrome.restoreSystemUIOverlays"]) {
    [self restoreSystemChromeSystemUIOverlays];
    result(nil);
  } else if ([method isEqualToString:@"SystemChrome.setSystemUIOverlayStyle"]) {
    [self setSystemChromeSystemUIOverlayStyle:args];
    result(nil);
  } else if ([method isEqualToString:@"SystemNavigator.pop"]) {
    NSNumber* isAnimated = args;
    [self popSystemNavigator:isAnimated.boolValue];
    result(nil);
  } else if ([method isEqualToString:@"Clipboard.getData"]) {
    result([self getClipboardData:args]);
  } else if ([method isEqualToString:@"Clipboard.setData"]) {
    [self setClipboardData:args];
    result(nil);
  } else if ([method isEqualToString:@"Clipboard.hasStrings"]) {
    result([self clipboardHasStrings]);
  } else if ([method isEqualToString:@"LiveText.isLiveTextInputAvailable"]) {
    result(@([self isLiveTextInputAvailable]));
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)playSystemSound:(NSString*)soundType {
  if ([soundType isEqualToString:@"SystemSoundType.click"]) {
    // All feedback types are specific to Android and are treated as equal on
    // iOS.
    AudioServicesPlaySystemSound(kKeyPressClickSoundId);
  }
}

- (void)vibrateHapticFeedback:(NSString*)feedbackType {
  if (!feedbackType) {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    return;
  }

#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
  if (@available(iOS 10, *)) {
    if ([@"HapticFeedbackType.lightImpact" isEqualToString:feedbackType]) {
      [[[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] autorelease]
          impactOccurred];
    } else if ([@"HapticFeedbackType.mediumImpact" isEqualToString:feedbackType]) {
      [[[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] autorelease]
          impactOccurred];
    } else if ([@"HapticFeedbackType.heavyImpact" isEqualToString:feedbackType]) {
      [[[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] autorelease]
          impactOccurred];
    } else if ([@"HapticFeedbackType.selectionClick" isEqualToString:feedbackType]) {
      [[[[UISelectionFeedbackGenerator alloc] init] autorelease] selectionChanged];
    }
  }
#endif
}

- (void)setSystemChromePreferredOrientations:(NSArray*)orientations {
  UIInterfaceOrientationMask mask = 0;

#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
  if (orientations.count == 0) {
    mask |= UIInterfaceOrientationMaskAll;
  } else {
    for (NSString* orientation in orientations) {
      if ([orientation isEqualToString:@"DeviceOrientation.portraitUp"]) {
        mask |= UIInterfaceOrientationMaskPortrait;
      } else if ([orientation isEqualToString:@"DeviceOrientation.portraitDown"]) {
        mask |= UIInterfaceOrientationMaskPortraitUpsideDown;
      } else if ([orientation isEqualToString:@"DeviceOrientation.landscapeLeft"]) {
        mask |= UIInterfaceOrientationMaskLandscapeLeft;
      } else if ([orientation isEqualToString:@"DeviceOrientation.landscapeRight"]) {
        mask |= UIInterfaceOrientationMaskLandscapeRight;
      }
    }
  }
#endif

  if (!mask) {
    return;
  }
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@(kOrientationUpdateNotificationName)
                    object:nil
                  userInfo:@{@(kOrientationUpdateNotificationKey) : @(mask)}];
}

- (void)setSystemChromeApplicationSwitcherDescription:(NSDictionary*)object {
  // No counterpart on iOS but is a benign operation. So no asserts.
}

- (void)setSystemChromeEnabledSystemUIOverlays:(NSArray*)overlays {
  // Checks if the top status bar should be visible. This platform ignores all
  // other overlays

  // We opt out of view controller based status bar visibility since we want
  // to be able to modify this on the fly. The key used is
  // UIViewControllerBasedStatusBarAppearance
#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
  [UIApplication sharedApplication].statusBarHidden =
      ![overlays containsObject:@"SystemUiOverlay.top"];
  if ([overlays containsObject:@"SystemUiOverlay.bottom"]) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:FlutterViewControllerShowHomeIndicator
                      object:nil];
  } else {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:FlutterViewControllerHideHomeIndicator
                      object:nil];
  }
#endif
}

- (void)setSystemChromeEnabledSystemUIMode:(NSString*)mode {
  // Checks if the top status bar should be visible, reflected by edge to edge setting. This
  // platform ignores all other system ui modes.

  // We opt out of view controller based status bar visibility since we want
  // to be able to modify this on the fly. The key used is
  // UIViewControllerBasedStatusBarAppearance
  [UIApplication sharedApplication].statusBarHidden =
      ![mode isEqualToString:@"SystemUiMode.edgeToEdge"];
  if ([mode isEqualToString:@"SystemUiMode.edgeToEdge"]) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:FlutterViewControllerShowHomeIndicator
                      object:nil];
  } else {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:FlutterViewControllerHideHomeIndicator
                      object:nil];
  }
}

- (void)restoreSystemChromeSystemUIOverlays {
  // Nothing to do on iOS.
}

- (void)setSystemChromeSystemUIOverlayStyle:(NSDictionary*)message {
  NSString* brightness = message[@"statusBarBrightness"];
  if (brightness == (id)[NSNull null]) {
    return;
  }

#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
  UIStatusBarStyle statusBarStyle;
  if ([brightness isEqualToString:@"Brightness.dark"]) {
    statusBarStyle = UIStatusBarStyleLightContent;
  } else if ([brightness isEqualToString:@"Brightness.light"]) {
    if (@available(iOS 13, *)) {
      statusBarStyle = UIStatusBarStyleDarkContent;
    } else {
      statusBarStyle = UIStatusBarStyleDefault;
    }
  } else {
    return;
  }

  NSNumber* infoValue = [[NSBundle mainBundle]
      objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
  Boolean delegateToViewController = (infoValue == nil || [infoValue boolValue]);

  if (delegateToViewController) {
    // This notification is respected by the iOS embedder
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@(kOverlayStyleUpdateNotificationName)
                      object:nil
                    userInfo:@{@(kOverlayStyleUpdateNotificationKey) : @(statusBarStyle)}];
  } else {
    // Note: -[UIApplication setStatusBarStyle] is deprecated in iOS9
    // in favor of delegating to the view controller
    [[UIApplication sharedApplication] setStatusBarStyle:statusBarStyle];
  }
#endif  
}

- (void)popSystemNavigator:(BOOL)isAnimated {
  // Apple's human user guidelines say not to terminate iOS applications. However, if the
  // root view of the app is a navigation controller, it is instructed to back up a level
  // in the navigation hierarchy.
  // It's also possible in an Add2App scenario that the FlutterViewController was presented
  // outside the context of a UINavigationController, and still wants to be popped.

  UIViewController* engineViewController = [_engine.get() viewController];
  UINavigationController* navigationController = [engineViewController navigationController];
  if (navigationController) {
    [navigationController popViewControllerAnimated:isAnimated];
  } else {
    UIViewController* rootViewController =
        [UIApplication sharedApplication].keyWindow.rootViewController;
    if (engineViewController != rootViewController) {
      [engineViewController dismissViewControllerAnimated:isAnimated completion:nil];
    }
  }
}

- (NSDictionary*)getClipboardData:(NSString*)format {
#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
  UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
  if (!format || [format isEqualToString:@(kTextPlainFormat)]) {
    NSString* stringInPasteboard = pasteboard.string;
    // The pasteboard may contain an item but it may not be a string (an image for instance).
    return stringInPasteboard == nil ? nil : @{@"text" : stringInPasteboard};
  }
#endif
  return nil;
}

- (void)setClipboardData:(NSDictionary*)data {
#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
  UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
  id copyText = data[@"text"];
  if ([copyText isKindOfClass:[NSString class]]) {
    pasteboard.string = copyText;
  } else {
    pasteboard.string = @"null";
  }
#endif
}

- (NSDictionary*)clipboardHasStrings {
   bool hasStrings = false;
#if !(defined(TARGET_OS_TV) && TARGET_OS_TV)
  UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
  if (@available(iOS 10, *)) {
    hasStrings = pasteboard.hasStrings;
  } else {
    NSString* stringInPasteboard = pasteboard.string;
    hasStrings = stringInPasteboard != nil;
  }
#endif
  return @{@"value" : @(hasStrings)};
}

- (BOOL)isLiveTextInputAvailable {
  return [[self textField] canPerformAction:@selector(captureTextFromCamera:) withSender:nil];
}

- (UITextField*)textField {
  if (_textField == nil) {
    _textField = [[UITextField alloc] init];
  }
  return _textField;
}

- (void)dealloc {
  [_textField release];
  [super dealloc];
}
@end
