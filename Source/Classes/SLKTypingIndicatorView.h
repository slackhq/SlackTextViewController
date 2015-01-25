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

extern NSString * const SLKTypingIndicatorViewWillShowNotification;
extern NSString * const SLKTypingIndicatorViewWillHideNotification;

/** @name A custom view to display an indicator of users typing. */
@interface SLKTypingIndicatorView : UIView

/** The amount of time a name should keep visible. If is zero, the indicator will not remove nor disappear automatically. Default is 6.0 seconds*/
@property (nonatomic, readwrite) NSTimeInterval interval;

/** If YES, the user can dismiss the indicator by tapping on it. Default is YES. */
@property (nonatomic, readwrite) BOOL canResignByTouch;

/** Returns YES if the indicator is visible. */
@property (nonatomic, readwrite, getter = isVisible) BOOL visible;

/** The appropriate height of the view. */
@property (nonatomic, readonly) CGFloat height;

/** The color of the text. Default is grayColor. */
@property (nonatomic, strong) UIColor *textColor;

/** The font of the text. Default is system font, 12 pts. */
@property (nonatomic, strong) UIFont *textFont;

/** The font to be used when matching a username string. Default is system bold font, 12 pts. */
@property (nonatomic, strong) UIFont *highlightFont;

/** The inner padding to use when laying out content in the view. Default is {10, 40, 10, 10}. */
@property (nonatomic, assign) UIEdgeInsets contentInset;

/**
 Inserts a user name, only if that user name is not yet on the list.
 Each inserted name has an attached timer, which will automatically remove the name from the list once the interval is reached (default 6 seconds).
 
 The control follows a set of display rules, to accomodate the screen size:
 
 - When only 1 user name is set, it will display ":name is typing"
 
 - When only 2 user names are set, it will display ":name & :name are typing"
 
 - When more than 2 user names are set, it will display "several people are typing"
 
 @param username The user name string.
 */
- (void)insertUsername:(NSString *)username;

/**
 Removes a user name, if existent on the list.
 Once there are no more items on the list, the indicator will automatically try to hide (by setting it self to visible = NO).

 @param username The user name string.
 */
- (void)removeUsername:(NSString *)username;

/**
 Dismisses the indicator view.
 */
- (void)dismissIndicator;

@end
