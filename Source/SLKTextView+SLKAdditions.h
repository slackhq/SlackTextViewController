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
 Insert a string at the caret's position with stylization from the attributes.
 
 @param text The string to be appended to the current text.
 @param attributes The attributes used to stylize the text.
 */
- (void)slk_insertTextAtCaretRange:(NSString *)text
                    withAttributes:(NSDictionary<NSString *, id> *)attributes;

/**
 Adds a string to a specific range.
 
 @param text The string to be appended to the current text.
 @param range The range where to insert text.
 
 @return The range of the newly inserted text.
 */
- (NSRange)slk_insertText:(NSString *)text inRange:(NSRange)range;

/**
 Adds a string to a specific range, with stylization from the attributes.
 
 @param text The string to be appended to the current text.
 @param attributes The attributes used to stylize the text.
 @param range The range where to insert text.
 @return The range of the newly inserted text.
 */
- (NSRange)slk_insertText:(NSString *)text
           withAttributes:(NSDictionary<NSString *, id> *)attributes
                  inRange:(NSRange)range;

/**
 Sets the text attributes for the attributed string in the provided range.
 
 @param attributes The attributes used to style NSAttributedString class.
 @param range The range of the text that needs to be stylized by the given attributes.
 @return An attributed string.
 */
- (NSAttributedString *)slk_setAttributes:(NSDictionary<NSString *, id> *)attributes
                                  inRange:(NSRange)range;

/**
 Inserts an attributed string at the caret's position.
 
 @param attributedText The attributed string to be appended.
 */
- (void)slk_insertAttributedTextAtCaretRange:(NSAttributedString *)attributedText;

/**
 Adds an attributed string to a specific range.
 
 @param text The string to be appended to the current text.
 @param range The range where to insert text.
 @return The range of the newly inserted text.
 */
- (NSRange)slk_insertAttributedText:(NSAttributedString *)attributedText inRange:(NSRange)range;

/**
 Removes all attributed string attributes from the text view, for the given range.
 
 @param range The range to remove the attributes.
 */
- (void)slk_clearAllAttributesInRange:(NSRange)range;

/**
 Returns a default attributed string, using the text view's font and text color.
 
 @param text The string to be used for creating a new attributed string.
 @return An attributed string.
 */
- (NSAttributedString *)slk_defaultAttributedStringForText:(NSString *)text;

/**
 Registers the current text for future undo actions.
 
 @param description A simple description associated with the Undo or Redo command.
 */
- (void)slk_prepareForUndo:(NSString *)description;

@end

NS_ASSUME_NONNULL_END

