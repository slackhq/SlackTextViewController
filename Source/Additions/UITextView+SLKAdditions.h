//
//   Copyright 2014 Slack Technologies, Inc.
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

#import <UIKit/UIKit.h>

/** @name UITextView additional features used for SlackTextViewController. */
@interface UITextView (SLKAdditions)

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

@end
