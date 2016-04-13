//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#define SLK_IS_LANDSCAPE         ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeLeft || [[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeRight)
#define SLK_IS_IPAD              ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define SLK_IS_IPHONE            ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define SLK_IS_IPHONE4           (SLK_IS_IPHONE && SLKKeyWindowBounds().size.height < 568.0)
#define SLK_IS_IPHONE5           (SLK_IS_IPHONE && SLKKeyWindowBounds().size.height == 568.0)
#define SLK_IS_IPHONE6           (SLK_IS_IPHONE && SLKKeyWindowBounds().size.height == 667.0)
#define SLK_IS_IPHONE6PLUS       (SLK_IS_IPHONE && SLKKeyWindowBounds().size.height == 736.0 || SLKKeyWindowBounds().size.width == 736.0) // Both orientations
#define SLK_IS_IOS8_AND_HIGHER   ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)
#define SLK_IS_IOS9_AND_HIGHER   ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0)

#define SLK_KEYBOARD_NOTIFICATION_DEBUG     DEBUG && 0  // Logs every keyboard notification being sent

#if __has_attribute(objc_designated_initializer)
    #define SLK_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
#endif

static NSString *SLKTextViewControllerDomain = @"com.slack.TextViewController";

/**
 Returns a constant font size difference reflecting the current accessibility settings.
 
 @param category A content size category constant string.
 @returns A float constant font size difference.
 */
__unused static CGFloat SLKPointSizeDifferenceForCategory(NSString *category)
{
    if ([category isEqualToString:UIContentSizeCategoryExtraSmall])                         return -3.0;
    if ([category isEqualToString:UIContentSizeCategorySmall])                              return -2.0;
    if ([category isEqualToString:UIContentSizeCategoryMedium])                             return -1.0;
    if ([category isEqualToString:UIContentSizeCategoryLarge])                              return 0.0;
    if ([category isEqualToString:UIContentSizeCategoryExtraLarge])                         return 2.0;
    if ([category isEqualToString:UIContentSizeCategoryExtraExtraLarge])                    return 4.0;
    if ([category isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge])               return 6.0;
    if ([category isEqualToString:UIContentSizeCategoryAccessibilityMedium])                return 8.0;
    if ([category isEqualToString:UIContentSizeCategoryAccessibilityLarge])                 return 10.0;
    if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraLarge])            return 11.0;
    if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraLarge])       return 12.0;
    if ([category isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge])  return 13.0;
    return 0;
}

__unused static CGRect SLKKeyWindowBounds()
{
    return [[UIApplication sharedApplication] keyWindow].bounds;
}

__unused static CGRect SLKRectInvert(CGRect rect)
{
    CGRect invert = CGRectZero;
    
    invert.origin.x = rect.origin.y;
    invert.origin.y = rect.origin.x;
    invert.size.width = rect.size.height;
    invert.size.height = rect.size.width;
    
    return invert;
}
