//
//  UIScrollView+SCKHelpers.h
//  Slack
//
//  Created by Ignacio on 8/19/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (SCKHelpers)

- (void)scrollToBottomAnimated:(BOOL)animated;

- (BOOL)isAtTop;
- (BOOL)isAtBottom;

@end
