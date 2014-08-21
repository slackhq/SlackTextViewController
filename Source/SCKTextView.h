//
//  SCKTextView.h
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextView+SCKHelpers.h"

extern NSString * const SCKTextViewTextWillChangeNotification;
extern NSString * const SCKTextViewSelectionDidChangeNotification;
extern NSString * const SCKTextViewContentSizeDidChangeNotification;

/** A custom text view with placeholder text. */
@interface SCKTextView : UITextView

/** The placeholder text string. */
@property (nonatomic, strong) NSString *placeholder;
/** The placeholder color. */
@property (nonatomic, strong) UIColor *placeholderColor;
/** The current number of lines displayed. */
@property (nonatomic, readonly) NSUInteger numberOfLines;
/** The maximum number of lines before enabling scrolling. Default is 0 wich means limitless. */
@property (nonatomic, readwrite) NSUInteger maxNumberOfLines;

@end
