//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import <UIKit/UIKit.h>

/**
 Classes that adopt the SLKTextInput protocol interact with the text input system and thus acquire features such as text processing.
 All these methods are already implemented in SLKTextInput+Implementation.m
 */
@protocol SLKTextInput <UITextInput>
@optional

/**
 Searches for any matching string prefix at the text input's caret position. When nothing found, the completion block returns nil values.
 This implementation is internally performed on a background thread and forwarded to the main thread once completed.
 
 @param prefixes A set of prefixes to search for.
 @param completion A completion block called whenever the text processing finishes, successfuly or not. Required.
 */
- (void)lookForPrefixes:(NSSet<NSString *> *)prefixes
             completion:(void (^)(NSString *prefix, NSString *word, NSRange wordRange))completion;

/**
 Finds the word close to the caret's position, if any.
 
 @param range Returns the range of the found word.
 @returns The found word.
 */
- (NSString *)wordAtCaretRange:(NSRangePointer)range;


/**
 Finds the word close to specific range.
 
 @param range The range to be used for searching the word.
 @param rangePointer Returns the range of the found word.
 @returns The found word.
 */
- (NSString *)wordAtRange:(NSRange)range rangeInText:(NSRangePointer)rangePointer;

@end
