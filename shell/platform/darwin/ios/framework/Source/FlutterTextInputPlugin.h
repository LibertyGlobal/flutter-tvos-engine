// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERTEXTINPUTPLUGIN_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERTEXTINPUTPLUGIN_H_

#import <UIKit/UIKit.h>

#import "flutter/shell/platform/common/text_editing_delta.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterIndirectScribbleDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterKeySecondaryResponder.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewResponder.h"

typedef NS_ENUM(NSInteger, FlutterScribbleFocusStatus) {
  FlutterScribbleFocusStatusUnfocused,
  FlutterScribbleFocusStatusFocusing,
  FlutterScribbleFocusStatusFocused,
};

typedef NS_ENUM(NSInteger, FlutterScribbleInteractionStatus) {
  FlutterScribbleInteractionStatusNone,
  FlutterScribbleInteractionStatusStarted,
  FlutterScribbleInteractionStatusEnding,
};

#ifdef TARGET_OS_TV
@interface FlutterTextInputPlugin
    : NSObject <FlutterKeySecondaryResponder>
#else
@interface FlutterTextInputPlugin
    : NSObject <FlutterKeySecondaryResponder, UIIndirectScribbleInteractionDelegate>
#endif


@property(nonatomic, weak) UIViewController* viewController;
@property(nonatomic, weak) id<FlutterIndirectScribbleDelegate> indirectScribbleDelegate;
@property(nonatomic, strong)
    NSMutableDictionary<UIScribbleElementIdentifier, NSValue*>* scribbleElements;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<FlutterTextInputDelegate>)textInputDelegate
    NS_DESIGNATED_INITIALIZER;

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

/**
 * The `UITextInput` implementation used to control text entry.
 *
 * This is used by `AccessibilityBridge` to forward interactions with iOS'
 * accessibility system.
 */
- (UIView<UITextInput>*)textInputView;

/**
 * These are used by the UIIndirectScribbleInteractionDelegate methods to handle focusing on the
 * correct element.
 */
- (void)setupIndirectScribbleInteraction:(id<FlutterViewResponder>)viewResponder;
- (void)resetViewResponder;

@end

/** An indexed position in the buffer of a Flutter text editing widget. */
@interface FlutterTextPosition : UITextPosition

@property(nonatomic, readonly) NSUInteger index;

+ (instancetype)positionWithIndex:(NSUInteger)index;
- (instancetype)initWithIndex:(NSUInteger)index;

@end

/** A range of text in the buffer of a Flutter text editing widget. */
@interface FlutterTextRange : UITextRange <NSCopying>

@property(nonatomic, readonly) NSRange range;

+ (instancetype)rangeWithNSRange:(NSRange)range;

@end

/** A tokenizer used by `FlutterTextInputView` to customize string parsing. */
@interface FlutterTokenizer : UITextInputStringTokenizer
@end

@interface FlutterTextSelectionRect : UITextSelectionRect

@property(nonatomic, assign) CGRect rect;
@property(nonatomic) NSUInteger position;
@property(nonatomic, assign) NSWritingDirection writingDirection;
@property(nonatomic) BOOL containsStart;
@property(nonatomic) BOOL containsEnd;
@property(nonatomic) BOOL isVertical;

+ (instancetype)selectionRectWithRectAndInfo:(CGRect)rect
                                    position:(NSUInteger)position
                            writingDirection:(NSWritingDirection)writingDirection
                               containsStart:(BOOL)containsStart
                                 containsEnd:(BOOL)containsEnd
                                  isVertical:(BOOL)isVertical;

+ (instancetype)selectionRectWithRect:(CGRect)rect position:(NSUInteger)position;

- (instancetype)initWithRectAndInfo:(CGRect)rect
                           position:(NSUInteger)position
                   writingDirection:(NSWritingDirection)writingDirection
                      containsStart:(BOOL)containsStart
                        containsEnd:(BOOL)containsEnd
                         isVertical:(BOOL)isVertical;

- (instancetype)init NS_UNAVAILABLE;
@end

API_AVAILABLE(ios(13.0)) @interface FlutterTextPlaceholder : UITextPlaceholder
@end

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
FLUTTER_DARWIN_EXPORT
#endif
#ifdef TARGET_OS_TV
@interface FlutterTextInputView : UIView <UITextInput>
#else
@interface FlutterTextInputView : UIView <UITextInput, UIScribbleInteractionDelegate>
#endif

// UITextInput
@property(nonatomic, readonly) NSMutableString* text;
@property(nonatomic, readonly) NSMutableString* markedText;
@property(readwrite, copy) UITextRange* selectedTextRange;
@property(nonatomic, strong) UITextRange* markedTextRange;
@property(nonatomic, copy) NSDictionary* markedTextStyle;
@property(nonatomic, weak) id<UITextInputDelegate> inputDelegate;

// UITextInputTraits
@property(nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property(nonatomic) UITextAutocorrectionType autocorrectionType;
@property(nonatomic) UITextSpellCheckingType spellCheckingType;
@property(nonatomic) BOOL enablesReturnKeyAutomatically;
@property(nonatomic) UIKeyboardAppearance keyboardAppearance;
@property(nonatomic) UIKeyboardType keyboardType;
@property(nonatomic) UIReturnKeyType returnKeyType;
@property(nonatomic, getter=isSecureTextEntry) BOOL secureTextEntry;
@property(nonatomic, getter=isEnableDeltaModel) BOOL enableDeltaModel;
@property(nonatomic) UITextSmartQuotesType smartQuotesType API_AVAILABLE(ios(11.0));
@property(nonatomic) UITextSmartDashesType smartDashesType API_AVAILABLE(ios(11.0));
@property(nonatomic, copy) UITextContentType textContentType API_AVAILABLE(ios(10.0));

@property(nonatomic, weak) UIAccessibilityElement* backingTextInputAccessibilityObject;

// Scribble Support
@property(nonatomic, weak) id<FlutterViewResponder> viewResponder;
@property(nonatomic) FlutterScribbleFocusStatus scribbleFocusStatus;
@property(nonatomic, strong) NSArray<FlutterTextSelectionRect*>* selectionRects;
- (void)resetScribbleInteractionStatusIfEnding;
- (BOOL)isScribbleAvailable;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder*)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithOwner:(FlutterTextInputPlugin*)textInputPlugin NS_DESIGNATED_INITIALIZER;

@end
#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERTEXTINPUTPLUGIN_H_
