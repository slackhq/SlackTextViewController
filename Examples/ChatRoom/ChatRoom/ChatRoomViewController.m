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

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *commands;
@property (nonatomic, strong) NSArray *emojis;

@property (nonatomic, strong) SearchResult *searchResult;

@end

@implementation ChatRoomViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.users = @[@"ignacio", @"michael", @"brady", @"everyone", @"channel", @"ali"];
        self.channels = @[@"general", @"ios", @"random", @"ssb", @"mobile", @"ui", @"released", @"SF"];
        self.commands = @[@"help", @"away", @"close", @"color", @"colors", @"feedback", @"invite", @"me", @"msg", @"dm", @"open"];
        self.emojis = @[@"bowtie", @"boar", @"boat", @"book", @"bookmark", @"neckbeard", @"metal", @"fu", @"feelsgood"];
        
        UIBarButtonItem *reachItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_network"] style:UIBarButtonItemStylePlain target:self action:@selector(simulateReachability:)];
        UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_editing"] style:UIBarButtonItemStylePlain target:self action:@selector(editRandomMessage:)];
        
        UIBarButtonItem *typeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_typing"] style:UIBarButtonItemStylePlain target:self action:@selector(simulateUserTyping:)];
        UIBarButtonItem *appendItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_append"] style:UIBarButtonItemStylePlain target:self action:@selector(fillWithText:)];
        
        self.navigationItem.leftBarButtonItems = @[reachItem, editItem];
        self.navigationItem.rightBarButtonItems = @[appendItem, typeItem];
        
        self.reachable = YES;
        
        self.edgesForExtendedLayout = UIRectEdgeNone; //UIRectEdgeAll
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.messages = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 40; i++) {
        [self.messages addObject:[NSString stringWithFormat:@"Dummy message #%d", i+1]];
    }
    
    self.bounces = NO;
    self.allowUndo = YES;
//    self.allowKeyboardPanning = NO;
    
    self.textContainerView.autoHideRightButton = YES;
    
    self.textView.placeholder = NSLocalizedString(@"Message", nil);
    self.textView.placeholderColor = [UIColor lightGrayColor];
    self.textContainerView.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
    self.textView.layer.borderColor = [UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1.0].CGColor;

    //    [self.leftButton setTintColor:[UIColor colorWithRed:154.0/255.0 green:159.0/255.0 blue:166.0/255.0 alpha:1.0]];
    [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];

    //    [self.rightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:136.0/255.0 blue:204.0/255.0 alpha:1.0]];
    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    
    [self.textContainerView.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textContainerView.editortLeftButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    [self.textContainerView.editortRightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
    [self registerKeysForAutoCompletion:@[@"@", @"#", @"/", @":"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - Action Methods

- (void)fillWithText:(id)sender
{
    if (self.textView.text.length == 0) {
        self.textView.text = [LoremIpsum sentencesWithNumber:4];
    }
    else {
        [self.textView insertTextAtCaretRange:[LoremIpsum word]];
    }
}

- (void)simulateUserTyping:(id)sender
{
    if (!self.isEditing && !self.isAutoCompleting) {
        [self.typeIndicatorView insertUsername:@"Ignacio"];
    }
}

- (void)simulateReachability:(id)sender
{
    _reachable = !self.isReachable;
    
    [self didChangeReachability];
}

- (void)editRandomMessage:(id)sender
{
    int sentences = (arc4random() % 10);
    if (sentences <= 1) sentences = 1;
    
    [self editText:[LoremIpsum sentencesWithNumber:sentences]];
}

- (void)editLastMessage:(id)sender
{
    NSString *lastMessage = [self.messages lastObject];
    [self editText:lastMessage];
    
    [self.tableView scrollToBottomAnimated:YES];
}

- (void)didSaveLastMessageEditing:(id)sender
{
    NSString *message = [self.textView.text copy];
    
    [self.messages removeLastObject];
    [self.messages addObject:message];
    
    [self.tableView reloadData];
}


#pragma mark - Extension

- (void)didChangeReachability
{
    NSString *placeholder = self.isReachable ? NSLocalizedString(@"Message", nil) : NSLocalizedString(@"Connecting...", nil);
    UIColor *textViewColor = self.isReachable ? [UIColor whiteColor] : [UIColor colorWithRed:253/255.0 green:240/255.0 blue:195/255.0 alpha:1.0];
    
    self.textView.placeholder = placeholder;
    self.textView.backgroundColor = textViewColor;
    
    self.rightButton.enabled = self.isReachable;
    self.textContainerView.editortRightButton.enabled = self.isReachable;
}


#pragma mark - Overriden Methods

- (void)textWillUpdate
{
    [super textWillUpdate];
    
    // Useful to sending a pong message to notify that the user is typing...
}

- (void)textDidUpdate:(BOOL)animated
{
    [super textDidUpdate:animated];
    
    // Useful to sending a pong message to notify that the user is typing...
}

- (void)didPressLeftButton:(id)sender
{
    [super didPressLeftButton:sender];
}

- (void)didPressRightButton:(id)sender
{
    [self.messages addObject:self.textView.text];
    [self.tableView reloadData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView scrollToBottomAnimated:YES];
    });
    
    [super didPressRightButton:sender];
}

- (void)didPasteImage:(UIImage *)image
{
    // Useful for sending an image
}

- (void)willRequestUndo
{
    [super willRequestUndo];
}

- (void)didCommitTextEditing:(id)sender
{
    NSString *message = [self.textView.text copy];
    
    [self.messages removeLastObject];
    [self.messages addObject:message];
    
    [self.tableView reloadData];
    
    [super didCommitTextEditing:sender];
}

- (void)didCancelTextEditing:(id)sender
{
    [super didCancelTextEditing:sender];
}

- (BOOL)canPressRightButton
{
    return self.isReachable && [super canPressRightButton];
}

- (BOOL)canShowAutoCompletion
{
    NSArray *array = nil;
    NSString *key = self.detectedKey;
    NSString *string = self.detectedWord;
    
    self.searchResult = [SearchResult new];
    self.searchResult.key = key;
    
    if ([key isEqualToString:@"@"]) {
        array = self.users;
    }
    else if ([key isEqualToString:@"#"]) {
        array = self.channels;
    }
    else if ([key isEqualToString:@"/"]) {
        array = self.commands;
    }
    else if ([key isEqualToString:@":"]) {
        if (string.length >= 2) {
            array = self.emojis;
        }
    }
    
    if (array.count == 0) {
        self.searchResult.list = nil;
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

- (CGFloat)heightForAutoCompletionView
{
    CGFloat cellHeight = [self.autoCompletionView.delegate tableView:self.autoCompletionView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cellHeight*self.searchResult.list.count;
}

- (NSArray *)keyCommands
{
    NSMutableArray *commands = [NSMutableArray arrayWithArray:[super keyCommands]];
    
    // Edit last message
    [commands addObject:[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                           modifierFlags:0
                                                   action:@selector(editLastMessage:)]];
    
    return commands;
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.tableView]) {
        return self.messages.count;
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
        
        NSString *message = self.messages[indexPath.row];
        cell.textLabel.text = message;
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
        cell.textLabel.numberOfLines = 0;
    }
    else {
        cell.backgroundColor = [UIColor whiteColor];
        
        NSString *sign = self.searchResult.key;
        NSString *item = self.searchResult.list[indexPath.row];

        if ([sign isEqualToString:@"#"]) {
            item = [NSString stringWithFormat:@"# %@", item];
        }
        else if ([sign isEqualToString:@":"]) {
            item = [NSString stringWithFormat:@":%@:", item];
        }
        
        cell.textLabel.text = item;
        cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        NSString *message = self.messages[indexPath.row];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        CGRect bounds = [message boundingRectWithSize:CGSizeMake(CGRectGetWidth(tableView.frame)-40.0, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        if (message.length == 0) {
            return 0.0;
        }
        
        return CGRectGetHeight(bounds)+20.0;
    }
    else {
        return 40.0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.autoCompletionView]) {
        UIView *topView = [UIView new];
        topView.backgroundColor = self.autoCompletionView.separatorColor;
        return topView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.autoCompletionView]) {
        return 0.5;
    }
    return 0.0;
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.autoCompletionView]) {
        
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
        
        [self acceptAutoCompletionWithString:item];
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
