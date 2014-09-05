//
//  UIScrollView+ChatKitAdditions.h
//  Slack
//
//  Created by Ignacio Romero Zurbuchen on 8/19/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/** @name UIScrollView additional features used for Slack Chat Kit. */
@interface UIScrollView (ChatKitAdditions)

/** YES if the scrollView's offset is at the very top. */
@property (nonatomic, readonly) BOOL isAtTop;
/** YES if the scrollView's offset is at the very bottom. */
@property (nonatomic, readonly) BOOL isAtBottom;
/** YES if the scrollView can scroll from it's current offset position to the bottom. */
@property (nonatomic, readonly) BOOL canScrollToBottom;

/** The vertical scroll indicator view. */
@property (nonatomic, readonly) UIView *verticalScroller;
/** The horizontal scroll indicator view. */
@property (nonatomic, readonly) UIView *horizontalScroller;

- (void)scrollToTopAnimated:(BOOL)animated;

/**
 Sets the offset from the content view’s origin to the very bottom.
 @param animated YES to animate the transition at a constant velocity to the new offset, NO to make the transition immediate.
 */
- (void)scrollToBottomAnimated:(BOOL)animated;

/**
 Stops scrolling, if it was scrolling.
 */
- (void)stopScrolling;

@end
