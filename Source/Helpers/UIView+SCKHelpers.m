//
//  UIView+SCKHelpers.m
//  Slack
//
//  Created by Ignacio on 8/20/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "UIView+SCKHelpers.h"

@implementation UIView (SCKHelpers)

- (void)animateLayoutIfNeededWithBounce:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations
{
    NSTimeInterval duration = bounce ? 0.5 : 0.2;
    [self animateLayoutIfNeededWithDuration:duration bounce:bounce curve:curve animations:animations];
}

- (void)animateLayoutIfNeededWithDuration:(NSTimeInterval)duration bounce:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations
{
    if (bounce) {
        [UIView animateWithDuration:duration
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.7
                            options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                         animations:^{
                             [self layoutIfNeeded];
                             
                             if (animations) {
                                 animations();
                             }
                         }
                         completion:NULL];
    }
    else {
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                         animations:^{
                             [self layoutIfNeeded];
                             
                             if (animations) {
                                 animations();
                             }
                         }
                         completion:NULL];
    }
}

- (NSArray *)constraintsForAttribute:(NSLayoutAttribute)attribute
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", attribute];
    return [self.constraints filteredArrayUsingPredicate:predicate];
}

@end
