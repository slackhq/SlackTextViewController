//
//  ChatRoomViewController.m
//  ChatRoom
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "ChatRoomViewController.h"

#import <LoremIpsum/LoremIpsum.h>

@interface SearchResult : NSObject
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSArray *list;
@end

@implementation SearchResult
@end

@interface ChatRoomViewController ()
@property (nonatomic, getter = isReachable) BOOL reachable;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *commands;
@property (nonatomic, strong) NSArray *emojis;

@property (nonatomic, strong) SearchResult *searchResult;

@end

@implementation ChatRoomViewController

- (instancetype)init
{
    if (self = [super init]) {
        
        self.users = @[@"ignacio", @"michael", @"brady", @"everyone", @"channel", @"ali"];
        self.channels = @[@"general", @"ios", @"random", @"ssb", @"mobile", @"ui", @"released", @"SF"];
        self.commands = @[@"help", @"away", @"close", @"color", @"colors", @"feedback", @"invite", @"me", @"msg", @"dm", @"open"];
        self.emojis = @[@"bowtie", @"boar", @"boat", @"book", @"bookmark", @"neckbeard", @"metal", @"fu", @"feelsgood"];
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
    
    self.textContainerView.autoHideRightButton = YES;
    
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
    
    self.signLookup = [@[@"@", @"#", @"/", @":"] mutableCopy];
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
        self.textView.text = [LoremIpsum sentencesWithNumber:4];
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


#pragma mark - SCKAutoCompletionDelegate Methods

- (BOOL)tableView:(UITableView *)tableView shouldShowAutoCompletionForSearchString:(NSString *)string withSign:(NSString *)sign
{
    NSLog(@"%s string: %@ sign: %@",__FUNCTION__, string, sign);
    
    NSArray *array = nil;
    
    self.searchResult = [SearchResult new];
    self.searchResult.key = sign;

    if ([sign isEqualToString:@"@"]) {
        array = self.users;
    }
    else if ([sign isEqualToString:@"#"]) {
        array = self.channels;
    }
    else if ([sign isEqualToString:@"/"]) {
        array = self.commands;
    }
    else if ([sign isEqualToString:@":"]) {
        array = self.emojis;
    }
    else {
        array = nil;
    }
    
    if (array.count == 0) {
        return NO;
    }
    
    //TODO: not include user_me in the list (like web app)
    
    if (string.length > 0) {
        array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@ AND self != %@", string, string]];
        self.searchResult.list = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    self.searchResult.list = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    return self.searchResult.list.count > 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForSearchString:(NSString *)string withSign:(NSString *)sign
{
    CGFloat cellHeight = [self.autoCompleteView.delegate tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cellHeight*self.searchResult.list.count;
}

- (void)tableView:(UITableView *)tableView didSelectStringRepresentation:(NSString *)string withSign:(NSString *)sign
{
    NSLog(@"%s",__FUNCTION__);
}

- (NSString *)tableView:(UITableView *)tableView stringToAppendAfterSelectingSearchString:(NSString *)string withSign:(NSString *)sign
{
    NSLog(@"%s",__FUNCTION__);
    
    return nil;
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.tableView]) {
        return 30;
    }
    else {
        return self.searchResult.list.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if ([tableView isEqual:self.tableView]) {
        cell.backgroundColor = [UIColor whiteColor];
        
        cell.textLabel.text = [NSString stringWithFormat:@"cell %ld", (long)indexPath.row];
    }
    else {
        cell.backgroundColor = [UIColor clearColor];
        
        NSString *sign = self.searchResult.key;
        NSString *item = self.searchResult.list[indexPath.row];

        if ([sign isEqualToString:@"#"]) {
            item = [NSString stringWithFormat:@"# %@", item];
        }
        else if ([sign isEqualToString:@":"]) {
            item = [NSString stringWithFormat:@":%@:", item];
        }
        
        cell.textLabel.text = item;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        return 60.0;
    }
    else {
        return 40.0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.autoCompleteView]) {
        UIView *topView = [UIView new];
        topView.backgroundColor = self.autoCompleteView.separatorColor;
        return topView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.autoCompleteView]) {
        return 0.5;
    }
    return 0.0;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.autoCompleteView]) {
        
        NSString *sign = self.searchResult.key;
        NSString *item = self.searchResult.list[indexPath.row];
        
        if ([sign isEqualToString:@"@"]) {
            item = [NSString stringWithFormat:@"%@: ", item];
        }
        else if ([sign isEqualToString:@":"]) {
            item = [NSString stringWithFormat:@"%@: ", item];
        }
        else {
            item = [NSString stringWithFormat:@"%@ ", item];
        }
        
        NSLog(@"item : %@", item);
        
        [self replaceFoundStringWithString:item];
        
        [self hideAutoCompleteView];
    }
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
