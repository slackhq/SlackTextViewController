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
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.title = @"viewController";
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(showPopOver:)];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    self.window.rootViewController = navigationController;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (IBAction)showPopOver:(id)sender
{
    MessageViewController *messageController = [MessageViewController new];
    messageController.presentedInPopover = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:messageController];
    
    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
    popoverController.delegate = self;
    
    [popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    
}

@end
