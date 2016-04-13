//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Generic protocol needed when customizing your own typing indicator view. */
@protocol SLKTypingIndicatorProtocol <NSObject>
@required

/**
 Returns YES if the indicator is visible.
 SLKTextViewController depends on this property internally, by observing its value changes to update the typing indicator view's constraints automatically.
 You can simply @synthesize this property to make it KVO compliant, or override its setter method and wrap its implementation with -willChangeValueForKey: and -didChangeValueForKey: methods, for more complex KVO compliance.
 */
@property (nonatomic, getter = isVisible) BOOL visible;

@optional

/**
 Dismisses the indicator view.
 */
- (void)dismissIndicator;

@end

NS_ASSUME_NONNULL_END