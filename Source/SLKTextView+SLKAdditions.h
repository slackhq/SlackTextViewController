//
//   Copyright 2014-2016 Slack Technologies, Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import "SLKTextView.h"

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
 Finds the word close to the caret's position, if any.
 
 @param range Returns the range of the found word.
 @returns The found word.
 */
- (NSString *)slk_wordAtCaretRange:(NSRangePointer)range;


/**
 Finds the word close to specific range.
 
 @param range The range to be used for searching the word.
 @param rangePointer Returns the range of the found word.
 @returns The found word.
 */
- (NSString *)slk_wordAtRange:(NSRange)range rangeInText:(NSRangePointer)rangePointer;

/**
 Registers the current text for future undo actions.
 
 @param description A simple description associated with the Undo or Redo command.
 */
- (void)slk_prepareForUndo:(NSString *)description;

/**
 Returns a constant font size difference reflecting the current accessibility settings.
 
 @param category A content size category constant string.
 @returns A float constant font size difference.
 */
+ (CGFloat)pointSizeDifferenceForCategory:(NSString *)category;

@end
