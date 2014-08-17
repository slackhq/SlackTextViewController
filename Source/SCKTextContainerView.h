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

@property (nonatomic, strong) SCKTextView *textView;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@property (nonatomic, copy) UIImage *leftButtonImage;

@end
