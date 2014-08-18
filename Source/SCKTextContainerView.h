//
//  SCKTextContainerView.h
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/16/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCKTextView.h"

#define kTextViewVerticalPadding 5
#define kTextViewHorizontalPadding 8

extern NSString * const SCKInputAccessoryViewKeyboardFrameDidChangeNotification;

@interface SCKTextContainerView : UIToolbar

/** The centered text view. */
@property (nonatomic, strong) SCKTextView *textView;
/** The left action button action. */
@property (nonatomic, strong) UIButton *leftButton;
/** The right action button action. */
@property (nonatomic, strong) UIButton *rightButton;

@end
