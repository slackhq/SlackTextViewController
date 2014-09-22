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

extern NSString * const SLKTextViewTextWillChangeNotification;
extern NSString * const SLKTextViewSelectionDidChangeNotification;
extern NSString * const SLKTextViewContentSizeDidChangeNotification;
extern NSString * const SLKTextViewDidPasteImageNotification;
extern NSString * const SLKTextViewDidShakeNotification;

/**  @name A custom text input view. */
@interface SLKTextView : UITextView

/** The placeholder text string. */
@property (nonatomic, readwrite) NSString *placeholder;

/** The placeholder color. */
@property (nonatomic, readwrite) UIColor *placeholderColor;

/** The maximum number of lines before enabling scrolling. Default is 0 wich means limitless. */
@property (nonatomic, readwrite) NSUInteger maxNumberOfLines;

/** YES if the text view is and can still expand it self, depending if the maximum number of lines are reached. */
@property (nonatomic, readonly) BOOL isExpanding;

@end
