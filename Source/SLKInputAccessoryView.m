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

@implementation SLKInputAccessoryView

#pragma mark - Super Overrides

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview) {
        if (SLK_IS_IOS9_AND_HIGHER) {
            
            // NOTE:
            // Because the keyboard is on its own view hierarchy since iOS 9,
            // we needed to lookup for its view so we can move the text input whenever its origin changed.
            // We are disabling the detection of the keyboard on iOS 9 until a public API is available.
            //
            // Open Radar: http://openradar.appspot.com/radar?id=5021485877952512
            
            /*
            NSPredicate *windowPredicate = [NSPredicate predicateWithFormat:@"self isMemberOfClass: %@", NSClassFromString(@"UIRemoteKeyboardWindow")];
            UIWindow *keyboardWindow = [[[UIApplication sharedApplication].windows filteredArrayUsingPredicate:windowPredicate] firstObject];
            
            for (UIView *subview in keyboardWindow.subviews) {
                for (UIView *hostview in subview.subviews) {
                    if ([hostview isMemberOfClass:NSClassFromString(@"UIInputSetHostView")]) {
                        _keyboardViewProxy = hostview;
                        break;
                    }
                }
            }
             */
        }
        else {
            _keyboardViewProxy = newSuperview;
        }
    }
}

@end