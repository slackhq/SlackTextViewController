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

#import <UIKit/UIKit.h>

/**
 Classes that adopt the SLKTextInput protocol interact with the text input system and thus acquire features such as text processing.
 All these methods are already implemented in SLKTextInput+Extension.
 */
@protocol SLKTextInput <UITextInput>
@optional

/**
 Searches for any matching string prefix at the text input's caret position. When nothing found, the completion block returns nil values.
 This implementation is internally performed on a background thread and forwarded to the main thread once completed.
 
 @param prefixes A set of prefixes to search for.
 @param completion A completion block called whenever the text processing finishes, successfuly or not. Required.
 */
- (void)lookForPrefixes:(NSSet *)prefixes
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
