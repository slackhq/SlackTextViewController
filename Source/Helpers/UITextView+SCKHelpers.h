//
//  UITextView+SCKHelpers.h
//  Slack
//
//  Created by Ignacio on 8/19/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (SCKHelpers)

/**
 
 */
- (void)scrollRangeToBottom;

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

/**
 
 */
- (BOOL)isCursorAtEnd;

/**
 
 */
- (NSString *)closerWord:(NSRangePointer)range;

/**
 
 */
- (void)disableQuickTypeBar:(BOOL)disable;

@end
