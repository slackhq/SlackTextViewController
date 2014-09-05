//
//  UITextView+ChatKitAdditions.h
//  Slack
//
//  Created by Ignacio Romero Zurbuchen on 8/19/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/** @name UITextView additional features used for Slack Chat Kit. */
@interface UITextView (ChatKitAdditions)

/** The current displayed number of lines. */
@property (nonatomic, readonly) NSUInteger numberOfLines;

/**
 Scrolls to the very end of the content size, animated.
 
 @param animated YES if the scrolling should be animated.
 */
- (void)scrollToBottomAnimated:(BOOL)animated;

/**
 Scrolls to the caret position, animated.
 
 @param animated YES if the scrolling should be animated.
 */
- (void)scrollToCaretPositonAnimated:(BOOL)animated;

/**
 Inserts a line break at the caret's position.
 */
- (void)insertNewLineBreak;

/**
 Inserts a string at the caret's position.
 
 @param text The string to be appended to the current text.
 */
- (void)insertTextAtCaretRange:(NSString *)text;

/**
 Adds a string to a specific range.
 
 @param text The string to be appended to the current text.
 @param range The range where to insert text.
 
 @return The range of the newly inserted text.
 */
- (NSRange)insertText:(NSString *)text inRange:(NSRange)range;

/**
 Finds the word close to the caret's position, if any.
 
 @param range Returns the range of the found word.
 @returns The found word.
 */
- (NSString *)wordAtCaretRange:(NSRangePointer)range;

/**
 Disables iOS8's Quick Type bar.
 @param disable YES if the bar should be disabled.
 */
- (void)disableQuickTypeBar:(BOOL)disable;

@end
