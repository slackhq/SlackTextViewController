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

#import "UIResponder+SLKAdditions.h"

static __weak id ___currentFirstResponder;

@implementation UIResponder (SLKAdditions)

/**
 Based on Jakob Egger's answer in http://stackoverflow.com/a/14135456/590010
 */
+ (instancetype)slk_currentFirstResponder
{
    ___currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(slk_findFirstResponder:) to:nil from:nil forEvent:nil];
    
    return ___currentFirstResponder;
}

- (void)slk_findFirstResponder:(id)sender
{
    ___currentFirstResponder = self;
}

@end
