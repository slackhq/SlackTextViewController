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

@implementation UIScrollView (SLKAdditions)

- (void)slk_scrollToTopAnimated:(BOOL)animated
{
    [self scrollRectToVisible:[self slk_topRect] animated:animated];
}

- (void)slk_scrollToBottomAnimated:(BOOL)animated
{
    [self scrollRectToVisible:[self slk_bottomRect] animated:animated];
}

- (BOOL)slk_isAtTop
{
    return CGRectGetMinY([self slk_visibleRect]) <= CGRectGetMinY([self slk_topRect]);
}

- (BOOL)slk_isAtBottom
{
    return CGRectGetMaxY([self slk_visibleRect]) >= CGRectGetMaxY([self slk_bottomRect]);
}

- (CGRect)slk_visibleRect
{
    CGRect visibleRect;
    visibleRect.origin = self.contentOffset;
    visibleRect.size = self.frame.size;
    return visibleRect;
}

- (CGRect)slk_topRect
{
    return CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
}

- (CGRect)slk_bottomRect
{
    return CGRectMake(0, self.contentSize.height - CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
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

@end
