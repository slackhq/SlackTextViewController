//
//  ChatRoomViewController.m
//  ChatRoom
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "ChatRoomViewController.h"

#import <LoremIpsum/LoremIpsum.h>

@interface ChatRoomViewController ()
@property (nonatomic, getter = isReachable) BOOL reachable;
@end

@implementation ChatRoomViewController

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"SlackChatKit";
    
    UIBarButtonItem *reachItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_network"] style:UIBarButtonItemStylePlain target:self action:@selector(simulateReachability)];
    UIBarButtonItem *typeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_typing"] style:UIBarButtonItemStylePlain target:self action:@selector(simulateUserTyping)];
    UIBarButtonItem *appendItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_append"] style:UIBarButtonItemStylePlain target:self action:@selector(fillWithText)];

    self.navigationItem.leftBarButtonItems = @[reachItem];
    self.navigationItem.rightBarButtonItems = @[appendItem,typeItem];
    
    self.reachable = YES;
    
    self.allowElasticity = YES;
    
    self.textContainerView.autoHideRightButton = NO;
    
    self.textView.placeholder = NSLocalizedString(@"Message", nil);
    self.textView.placeholderColor = [UIColor lightGrayColor];
    self.textView.layer.borderColor = [UIColor colorWithRed:217/255.0 green:217/255.0 blue:217/255.0 alpha:1.0].CGColor;
    self.textContainerView.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1.0];
    
    [self.rightButton addTarget:self action:@selector(didTapRighttButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    [self.rightButton setTintColor:[UIColor colorWithRed:0/255.0 green:136.0/255.0 blue:204.0/255.0 alpha:1.0]];
    [self.leftButton setAccessibilityLabel:@"Send button"];

    [self.leftButton addTarget:self action:@selector(didTapLeftButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.leftButton setTintColor:[UIColor colorWithRed:154/255.0 green:159/255.0 blue:166/255.0 alpha:1.0]];
    [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
    [self.leftButton setAccessibilityLabel:@"Upload image"];
}


#pragma mark - Action Methods

- (void)didTapLeftButton:(id)sender
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)didTapRighttButton:(id)sender
{
    NSLog(@"%s",__FUNCTION__);
    
    self.textView.text = @"";
}

- (void)fillWithText
{
    if (self.textView.text.length == 0) {
        self.textView.text = [LoremIpsum sentencesWithNumber:3];
    }
    else {
        [self.textView insertTextAtCursor:[LoremIpsum word]];
    }
}

- (void)simulateUserTyping
{
    [self.typeIndicatorView insertUsername:@"Ignacio"];
}

- (void)simulateReachability
{
    _reachable = !self.isReachable;
    
    [self didChangeReachability];
}


#pragma mark - Extension

- (void)didChangeReachability
{
    NSString *placeholder = self.isReachable ? NSLocalizedString(@"Message", nil) : NSLocalizedString(@"Loading...", nil);
    UIColor *textViewColor = self.isReachable ? [UIColor whiteColor] : [UIColor colorWithRed:253/255.0 green:240/255.0 blue:195/255.0 alpha:1.0];
    
    self.textView.placeholder = placeholder;
    self.textView.backgroundColor = textViewColor;
    
    self.rightButton.enabled = self.isReachable;
}


#pragma mark - Overriden Methods

- (BOOL)canPressSendButton
{
    return self.isReachable;
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"cell %ld", (long)indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


#pragma mark - View lifeterm

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}


#pragma mark - View Auto-Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
