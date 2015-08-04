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

#define SLK_IS_LANDSCAPE         ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeRight)
#define SLK_IS_IPAD              ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define SLK_IS_IPHONE            ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define SLK_IS_IPHONE4           (SLK_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height < 568.0)
#define SLK_IS_IPHONE5           (SLK_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0)
#define SLK_IS_IPHONE6           (SLK_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0)
#define SLK_IS_IPHONE6PLUS       (SLK_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0 || [[UIScreen mainScreen] bounds].size.width == 736.0) // Both orientations
#define SLK_IS_IOS8_AND_HIGHER   ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)

#define SLK_KEYBOARD_NOTIFICATION_DEBUG     DEBUG && 0  // Logs every keyboard notification being sent

#if __has_attribute(objc_designated_initializer)
#define SLK_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#endif

static NSString *SLKTextViewControllerDomain = @"com.slack.TextViewController";

inline static CGFloat minimumKeyboardHeight()
{
    if (SLK_IS_IPAD) {
        if (SLK_IS_LANDSCAPE) return 352.f;
        else return 264.f;
    }
    if (SLK_IS_IPHONE6PLUS) {
        if (SLK_IS_LANDSCAPE) return 162.f;
        else return 226.f;
    }
    else {
        if (SLK_IS_LANDSCAPE) return 162.f;
        else return 216.f;
    }
}

inline static CGRect SLKRectInvert(CGRect rect)
{
    CGRect invert = CGRectZero;
    
    invert.origin.x = rect.origin.y;
    invert.origin.y = rect.origin.x;
    invert.size.width = rect.size.height;
    invert.size.height = rect.size.width;
    
    return invert;
}