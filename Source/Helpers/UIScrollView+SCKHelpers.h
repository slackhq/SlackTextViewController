//
//  UIScrollView+SCKHelpers.h
//  Slack
//
//  Created by Ignacio on 8/19/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (SCKHelpers)

/**
 Sets the offset from the content view’s origin to the very bottom.
 @param animated YES to animate the transition at a constant velocity to the new offset, NO to make the transition immediate.
 */
- (void)scrollToBottomAnimated:(BOOL)animated;

/** YES if the scrollView's offset is at the very top. */
- (BOOL)isAtTop;
/** YES if the scrollView's offset is at the very bottom. */
- (BOOL)isAtBottom;
/** YES if the scrollView can scroll from it's current offset position to the bottom. */
- (BOOL)canScrollToBottom;

@end
