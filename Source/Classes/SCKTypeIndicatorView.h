//
//  SCKTypeIndicatorView.h
//  SlackChatKit
//  https://github.com/tinyspeck/slack-chat-kit
//
//  Created by Ignacio Romero Zurbuchen on 5/13/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//  Licence: MIT-Licence
//

#import <UIKit/UIKit.h>

extern NSString * const SCKTypeIndicatorViewWillShowNotification;
extern NSString * const SCKTypeIndicatorViewWillHideNotification;

/** @name A custom view to display an indicator of users typing. */
@interface SCKTypeIndicatorView : UIView

/** The amount of time a name should keep visible. If is zero, the indicator will not remove nor disappear automatically. Default is 6.0 seconds*/
@property (nonatomic, readwrite) NSTimeInterval interval;
/** The height of the view. Default is 26.0 */
@property (nonatomic, readwrite) CGFloat height;
/** If YES, the user can dismiss the indicator by tapping on it. Default is YES. */
@property (nonatomic, readwrite) BOOL canResignByTouch;
/** Returns YES if the indicator is visible. */
@property (nonatomic, readwrite, getter = isVisible) BOOL visible;

/**
 Inserts a user name, only if that user name is not yet on the list.
 @discussion Each inserted name has an attached timer, which will automatically remove the name from the list once the interval is reached (default 6 seconds).
 
 The control follows a set of display rules, to accomodate the screen size:
 
 - When only 1 user name is set, it will display ":name is typing"
 
 - When only 2 user names are set, it will display ":name & :name are typing"
 
 - When more than 2 user names are set, it will display "several people are typing"
 
 @param username The user name string.
 */
- (void)insertUsername:(NSString *)username;

/**
 Removes a user name, if existent on the list.
 @discussion Once there are no more items on the list, the indicator will automatically try to hide (by setting it self to visible = NO).

 @param username The user name string.
 */
- (void)removeUsername:(NSString *)username;

/**
 * Dismisses the indicator view.
 */
- (void)dismissIndicator;

@end