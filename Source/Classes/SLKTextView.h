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
@property (nonatomic, copy) NSString *placeholder;

/** The placeholder color. */
@property (nonatomic, copy) UIColor *placeholderColor;

/** The maximum number of lines before enabling scrolling. Default is 0 wich means limitless. */
@property (nonatomic, readwrite) NSUInteger maxNumberOfLines;

/** The current displayed number of lines. */
@property (nonatomic, readonly) NSUInteger numberOfLines;

/** YES if the text view is and can still expand it self, depending if the maximum number of lines are reached. */
@property (nonatomic, readonly) BOOL isExpanding;

/** YES if quickly refreshed the textview without the intension to dismiss the keyboard. @view -disableQuicktypeBar: for more details. */
@property (nonatomic, readwrite) BOOL didNotResignFirstResponder;

/** YES if the magnifying glass is visible. */
@property (nonatomic, getter=isLoupeVisible) BOOL loupeVisible;

/**
 Disables iOS8's Quick Type bar.
 The cleanest hack so far is to disable auto-correction and spellingCheck momentarily, while calling -refreshFirstResponder if -isFirstResponder to be able to reflect the property changes in the text view.
 
 @param disable YES if the bar should be disabled.
 */
- (void)disableQuicktypeBar:(BOOL)disable;

/**
 Some text view properties don't update when it's already firstResponder (auto-correction, spelling-check, etc.)
 To be able to update the text view while still being first responder, requieres to switch quickly from -resignFirstResponder to -becomeFirstResponder.
 When doing so, the flag 'didNotResignFirstResponder' is momentarly set to YES before it goes back to -isFirstResponder, to be able to prevent some tasks to be excuted because of UIKeyboard notifications.
 
 You can also use this method to confirm an auto-correction programatically, before the text view resigns first responder.
 */
- (void)refreshFirstResponder;

@end
