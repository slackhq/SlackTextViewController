//
//  SCKTextView.h
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextView+ChatKitAdditions.h"

extern NSString * const SCKTextViewTextWillChangeNotification;
extern NSString * const SCKTextViewSelectionDidChangeNotification;
extern NSString * const SCKTextViewContentSizeDidChangeNotification;
extern NSString * const SCKTextViewDidPasteImageNotification;
extern NSString * const SCKTextViewDidShakeNotification;

///------------------------------------------------
/// @name A custom text input view.
///------------------------------------------------
@interface SCKTextView : UITextView

/** The placeholder text string. */
@property (nonatomic, strong) NSString *placeholder;
/** The placeholder color. */
@property (nonatomic, strong) UIColor *placeholderColor;
/** The maximum number of lines before enabling scrolling. Default is 0 wich means limitless. */
@property (nonatomic, readwrite) NSUInteger maxNumberOfLines;
/** YES if the text view is and can still expand it self, depending if the maximum number of lines are reached. */
@property (nonatomic, readonly, getter = isExpanding) BOOL expanding;

@end
