//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import <UIKit/UIKit.h>

/** @name UIScrollView additional features used for SlackTextViewController. */
@interface UIScrollView (SLKAdditions)

/** YES if the scrollView's offset is at the very top. */
@property (nonatomic, readonly) BOOL slk_isAtTop;
/** YES if the scrollView's offset is at the very bottom. */
@property (nonatomic, readonly) BOOL slk_isAtBottom;
/** The visible area of the content size. */
@property (nonatomic, readonly) CGRect slk_visibleRect;

/**
 Sets the content offset to the top.
 
 @param animated YES to animate the transition at a constant velocity to the new offset, NO to make the transition immediate.
 */
- (void)slk_scrollToTopAnimated:(BOOL)animated;

/**
 Sets the content offset to the bottom.
 
 @param animated YES to animate the transition at a constant velocity to the new offset, NO to make the transition immediate.
 */
- (void)slk_scrollToBottomAnimated:(BOOL)animated;

/**
 Stops scrolling, if it was scrolling.
 */
- (void)slk_stopScrolling;

@end