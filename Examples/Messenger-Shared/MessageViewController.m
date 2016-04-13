//
//  MessageViewController.m
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "MessageViewController.h"
#import "MessageTableViewCell.h"
#import "MessageTextView.h"
#import "TypingIndicatorView.h"
#import "Message.h"

#import <LoremIpsum/LoremIpsum.h>

#define DEBUG_CUSTOM_TYPING_INDICATOR 0

@interface MessageViewController ()

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *emojis;
@property (nonatomic, strong) NSArray *commands;

@property (nonatomic, strong) NSArray *searchResult;

@property (nonatomic, strong) UIWindow *pipWindow;

@property (nonatomic, weak) Message *editingMessage;

@end

@implementation MessageViewController

- (instancetype)init
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}

- (void)commonInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputbarDidMove:) name:SLKTextInputbarDidMoveNotification object:nil];
    
    // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
    [self registerClassForTextView:[MessageTextView class]];
    
#if DEBUG_CUSTOM_TYPING_INDICATOR
    // Register a UIView subclass, conforming to SLKTypingIndicatorProtocol, to use a custom typing indicator view.
    [self registerClassForTypingIndicatorView:[TypingIndicatorView class]];
#endif
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Example's configuration
    [self configureDataSource];
    [self configureActionItems];
    
    // SLKTVC's configuration
    self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = YES;
    
    [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
    [self.leftButton setTintColor:[UIColor grayColor]];
    
    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    
    self.textInputbar.autoHideRightButton = YES;
    self.textInputbar.maxCharCount = 256;
    self.textInputbar.counterStyle = SLKCounterStyleSplit;
    self.textInputbar.counterPosition = SLKCounterPositionTop;
    
    [self.textInputbar.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textInputbar.editorLeftButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    [self.textInputbar.editorRightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
#if !DEBUG_CUSTOM_TYPING_INDICATOR
    self.typingIndicatorView.canResignByTouch = YES;
#endif
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:MessengerCellIdentifier];
    
    [self.autoCompletionView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:AutoCompletionCellIdentifier];
    [self registerPrefixesForAutoCompletion:@[@"@", @"#", @":", @"+:", @"/"]];
    
    [self.textView registerMarkdownFormattingSymbol:@"*" withTitle:@"Bold"];
    [self.textView registerMarkdownFormattingSymbol:@"_" withTitle:@"Italics"];
    [self.textView registerMarkdownFormattingSymbol:@"~" withTitle:@"Strike"];
    [self.textView registerMarkdownFormattingSymbol:@"`" withTitle:@"Code"];
    [self.textView registerMarkdownFormattingSymbol:@"```" withTitle:@"Preformatted"];
    [self.textView registerMarkdownFormattingSymbol:@">" withTitle:@"Quote"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


#pragma mark - Example's Configuration

- (void)configureDataSource
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 100; i++) {
        NSInteger words = (arc4random() % 40)+1;
        
        Message *message = [Message new];
        message.username = [LoremIpsum name];
        message.text = [LoremIpsum wordsWithNumber:words];
        [array addObject:message];
    }
    
    NSArray *reversed = [[array reverseObjectEnumerator] allObjects];
    
    self.messages = [[NSMutableArray alloc] initWithArray:reversed];
    
    self.users = @[@"Allen", @"Anna", @"Alicia", @"Arnold", @"Armando", @"Antonio", @"Brad", @"Catalaya", @"Christoph", @"Emerson", @"Eric", @"Everyone", @"Steve"];
    self.channels = @[@"General", @"Random", @"iOS", @"Bugs", @"Sports", @"Android", @"UI", @"SSB"];
    self.emojis = @[@"-1", @"m", @"man", @"machine", @"block-a", @"block-b", @"bowtie", @"boar", @"boat", @"book", @"bookmark", @"neckbeard", @"metal", @"fu", @"feelsgood"];
    self.commands = @[@"msg", @"call", @"text", @"skype", @"kick", @"invite"];
}

- (void)configureActionItems
{
    UIBarButtonItem *arrowItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_arrow_down"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(hideOrShowTextInputbar:)];
    
    UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_editing"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(editRandomMessage:)];
    
    UIBarButtonItem *typeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_typing"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(simulateUserTyping:)];
    
    UIBarButtonItem *appendItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_append"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(fillWithText:)];
    
    UIBarButtonItem *pipItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icn_pic"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(togglePIPWindow:)];
    
    self.navigationItem.rightBarButtonItems = @[arrowItem, pipItem, editItem, appendItem, typeItem];
}


#pragma mark - Action Methods

- (void)hideOrShowTextInputbar:(id)sender
{
    BOOL hide = !self.textInputbarHidden;
    
    UIImage *image = hide ? [UIImage imageNamed:@"icn_arrow_up"] : [UIImage imageNamed:@"icn_arrow_down"];
    UIBarButtonItem *buttonItem = (UIBarButtonItem *)sender;
    
    [self setTextInputbarHidden:hide animated:YES];
    [buttonItem setImage:image];
}

- (void)fillWithText:(id)sender
{
    if (self.textView.text.length == 0)
    {
        int sentences = (arc4random() % 4);
        if (sentences <= 1) sentences = 1;
        self.textView.text = [LoremIpsum sentencesWithNumber:sentences];
    }
    else {
        [self.textView slk_insertTextAtCaretRange:[NSString stringWithFormat:@" %@", [LoremIpsum word]]];
    }
}

- (void)simulateUserTyping:(id)sender
{
    if ([self canShowTypingIndicator]) {
        
#if DEBUG_CUSTOM_TYPING_INDICATOR
        __block TypingIndicatorView *view = (TypingIndicatorView *)self.typingIndicatorProxyView;
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize imgSize = CGSizeMake(kTypingIndicatorViewAvatarHeight*scale, kTypingIndicatorViewAvatarHeight*scale);
        
        // This will cause the typing indicator to show after a delay ¯\_(ツ)_/¯
        [LoremIpsum asyncPlaceholderImageWithSize:imgSize
                                       completion:^(UIImage *image) {
                                           UIImage *thumbnail = [UIImage imageWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
                                           [view presentIndicatorWithName:[LoremIpsum name] image:thumbnail];
                                       }];
#else
        [self.typingIndicatorView insertUsername:[LoremIpsum name]];
#endif
    }
}

- (void)didLongPressCell:(UIGestureRecognizer *)gesture
{
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }

#ifdef __IPHONE_8_0
    if (SLK_IS_IOS8_AND_HIGHER && [UIAlertController class]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        alertController.popoverPresentationController.sourceView = gesture.view.superview;
        alertController.popoverPresentationController.sourceRect = gesture.view.frame;
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Edit Message" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self editCellMessage:gesture];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
        
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    }
    else {
        [self editCellMessage:gesture];
    }
#else
    [self editCellMessage:gesture];
#endif
}

- (void)editCellMessage:(UIGestureRecognizer *)gesture
{
    MessageTableViewCell *cell = (MessageTableViewCell *)gesture.view;
    
    self.editingMessage = self.messages[cell.indexPath.row];
    
    [self editText:self.editingMessage.text];
    
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
    if (self.textView.text.length > 0) {
        return;
    }
    
    NSInteger lastSectionIndex = [self.tableView numberOfSections]-1;
    NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex]-1;
    
    Message *lastMessage = [self.messages objectAtIndex:lastRowIndex];
    
    [self editText:lastMessage.text];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)togglePIPWindow:(id)sender
{
    if (!_pipWindow) {
        [self showPIPWindow:sender];
    }
    else {
        [self hidePIPWindow:sender];
    }
}

- (void)showPIPWindow:(id)sender
{
    CGRect frame = CGRectMake(CGRectGetWidth(self.view.frame) - 60.0, 0.0, 50.0, 50.0);
    frame.origin.y = CGRectGetMinY(self.textInputbar.frame) - 60.0;
    
    _pipWindow = [[UIWindow alloc] initWithFrame:frame];
    _pipWindow.backgroundColor = [UIColor blackColor];
    _pipWindow.layer.cornerRadius = 10.0;
    _pipWindow.layer.masksToBounds = YES;
    _pipWindow.hidden = NO;
    _pipWindow.alpha = 0.0;
    
    [[UIApplication sharedApplication].keyWindow addSubview:_pipWindow];
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _pipWindow.alpha = 1.0;
                     }];
}

- (void)hidePIPWindow:(id)sender
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         _pipWindow.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         _pipWindow.hidden = YES;
                         _pipWindow = nil;
                     }];
}

- (void)textInputbarDidMove:(NSNotification *)note
{
    if (!_pipWindow) {
        return;
    }
    
    CGRect frame = self.pipWindow.frame;
    frame.origin.y = [note.userInfo[@"origin"] CGPointValue].y - 60.0;
    
    self.pipWindow.frame = frame;
}


#pragma mark - Overriden Methods

- (BOOL)ignoreTextInputbarAdjustment
{
    return [super ignoreTextInputbarAdjustment];
}

- (BOOL)forceTextInputbarAdjustmentForResponder:(UIResponder *)responder
{
    if ([responder isKindOfClass:[UIAlertController class]]) {
        return YES;
    }
    
    // On iOS 9, returning YES helps keeping the input view visible when the keyboard if presented from another app when using multi-tasking on iPad.
    return SLK_IS_IPAD;
}

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status
{
    // Notifies the view controller that the keyboard changed status.
}

- (void)textWillUpdate
{
    // Notifies the view controller that the text will update.
    
    [super textWillUpdate];
}

- (void)textDidUpdate:(BOOL)animated
{
    // Notifies the view controller that the text did update.
    
    [super textDidUpdate:animated];
}

- (void)didPressLeftButton:(id)sender
{
    // Notifies the view controller when the left button's action has been triggered, manually.
    
    [super didPressLeftButton:sender];
}

- (void)didPressRightButton:(id)sender
{
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    
    Message *message = [Message new];
    message.username = [LoremIpsum name];
    message.text = [self.textView.text copy];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
    UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;
    
    [self.tableView beginUpdates];
    [self.messages insertObject:message atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
    [self.tableView endUpdates];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
    
    // Fixes the cell from blinking (because of the transform, when using translucent cells)
    // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [super didPressRightButton:sender];
}

- (void)didPressArrowKey:(UIKeyCommand *)keyCommand
{
    if ([keyCommand.input isEqualToString:UIKeyInputUpArrow] && self.textView.text.length == 0) {
        [self editLastMessage:nil];
    }
    else {
        [super didPressArrowKey:keyCommand];
    }
}

- (NSString *)keyForTextCaching
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)didPasteMediaContent:(NSDictionary *)userInfo
{
    // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
    [super didPasteMediaContent:userInfo];
    
    SLKPastableMediaType mediaType = [userInfo[SLKTextViewPastedItemMediaType] integerValue];
    NSString *contentType = userInfo[SLKTextViewPastedItemContentType];
    id data = userInfo[SLKTextViewPastedItemData];
    
    NSLog(@"%s : %@ (type = %ld) | data : %@",__FUNCTION__, contentType, (unsigned long)mediaType, data);
}

- (void)willRequestUndo
{
    // Notifies the view controller when a user did shake the device to undo the typed text
    
    [super willRequestUndo];
}

- (void)didCommitTextEditing:(id)sender
{
    // Notifies the view controller when tapped on the right "Accept" button for commiting the edited text
    self.editingMessage.text = [self.textView.text copy];
    
    [self.tableView reloadData];
    
    [super didCommitTextEditing:sender];
}

- (void)didCancelTextEditing:(id)sender
{
    // Notifies the view controller when tapped on the left "Cancel" button
    
    [super didCancelTextEditing:sender];
}

- (BOOL)canPressRightButton
{
    return [super canPressRightButton];
}

- (BOOL)canShowTypingIndicator
{
#if DEBUG_CUSTOM_TYPING_INDICATOR
    return YES;
#else
    return [super canShowTypingIndicator];
#endif
}

- (BOOL)shouldProcessTextForAutoCompletion:(NSString *)text
{
    return YES;
}

- (void)didChangeAutoCompletionPrefix:(NSString *)prefix andWord:(NSString *)word
{
    NSArray *array = nil;
    
    self.searchResult = nil;
    
    if ([prefix isEqualToString:@"@"]) {
        if (word.length > 0) {
            array = [self.users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
        else {
            array = self.users;
        }
    }
    else if ([prefix isEqualToString:@"#"] && word.length > 0) {
        array = [self.channels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
    }
    else if (([prefix isEqualToString:@":"] || [prefix isEqualToString:@"+:"]) && word.length > 1) {
        array = [self.emojis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
    }
    else if ([prefix isEqualToString:@"/"] && self.foundPrefixRange.location == 0) {
        if (word.length > 0) {
            array = [self.commands filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
        else {
            array = self.commands;
        }
    }
    
    if (array.count > 0) {
        array = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    self.searchResult = [[NSMutableArray alloc] initWithArray:array];
    
    BOOL show = (self.searchResult.count > 0);
    
    [self showAutoCompletionView:show];
}

- (CGFloat)heightForAutoCompletionView
{
    CGFloat cellHeight = [self.autoCompletionView.delegate tableView:self.autoCompletionView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cellHeight*self.searchResult.count;
}


#pragma mark - SLKTextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldOfferFormattingForSymbol:(NSString *)symbol
{
    if ([symbol isEqualToString:@">"]) {
        
        NSRange selection = textView.selectedRange;
        
        // The Quote formatting only applies new paragraphs
        if (selection.location == 0 && selection.length > 0) {
            return YES;
        }
        
        // or older paragraphs too
        NSString *prevString = [textView.text substringWithRange:NSMakeRange(selection.location-1, 1)];
        
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[prevString characterAtIndex:0]]) {
            return YES;
        }
        
        return NO;
    }
    
    return [super textView:textView shouldOfferFormattingForSymbol:symbol];
}

- (BOOL)textView:(SLKTextView *)textView shouldInsertSuffixForFormattingWithSymbol:(NSString *)symbol prefixRange:(NSRange)prefixRange
{
    if ([symbol isEqualToString:@">"]) {
        return NO;
    }
    
    return [super textView:textView shouldInsertSuffixForFormattingWithSymbol:symbol prefixRange:prefixRange];
}

#pragma mark - UITextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [super textView:textView shouldChangeTextInRange:range replacementText:text];
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
    
    if (cell.gestureRecognizers.count == 0) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressCell:)];
        [cell addGestureRecognizer:longPress];
    }
    
    Message *message = self.messages[indexPath.row];
    
    cell.titleLabel.text = message.username;
    cell.bodyLabel.text = message.text;
    
    cell.indexPath = indexPath;
    cell.usedForMessage = YES;
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform;
    
    return cell;
}

- (MessageTableViewCell *)autoCompletionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.autoCompletionView dequeueReusableCellWithIdentifier:AutoCompletionCellIdentifier];
    cell.indexPath = indexPath;
    
    NSString *text = self.searchResult[indexPath.row];
    
    if ([self.foundPrefix isEqualToString:@"#"]) {
        text = [NSString stringWithFormat:@"# %@", text];
    }
    else if (([self.foundPrefix isEqualToString:@":"] || [self.foundPrefix isEqualToString:@"+:"])) {
        text = [NSString stringWithFormat:@":%@:", text];
    }
    
    cell.titleLabel.text = text;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        Message *message = self.messages[indexPath.row];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        
        CGFloat pointSize = [MessageTableViewCell defaultFontSize];
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:pointSize],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        CGFloat width = CGRectGetWidth(tableView.frame)-kMessageTableViewCellAvatarHeight;
        width -= 25.0;
        
        CGRect titleBounds = [message.username boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        CGRect bodyBounds = [message.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        if (message.text.length == 0) {
            return 0.0;
        }
        
        CGFloat height = CGRectGetHeight(titleBounds);
        height += CGRectGetHeight(bodyBounds);
        height += 40.0;
        
        if (height < kMessageTableViewCellMinimumHeight) {
            height = kMessageTableViewCellMinimumHeight;
        }
        
        return height;
    }
    else {
        return kMessageTableViewCellMinimumHeight;
    }
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.autoCompletionView]) {
        
        NSMutableString *item = [self.searchResult[indexPath.row] mutableCopy];
        
        if ([self.foundPrefix isEqualToString:@"@"] && self.foundPrefixRange.location == 0) {
            [item appendString:@":"];
        }
        else if (([self.foundPrefix isEqualToString:@":"] || [self.foundPrefix isEqualToString:@"+:"])) {
            [item appendString:@":"];
        }
        
        [item appendString:@" "];
        
        [self acceptAutoCompletionWithString:item keepPrefix:YES];
    }
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
    [super scrollViewDidScroll:scrollView];
}



#pragma mark - Lifeterm

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
