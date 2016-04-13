//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTextView.h"

NS_ASSUME_NONNULL_BEGIN

/** @name SLKTextView additional features used for SlackTextViewController. */
@interface SLKTextView (SLKAdditions)

/**
 Clears the text.
 
 @param clearUndo YES if clearing the text should also clear the undo manager (if enabled).
 */
- (void)slk_clearText:(BOOL)clearUndo;

/**
 Scrolls to the very end of the content size, animated.
 
 @param animated YES if the scrolling should be animated.
 */
- (void)slk_scrollToBottomAnimated:(BOOL)animated;

/**
 Scrolls to the caret position, animated.
 
 @param animated YES if the scrolling should be animated.
 */
- (void)slk_scrollToCaretPositonAnimated:(BOOL)animated;

/**
 Inserts a line break at the caret's position.
 */
- (void)slk_insertNewLineBreak;

/**
 Inserts a string at the caret's position.
 
 @param text The string to be appended to the current text.
 */
- (void)slk_insertTextAtCaretRange:(NSString *)text;

/**
 Adds a string to a specific range.
 
 @param text The string to be appended to the current text.
 @param range The range where to insert text.
 
 @return The range of the newly inserted text.
 */
- (NSRange)slk_insertText:(NSString *)text inRange:(NSRange)range;

/**
 Registers the current text for future undo actions.
 
 @param description A simple description associated with the Undo or Redo command.
 */
- (void)slk_prepareForUndo:(NSString *)description;

@end

NS_ASSUME_NONNULL_END

