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

#import "SLKInputAccessoryView.h"
#import "SLKUIConstants.h"

NSString * const SLKInputAccessoryViewKeyboardFrameDidChangeNotification = @"SLKInputAccessoryViewKeyboardFrameDidChangeNotification";

@interface SLKInputAccessoryView ()
@property (nonatomic, weak) UIView *observedSuperview;
@end

@implementation SLKInputAccessoryView

#pragma mark - Getters

NSString *SLKKeyboardHandlingKeyPath()
{
    // Listening for the superview's frame doesn't work on iOS8 and above, so we use its center
    if (SLK_IS_IOS8_AND_HIGHER) {
        return NSStringFromSelector(@selector(center));
    }
    else {
        return NSStringFromSelector(@selector(frame));
    }
}


#pragma mark - Super Overrides

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [self slk_removeSuperviewObserver];
    [self slk_addSuperviewObserver:newSuperview];
    
    [super willMoveToSuperview:newSuperview];
}


#pragma mark - Superview handling

- (void)slk_addSuperviewObserver:(UIView *)superview
{
    if (_observedSuperview || !superview) {
        return;
    }
    
    _observedSuperview = superview;
    
    [superview addObserver:self forKeyPath:SLKKeyboardHandlingKeyPath() options:0 context:NULL];
}

- (void)slk_removeSuperviewObserver
{
    if (!_observedSuperview) {
        return;
    }
    
    [self.observedSuperview removeObserver:self forKeyPath:SLKKeyboardHandlingKeyPath()];
    
    _observedSuperview = nil;
}


#pragma mark - Events

- (void)slk_didChangeKeyboardFrame:(CGRect)frame
{
    NSDictionary *userInfo = @{UIKeyboardFrameEndUserInfoKey:[NSValue valueWithCGRect:frame]};
    [[NSNotificationCenter defaultCenter] postNotificationName:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil userInfo:userInfo];
}


#pragma mark - KVO Listener

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.superview] && [keyPath isEqualToString:SLKKeyboardHandlingKeyPath()]) {
        [self slk_didChangeKeyboardFrame:self.superview.frame];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Lifeterm

- (void)dealloc
{
    [self slk_removeSuperviewObserver];
}

@end
