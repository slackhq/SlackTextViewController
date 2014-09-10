//
//  ChatRoomViewController.m
//  ChatRoom
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "ChatRoomViewController.h"
#import "ChatViewCell.h"

#import <LoremIpsum/LoremIpsum.h>

static NSString *chatCellIdentifier = @"ChatCell";
static NSString *autoCompletionCellIdentifier = @"AutoCompletionCell";

@interface ChatRoomViewController ()
@property (nonatomic, getter = isReachable) BOOL reachable;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *commands;
@property (nonatomic, strong) NSArray *emojis;

@property (nonatomic, strong) NSArray *searchResult;

@end

@implementation ChatRoomViewController

- (id)init
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        self.users = @[@"ignacio", @"michael", @"brady", @"everyone", @"channel", @"ali"];
        self.channels = @[@"general", @"ios", @"random", @"ssb", @"mobile", @"ui", @"released", @"SF"];
        self.emojis = @[@"m", @"man", @"machine", @"block-a", @"block-b", @"bowtie", @"boar", @"boat", @"book", @"bookmark", @"neckbeard", @"metal", @"fu", @"feelsgood"];
        self.commands = @[@"help", @"away", @"close", @"color", @"colors", @"feedback", @"invite", @"me", @"msg", @"dm", @"open"];

        UIBarButtonItem *reachItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_network"] style:UIBarButtonItemStylePlain target:self action:@selector(simulateReachability:)];
        UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_editing"] style:UIBarButtonItemStylePlain target:self action:@selector(editRandomMessage:)];
        
        UIBarButtonItem *typeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_typing"] style:UIBarButtonItemStylePlain target:self action:@selector(simulateUserTyping:)];
        UIBarButtonItem *appendItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_append"] style:UIBarButtonItemStylePlain target:self action:@selector(fillWithText:)];
        
        self.navigationItem.leftBarButtonItems = @[reachItem, editItem];
        self.navigationItem.rightBarButtonItems = @[appendItem, typeItem];
        
        self.reachable = YES;
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 40; i++) {
        NSInteger words = (arc4random() % 15)+1;
        [array addObject:[LoremIpsum wordsWithNumber:words]];
    }
    
    NSArray *reversed = [[array reverseObjectEnumerator] allObjects];
    
    self.messages = [[NSMutableArray alloc] initWithArray:reversed];
    
    self.bounces = YES;
    self.undoShakingEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.inverted = YES;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[ChatViewCell class] forCellReuseIdentifier:chatCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:autoCompletionCellIdentifier];
    
    self.textContainerView.autoHideRightButton = YES;
    
    self.textView.placeholder = NSLocalizedString(@"Message", nil);
    self.textView.placeholderColor = [UIColor lightGrayColor];
    self.textContainerView.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
    self.textView.layer.borderColor = [UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1.0].CGColor;

    [self.leftButton setTintColor:[UIColor colorWithRed:154.0/255.0 green:159.0/255.0 blue:166.0/255.0 alpha:1.0]];
    [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];

    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    
    [self.textContainerView.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textContainerView.editortLeftButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    [self.textContainerView.editortRightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
    [self registerPrefixesForAutoCompletion:@[@"@", @"#", @"/", @":"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - Action Methods

- (void)fillWithText:(id)sender
{
    if (self.textView.text.length == 0)
    {
        int sentences = (arc4random() % 4);
        if (sentences <= 1) sentences = 1;
        self.textView.text = [LoremIpsum sentencesWithNumber:sentences];
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
    NSString *lastMessage = [self.messages firstObject];
    [self editText:lastMessage];
    
    [self.tableView scrollToTopAnimated:YES];
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
    
    // Useful for notifying when user will type some text
}

- (void)textDidUpdate:(BOOL)animated
{
    [super textDidUpdate:animated];
    
    // Useful for notifying when user did type some text
}

- (void)didPressLeftButton:(id)sender
{
    [super didPressLeftButton:sender];
}

- (void)didPressRightButton:(id)sender
{
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button (in iOS7)
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
        [self.textView becomeFirstResponder];
    }
    
    NSString *message = [self.textView.text copy];
    
    [self.tableView beginUpdates];
    [self.messages insertObject:message atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
    
    [self.tableView scrollToTopAnimated:YES];
    
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
    
    [self.messages removeObjectAtIndex:0];
    [self.messages insertObject:message atIndex:0];
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
    NSString *prefix = self.foundPrefix;
    NSString *word = self.foundWord;
    
    self.searchResult = nil;
    
    if ([prefix isEqualToString:@"@"])
    {
        array = self.users;
        
        if (word.length > 0) {
            array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@ AND self != %@", word, word]];
        }
        
        // Ignores 'me'
        NSString *me = [self.users firstObject];
        array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self != %@", me]];
    }
    else if ([prefix isEqualToString:@"#"])
    {
        array = self.channels;
        if (word.length > 0) {
            array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@ AND self != %@", word, word]];
        }
    }
    else if ([prefix isEqualToString:@"/"])
    {
        array = self.commands;
        if (word.length > 0) {
            array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@ AND self != %@", word, word]];
        }
    }
    else if ([prefix isEqualToString:@":"] && word.length > 0) {
        array = [self.emojis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@ AND NOT (self CONTAINS[cd] %@)", word, prefix]];
    }
    
    if (array.count > 0) {
        array = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    self.searchResult = [[NSMutableArray alloc] initWithArray:array];
    
    return array.count > 0;
}

- (CGFloat)heightForAutoCompletionView
{
    CGFloat cellHeight = [self.autoCompletionView.delegate tableView:self.autoCompletionView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cellHeight*self.searchResult.count;
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
        return self.searchResult.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        return [self chatCellForRowAtIndexPath:indexPath];
    }
    else {
        return [self autoCompletionCellForRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)chatCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatViewCell *cell = (ChatViewCell *)[self.tableView dequeueReusableCellWithIdentifier:chatCellIdentifier];
    
    NSString *message = self.messages[indexPath.row];
    cell.textLabel.text = message;

    if (cell.hasPlaceholder)
    {
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize imgSize = CGSizeMake(kAvatarSize*scale, kAvatarSize*scale);
        
        [LoremIpsum asyncPlaceholderImageWithSize:imgSize
                                       completion:^(UIImage *image) {
                                           image = [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
                                           cell.imageView.image = image;
                                           cell.hasPlaceholder = NO;
                                       }];
    }
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform;
    
    return cell;
}

- (UITableViewCell *)autoCompletionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:autoCompletionCellIdentifier];
    
    NSString *item = self.searchResult[indexPath.row];
    
    if ([self.foundPrefix isEqualToString:@"#"]) {
        item = [NSString stringWithFormat:@"# %@", item];
    }
    else if ([self.foundPrefix isEqualToString:@":"]) {
        item = [NSString stringWithFormat:@":%@:", item];
    }
    
    cell.textLabel.text = item;
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    cell.textLabel.numberOfLines = 1;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
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
        
        CGFloat width = CGRectGetWidth(tableView.frame)-(kAvatarSize*1.5);
        
        CGRect bounds = [message boundingRectWithSize:CGSizeMake(width, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        if (message.length == 0) {
            return 0.0;
        }
        
        CGFloat height = roundf(CGRectGetHeight(bounds)+kAvatarSize);
        
        if (height < kMinimumHeight) {
            height = kMinimumHeight;
        }
        
        return height;
    }
    else {
        return kMinimumHeight;
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
        
        NSMutableString *item = [self.searchResult[indexPath.row] mutableCopy];
        
        if ([self.foundPrefix isEqualToString:@"@"] || [self.foundPrefix isEqualToString:@":"]) {
            [item appendString:@":"];
        }
        
        [item appendString:@" "];
        
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
