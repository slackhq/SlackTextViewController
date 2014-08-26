//
//  SCKTypeIndicatorView.h
//  Slack
//
//  Created by Ignacio Romero Z. on 5/13/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const SCKTypeIndicatorViewWillShowNotification;
extern NSString * const SCKTypeIndicatorViewWillHideNotification;

@interface SCKTypeIndicatorView : UIView

/** The amount of time a name should keep visible. If is zero, the indicator will not remove nor disappear automatically. Default is 6.0 seconds*/
@property (nonatomic) NSTimeInterval interval;
/** The height of the rows. Default is 26.0 */
@property (nonatomic) CGFloat height;
/** If YES, the user can dismiss the indicator by tapping on it. Default is YES. */
@property (nonatomic) BOOL canResignByTouch;
/** Returns YES if the indicator is visible. Setting the value calls setVisible:Animated with not animation. */
@property (nonatomic, getter = isVisible) BOOL visible;

/**
 * Inserts a user name, animatedly, only if that user name is not yet on the list.
 * It the indicator interval is bigger than zero, the name will be removed automatically from the list.
 *
 * @param username The user name string.
 */
- (void)insertUsername:(NSString *)username;

/**
 * Removes a user name, animatedly, if existent on the list.
 * It the indicator interval is bigger than zero, once there are no more items on the list, the indicator is dismissed automatically.
 *
 * @param username The user name string.
 */
- (void)removeUsername:(NSString *)username;

/**
 * Dismisses the indicator view, animatedly.
 */
- (void)dismissIndicator;

@end