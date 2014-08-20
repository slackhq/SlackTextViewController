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
/** The current number of lines displayed. */
@property (nonatomic, readonly) NSUInteger numberOfLines;
/** The maximum number of lines before enabling scrolling. Default is 0 wich means limitless. */
@property (nonatomic, readwrite) NSUInteger maxNumberOfLines;

/**
 Adds a string at the cursor's position.
 
 @param text The string to be appended to the current text.
 */
- (void)insertTextAtCursor:(NSString *)text;

/**
 Adds a string to a specific range.
 
 @param text The string to be appended to the current text.
 @param range The range where to insert text.
 
 @return The range of the newly inserted text.
 */
- (NSRange)insertText:(NSString *)text inRange:(NSRange)range;

@end
