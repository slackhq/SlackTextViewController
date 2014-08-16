//
//  SLKTextContainerView.h
//  ChatRoom
//
//  Created by Ignacio Romero Z. on 8/16/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTextView.h"

extern NSString * const SLKInputAccessoryViewKeyboardFrameDidChangeNotification;

@interface SLKTextContainerView : UIToolbar

@property (nonatomic, strong) SLKTextView *textView;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@property (nonatomic, copy) UIImage *leftButtonImage;

@end
