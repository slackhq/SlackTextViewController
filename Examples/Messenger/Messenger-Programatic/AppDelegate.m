//
//  AppDelegate.m
//  Messenger-Programatic
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import "SLKTextViewController.h"
#import "MessageViewController.h"

@implementation AppDelegate
            
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[MessageViewController new]];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
