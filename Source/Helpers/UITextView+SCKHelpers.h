//
//  UITextView+SCKHelpers.h
//  Slack
//
//  Created by Ignacio on 8/19/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (SCKHelpers)

/** YES if the cursor is positionned at the very end. */
@property (nonatomic, readonly) BOOL isCursorAtEnd;

/**
 Scrolls animated to the very end of the content size.
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
 Finds the word close to the cursor's position, if any.
 
 @param range Returns the range of the found word.
 @returns The found word.
 */
- (NSString *)getWordAtCursor:(NSRangePointer)range;

/**
 Disables iOS8's Quick Type bar.
 @param disable YES if the bar should be disabled.
 */
- (void)disableQuickTypeBar:(BOOL)disable;

@end
