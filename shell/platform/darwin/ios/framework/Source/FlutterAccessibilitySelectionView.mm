// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterAccessibilitySelectionView.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"


@interface FlutterAccessibilitySelectionView ()
@property(nonatomic) int32_t uid;
@end


@implementation FlutterAccessibilitySelectionView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.hidden = YES;  // default hidden, make visible on move
        self.backgroundColor = [UIColor clearColor]; // Make sure background is transparent
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"";
        self.accessibilityHint = @"";
        self.accessibilityTraits = UIAccessibilityTraitStaticText;
        self.uid = -1;
    }
    return self;
}

- (void)updateSemantics:(SemanticsObject*)object {
    if(object){
        // only update when different to avoid flashing of system selection rectangle
        if( (self.uid != object.uid) || !CGRectEqualToRect(self.accessibilityFrame, object.accessibilityFrame) ){
            self.hidden = NO;
            self.isAccessibilityElement = YES;
            self.userInteractionEnabled = YES;

            self.frame = object.accessibilityFrame;
            self.accessibilityFrame = object.accessibilityFrame;

            // copy SemanticsObject(UIAccessibilityElement) content to UIView
            self.accessibilityLabel = object.accessibilityLabel;
            self.accessibilityHint = object.accessibilityHint;
            self.accessibilityValue = object.accessibilityValue;
            self.accessibilityTraits = object.accessibilityTraits;
            self.accessibilityIdentifier = object.accessibilityIdentifier;
            self.uid = object.uid;

            [self setNeedsDisplay]; // Triggers redraw

            // Force the selection to be the top view so that it is always visible. Otherwise new semantic scroll views are added on top
            [self.superview bringSubviewToFront:self];

            // Force focus so that tvOS shows the focus rectangle
            [self setNeedsFocusUpdate];
            [self updateFocusIfNeeded];
        }
    }
    else {
        self.hidden = YES;
        self.isAccessibilityElement = NO;   // make sure that in "explorer mode" the focused rectangle is not visible
        self.userInteractionEnabled = NO;
        self.uid = -1;
        [self setNeedsDisplay]; // Triggers redraw
    }
}

- (BOOL)canBecomeFocused {
    return (self.hidden == NO);
}

@end
