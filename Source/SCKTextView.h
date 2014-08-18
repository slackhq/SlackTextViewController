//
//  SCKTextView.h
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const SCKTextViewContentSizeDidChangeNotification;

/** A custom text view with placeholder text. */
@interface SCKTextView : UITextView

/** The placeholder text string. */
@property (nonatomic, strong) NSString *placeholder;
/** The placeholder color. */
@property (nonatomic, strong) UIColor *placeholderColor;

@property (nonatomic, readonly) NSUInteger numberOfLines;

@end
