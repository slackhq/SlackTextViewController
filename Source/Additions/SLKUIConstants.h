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

#define UI_IS_LANDSCAPE         ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight)
#define UI_IS_IPAD              ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define UI_IS_IPHONE            ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define UI_IS_IPHONE4           (UI_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height < 568.0)
#define UI_IS_IPHONE5           (UI_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0)
#define UI_IS_IPHONE6           (UI_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0)
#define UI_IS_IPHONE6PLUS       (UI_IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0 || [[UIScreen mainScreen] bounds].size.width == 736.0) // Both orientations
#define UI_IS_IOS8_AND_HIGHER   ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)


typedef NS_ENUM(NSUInteger, SLKQuicktypeBarMode) {
    SLKQuicktypeBarModeHidden,
    SLKQuicktypeBarModeCollapsed,
    SLKQuicktypeBarModeExpanded ,
};


inline static CGFloat minimumKeyboardHeight()
{
    if (UI_IS_IPAD) {
        if (UI_IS_LANDSCAPE) return 352.f;
        else return 264.f;
    }
    if (UI_IS_IPHONE6PLUS) {
        if (UI_IS_LANDSCAPE) return 162.f;
        else return 226.f;
    }
    else {
        if (UI_IS_LANDSCAPE) return 162.f;
        else return 216.f;
    }
}

inline static CGFloat SLKQuicktypeBarHeightForMode(SLKQuicktypeBarMode mode)
{
    if (UI_IS_IPAD) {
        switch (mode) {
            case SLKQuicktypeBarModeHidden:
                return 0.f;
                
            case SLKQuicktypeBarModeCollapsed:
                return 10.f;
                
            case SLKQuicktypeBarModeExpanded :
                return 39.f;
        }
    }
    if (UI_IS_IPHONE6PLUS) {
        switch (mode) {
            case SLKQuicktypeBarModeHidden:
                return 0.f;
                
            case SLKQuicktypeBarModeCollapsed:
                return 9.f;
                
            case SLKQuicktypeBarModeExpanded :
                if (UI_IS_LANDSCAPE) return 32.f;
                else return 45.f;
        }
    }
    else {
        switch (mode) {
            case SLKQuicktypeBarModeHidden:
                return 0.f;
                
            case SLKQuicktypeBarModeCollapsed:
                return 8.f;
                
            case SLKQuicktypeBarModeExpanded :
                if (UI_IS_LANDSCAPE) return 31.f;
                else return 37.f;
        }
    }
}

inline static SLKQuicktypeBarMode SLKQuicktypeBarModeForHeight(CGFloat height)
{
    if (height > 0.f && height <= 10.f) {
        return SLKQuicktypeBarModeCollapsed;
    }
    
    if (height > 10.f && height <= 45.f) {
        return SLKQuicktypeBarModeExpanded ;
    }
    
    return SLKQuicktypeBarModeHidden;
}
