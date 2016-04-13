//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "UIView+SLKAdditions.h"

#import "SLKUIConstants.h"

@implementation UIView (SLKAdditions)

- (void)slk_animateLayoutIfNeededWithBounce:(BOOL)bounce options:(UIViewAnimationOptions)options animations:(void (^)(void))animations
{
    [self slk_animateLayoutIfNeededWithBounce:bounce options:options animations:animations completion:NULL];
}

- (void)slk_animateLayoutIfNeededWithBounce:(BOOL)bounce options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    NSTimeInterval duration = bounce ? 0.65 : 0.2;
    [self slk_animateLayoutIfNeededWithDuration:duration bounce:bounce options:options animations:animations completion:completion];
}

- (void)slk_animateLayoutIfNeededWithDuration:(NSTimeInterval)duration bounce:(BOOL)bounce options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion
{
    if (bounce) {
        [UIView animateWithDuration:duration
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.7
                            options:options
                         animations:^{
                             [self layoutIfNeeded];
                             
                             if (animations) {
                                 animations();
                             }
                         }
                         completion:completion];
    }
    else {
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:options
                         animations:^{
                             [self layoutIfNeeded];
                             
                             if (animations) {
                                 animations();
                             }
                         }
                         completion:completion];
    }
}

- (NSArray *)slk_constraintsForAttribute:(NSLayoutAttribute)attribute
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", attribute];
    return [self.constraints filteredArrayUsingPredicate:predicate];
}

- (NSLayoutConstraint *)slk_constraintForAttribute:(NSLayoutAttribute)attribute firstItem:(id)first secondItem:(id)second
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d AND firstItem = %@ AND secondItem = %@", attribute, first, second];
    return [[self.constraints filteredArrayUsingPredicate:predicate] firstObject];
}

@end
