//
//  AppDelegate.m
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import "SLKTextViewController.h"
#import "MessageViewController.h"

@interface AppDelegate () <UIPopoverControllerDelegate>
@end

@implementation AppDelegate
            
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    UIViewController *vc = [UIViewController new];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Push Me" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(pushVC:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    [button setCenter:vc.view.center];
    [vc.view addSubview:button];
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    UITabBarController *tc = [UITabBarController new];
    tc.viewControllers = @[nc];
    
    self.window.rootViewController = tc;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)pushVC:(id)sender
{
    MessageViewController *mc = [MessageViewController new];
    mc.hidesBottomBarWhenPushed = YES;
    
    UITabBarController *tc = (UITabBarController *)self.window.rootViewController;
    UINavigationController *nc = (UINavigationController *)[tc.viewControllers firstObject];
    
    [nc pushViewController:mc animated:YES];
}

@end
