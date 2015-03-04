//
//  AppDelegate.m
//  Messenger-Programatic-iPad-Sheet
//
//  Created by Bob Spryn on 1/23/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "SLKTextViewController.h"
#import "MessageViewController.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:[MessageViewController new]];
    
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    navVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    
    [self.window.rootViewController presentViewController:navVC animated:YES completion:nil];
    return YES;
}


@end
