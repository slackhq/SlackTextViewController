//
//  MessageViewController.m
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "MessageViewController.h"
#import "MessageTableViewCell.h"

#import <LoremIpsum/LoremIpsum.h>

static NSString *MessengerCellIdentifier = @"MessengerCell";
static NSString *AutoCompletionCellIdentifier = @"AutoCompletionCell";

@interface MessageViewController ()

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *emojis;

@property (nonatomic, strong) NSArray *searchResult;

@end

@implementation MessageViewController

- (id)init
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        
        self.users = @[@"Anna", @"Alicia", @"Arnold", @"Armando", @"Antonio", @"Brad", @"Catalaya", @"Christoph", @"Emerson", @"Eric", @"Everyone"];
        self.channels = @[@"General", @"Random", @"iOS", @"Bugs", @"Sports", @"Android", @"UI", @"SSB"];
        self.emojis = @[@"m", @"man", @"machine", @"block-a", @"block-b", @"bowtie", @"boar", @"boat", @"book", @"bookmark", @"neckbeard", @"metal", @"fu", @"feelsgood"];

        UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_editing"] style:UIBarButtonItemStylePlain target:self action:@selector(editRandomMessage:)];
        
        UIBarButtonItem *typeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_typing"] style:UIBarButtonItemStylePlain target:self action:@selector(simulateUserTyping:)];
        UIBarButtonItem *appendItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_append"] style:UIBarButtonItemStylePlain target:self action:@selector(fillWithText:)];
        
        self.navigationItem.rightBarButtonItems = @[editItem, appendItem, typeItem];
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
    [self.tableView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:MessengerCellIdentifier];
    [self.autoCompletionView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:AutoCompletionCellIdentifier];

    self.textInputbar.autoHideRightButton = YES;
    self.typingIndicatorView.canResignByTouch = YES;

    self.textView.placeholder = NSLocalizedString(@"Message", nil);
    self.textView.placeholderColor = [UIColor lightGrayColor];
    self.textInputbar.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:240.0/255.0 alpha:1.0];
    self.textView.layer.borderColor = [UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1.0].CGColor;
    
    [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];

    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    
    [self.textInputbar.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textInputbar.editortLeftButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    [self.textInputbar.editortRightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
    [self registerPrefixesForAutoCompletion:@[@"@", @"#", @":"]];
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
        [self.typingIndicatorView insertUsername:[LoremIpsum name]];
    }
}

- (void)editCellMessage:(UIGestureRecognizer *)gesture
{
    MessageTableViewCell *cell = (MessageTableViewCell *)gesture.view;
    NSString *message = self.messages[cell.indexPath.row];
    
    [self editText:message];
    
    [self.tableView scrollToRowAtIndexPath:cell.indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
    NSLog(@"%s",__FUNCTION__);
    
    [super didPressLeftButton:sender];
}

- (void)didPressRightButton:(id)sender
{
    NSLog(@"%s",__FUNCTION__);
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    
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
    
    NSLog(@"%s",__FUNCTION__);
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
    return [super canPressRightButton];
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
            array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
    }
    else if ([prefix isEqualToString:@"#"])
    {
        array = self.channels;
        if (word.length > 0) {
            array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
    }
    else if ([prefix isEqualToString:@":"] && word.length > 0) {
        array = [self.emojis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
    }
    
    if (array.count > 0) {
        array = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    self.searchResult = [[NSMutableArray alloc] initWithArray:array];
    
    return self.searchResult.count > 0;
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
        return [self messageCellForRowAtIndexPath:indexPath];
    }
    else {
        return [self autoCompletionCellForRowAtIndexPath:indexPath];
    }
}

- (MessageTableViewCell *)messageCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:MessengerCellIdentifier];
    
    if (!cell.textLabel.text) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(editCellMessage:)];
        [cell addGestureRecognizer:longPress];
    }
    
    NSString *message = self.messages[indexPath.row];
    cell.textLabel.text = message;
    cell.indexPath = indexPath;
    cell.topAligned = YES;

    if (cell.needsPlaceholder)
    {
        cell.needsPlaceholder = NO;
        
        CGFloat scale = [UIScreen mainScreen].scale;
        
        if ([[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)]) {
            scale = [UIScreen mainScreen].nativeScale;
        }
        
        CGSize imgSize = CGSizeMake(kAvatarSize*scale, kAvatarSize*scale);
        
        [LoremIpsum asyncPlaceholderImageWithSize:imgSize
                                       completion:^(UIImage *image) {
                                           image = [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
                                           cell.imageView.image = image;
                                       }];
    }
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform;
    
    return cell;
}

- (MessageTableViewCell *)autoCompletionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.autoCompletionView dequeueReusableCellWithIdentifier:AutoCompletionCellIdentifier];
    cell.indexPath = indexPath;
    
    NSString *item = self.searchResult[indexPath.row];
    
    if ([self.foundPrefix isEqualToString:@"#"]) {
        item = [NSString stringWithFormat:@"# %@", item];
    }
    else if ([self.foundPrefix isEqualToString:@":"]) {
        item = [NSString stringWithFormat:@":%@:", item];
    }
    
    cell.textLabel.text = item;
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.numberOfLines = 1;
    
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
        
        CGFloat width = CGRectGetWidth(tableView.frame)-(kAvatarSize*2.0+10);
        
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

@end
