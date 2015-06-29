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

#import <Foundation/Foundation.h>

/**
 Generic protocol needed when customizing your own typing indicator view.
 SLKTextViewController depends of the 'isVisible' property internally, to detect with KVO its changes and update the typing indicator view's constraints automatically.
 Because of this, you MUST conform to this protocol and implement the required methods.
 */
@protocol SLKTypingIndicatorProtocol <NSObject>
@required

/** Returns YES if the indicator is visible. */
@property (nonatomic, getter = isVisible) BOOL visible;

/**
 Updates the 'visible' state.
 To enable the typing indicator, you MUST override this method and implement key-value observer compliance manually,
 using the -willChangeValueForKey: and -didChangeValueForKey: methods.
 
 @return YES if the indicator view is visible.
 */
- (void)setVisible:(BOOL)visible;

@optional

/**
 Dismisses the indicator view.
 */
- (void)dismissIndicator;

@end