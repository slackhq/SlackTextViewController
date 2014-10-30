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

#import "UIScrollView+SLKAdditions.h"
#import <objc/runtime.h>

static NSString * const kKeyScrollViewVerticalIndicator = @"_verticalScrollIndicator";
static NSString * const kKeyScrollViewHorizontalIndicator = @"_horizontalScrollIndicator";

@implementation UIScrollView (SLKAdditions)

- (void)slk_scrollToTopAnimated:(BOOL)animated
{
    if (![self slk_isAtTop]) {
        [self setContentOffset:[self slk_topOffset] animated:animated];
    }
}

- (void)slk_scrollToBottomAnimated:(BOOL)animated
{
    if ([self slk_canScrollToBottom]) {
        [self setContentOffset:[self slk_bottomOffset] animated:animated];
    }
}

- (BOOL)slk_isAtTop
{
    return (self.contentOffset.y == [self slk_topOffset].y) ? YES : NO;
}

- (BOOL)slk_isAtBottom
{
    return (self.contentOffset.y == [self slk_bottomOffset].y) ? YES : NO;
}

- (CGPoint)slk_topOffset
{
    return CGPointMake(self.contentOffset.x, 0.0);
}

- (CGPoint)slk_bottomOffset
{
    return CGPointMake(self.contentOffset.x, self.contentSize.height - self.bounds.size.height);
}

- (BOOL)slk_canScrollToBottom
{
    if (self.contentSize.height < self.bounds.size.height) {
        return NO;
    }
    if ([self slk_isAtBottom]) {
        return NO;
    }
    return YES;
}

- (void)slk_stopScrolling
{
    if (!self.isDragging) {
        return;
    }
    
    CGPoint offset = self.contentOffset;
    offset.y -= 1.0;
    [self setContentOffset:offset];
    
    offset.y += 1.0;
    [self setContentOffset:offset];
}

- (UIView *)slk_verticalScroller
{
    if (objc_getAssociatedObject(self, _cmd) == nil) {
        objc_setAssociatedObject(self, _cmd, [self slk_safeValueForKey:kKeyScrollViewVerticalIndicator], OBJC_ASSOCIATION_ASSIGN);
    }
    
    return objc_getAssociatedObject(self, _cmd);
}

- (UIView *)slk_horizontalScroller
{
    if (objc_getAssociatedObject(self, _cmd) == nil) {
        objc_setAssociatedObject(self, _cmd, [self slk_safeValueForKey:kKeyScrollViewHorizontalIndicator], OBJC_ASSOCIATION_ASSIGN);
    }
    
    return objc_getAssociatedObject(self, _cmd);
}

- (id)slk_safeValueForKey:(NSString *)key
{
    Ivar instanceVariable = class_getInstanceVariable([self class], [key cStringUsingEncoding:NSUTF8StringEncoding]);
    return object_getIvar(self, instanceVariable);
}

@end
