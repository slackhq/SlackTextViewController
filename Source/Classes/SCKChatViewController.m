//
//  SCKChatViewController.m
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SCKChatViewController.h"
#import "UIView+ChatKitAdditions.h"

@interface SCKChatViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
    CGFloat minYOffset;
}

@property (nonatomic, strong) UIGestureRecognizer *singleTapGesture;

@property (nonatomic, strong) NSLayoutConstraint *tableViewHC;
@property (nonatomic, strong) NSLayoutConstraint *containerViewHC;
@property (nonatomic, strong) NSLayoutConstraint *typeIndicatorViewHC;
@property (nonatomic, strong) NSLayoutConstraint *autoCompletionViewHC;
@property (nonatomic, strong) NSLayoutConstraint *keyboardHC;

// Used for auto-completion
@property (nonatomic, strong) NSMutableArray *keysLookupList;
@property (nonatomic) NSRange detectedKeyRange;

@end

@implementation SCKChatViewController
@synthesize tableView = _tableView;
@synthesize typeIndicatorView = _typeIndicatorView;
@synthesize textContainerView = _textContainerView;
@synthesize autoCompletionView = _autoCompletionView;

#pragma mark - Initializer

- (instancetype)init
{
    if (self = [super init])
    {
        self.bounces = NO;
        self.allowUndo = NO;
        
        [self.view addSubview:self.tableView];
        [self.view addSubview:self.autoCompletionView];
        [self.view addSubview:self.typeIndicatorView];
        [self.view addSubview:self.textContainerView];

        [self setupViewConstraints];
        
        [self registerNotifications];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // We save the minimum offset of the tableView
    minYOffset = self.tableView.contentOffset.y;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


#pragma mark - Getters

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [UITableView new];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.scrollsToTop = YES;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        _tableView.tableFooterView = [UIView new];

        _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTableView)];
        _singleTapGesture.delegate = self;
        [_tableView addGestureRecognizer:self.singleTapGesture];
    }
    return _tableView;
}

- (UITableView *)autoCompletionView
{
    if (!_autoCompletionView)
    {
        _autoCompletionView = [UITableView new];
        _autoCompletionView.translatesAutoresizingMaskIntoConstraints = NO;
        _autoCompletionView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
        _autoCompletionView.dataSource = self;
        _autoCompletionView.delegate = self;
        
        _autoCompletionView.tableFooterView = [UIView new];
    }
    return _autoCompletionView;
}

- (SCKTextContainerView *)textContainerView
{
    if (!_textContainerView)
    {
        _textContainerView = [SCKTextContainerView new];
        _textContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        _textContainerView.bounces = self.bounces;
        
        [_textContainerView.leftButton addTarget:self action:@selector(didPressLeftButton:) forControlEvents:UIControlEventTouchUpInside];
        [_textContainerView.rightButton addTarget:self action:@selector(didPressRightButton:) forControlEvents:UIControlEventTouchUpInside];
        [_textContainerView.editortLeftButton addTarget:self action:@selector(didCancelTextEditing:) forControlEvents:UIControlEventTouchUpInside];
        [_textContainerView.editortRightButton addTarget:self action:@selector(didCommitTextEditing:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _textContainerView;
}

- (SCKTypeIndicatorView *)typeIndicatorView
{
    if (!_typeIndicatorView)
    {
        _typeIndicatorView = [SCKTypeIndicatorView new];
        _typeIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        _typeIndicatorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    }
    return _typeIndicatorView;
}

- (BOOL)isAutoCompleting
{
    return self.autoCompletionViewHC.constant > 0 ? YES : NO;
}

- (BOOL)isEditing
{
    return self.textContainerView.isEditing;
}

- (SCKTextView *)textView
{
    return self.textContainerView.textView;
}

- (UIButton *)leftButton
{
    return self.textContainerView.leftButton;
}

- (UIButton *)rightButton
{
    return self.textContainerView.rightButton;
}

- (CGFloat)appropriateContainerViewHeight
{
    CGFloat delta = self.textView.intrinsicContentSize.height-self.textView.font.lineHeight;
    CGFloat height = delta;
    
    if (self.textView.numberOfLines == 1) {
        height = self.textContainerView.minHeight;
    }
    else if (self.textView.numberOfLines < self.textView.maxNumberOfLines) {
        height += roundf(self.textView.font.lineHeight*self.textView.numberOfLines);
        height += (kTextViewVerticalPadding*2.0);
    }
    else {
        height += roundf(self.textView.font.lineHeight*self.textView.maxNumberOfLines);
        height += (kTextViewVerticalPadding*2.0);
    }
    
    if (height < self.textContainerView.minHeight) {
        height = self.textContainerView.minHeight;
    }
    
    if (self.isEditing) {
        height += kEditingViewHeight;
    }
    
    return roundf(height);
}


#pragma mark - Setters

- (void)setbounces:(BOOL)bounces
{
    _bounces = bounces;
    _textContainerView.bounces = self.bounces;
}


#pragma mark - Subclassable Methods

- (BOOL)canShowAutoCompletion
{
    return NO;
}

- (CGFloat)heightForAutoCompletionView
{
    return 0.0;
}

- (CGFloat)maximumHeightForAutoCompletionView
{
    return 140.0;
}

- (BOOL)canPressRightButton
{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return text.length > 0 ? YES : NO;
}

- (void)presentKeyboard:(BOOL)animated
{
    if (![self.textView isFirstResponder])
    {
        if (!animated)
        {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.0];
            [UIView setAnimationDelay:0.0];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            
            [self.textView becomeFirstResponder];
            
            [UIView commitAnimations];
        }
        else {
            [self.textView becomeFirstResponder];
        }
    }
}

- (void)dismissKeyboard:(BOOL)animated
{
    if ([self.textView isFirstResponder])
    {
        if (!animated)
        {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.0];
            [UIView setAnimationDelay:0.0];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            
            [self.textView resignFirstResponder];
            
            [UIView commitAnimations];
        }
        else {
            [self.textView resignFirstResponder];
        }
    }
}

- (void)textWillUpdate
{
    // No implementation here. Meant to be overriden in subclass.
}

- (CGFloat)tableHeight
{
    CGFloat height = self.view.bounds.size.height;
    height -= self.keyboardHC.constant;
    height -= self.containerViewHC.constant;
    height -= self.autoCompletionViewHC.constant;
    height -= self.typeIndicatorViewHC.constant;
    
    if (height < 0) return 0;
    else return roundf(height);
}

- (void)textDidUpdate:(BOOL)animated
{
    self.textContainerView.rightButton.enabled = [self canPressRightButton];
    self.textContainerView.editortRightButton.enabled = [self canPressRightButton];

    CGFloat containeHeight = [self appropriateContainerViewHeight];
    
    if (containeHeight != self.containerViewHC.constant)
    {
        CGFloat offsetDelta = roundf(self.containerViewHC.constant-containeHeight);
        CGFloat offsetY = self.tableView.contentOffset.y-offsetDelta;
        
        self.containerViewHC.constant = containeHeight;
        self.tableViewHC.constant = [self tableHeight];
        
        BOOL scroll = [self.tableView canScrollToBottom];
        
        if (animated) {
            [self.view animateLayoutIfNeededWithBounce:self.bounces
                                                 curve:UIViewAnimationOptionCurveEaseInOut
                                            animations:^{
                                                
                                                if (self.isEditing) {
                                                    [self.textView scrollToCaretPositonAnimated:NO];
                                                }
                                                
                                                if (scroll && offsetY >= 0) {
                                                    [self.tableView setContentOffset:CGPointMake(0.0, offsetY)];
                                                }
                                            }];
        }
        else {
            [self.view layoutIfNeeded];
            
            if (scroll && offsetY >= 0) {
                [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:animated];
            }
        }
    }
}

- (void)didPressLeftButton:(id)sender
{
    // No implementation here. Meant to be overriden in subclass.
}

- (void)didPressRightButton:(id)sender
{
    [self.textView setText:nil];
}

- (void)didPasteImage:(UIImage *)image
{
    // No implementation here. Meant to be overriden in subclass.
}

- (void)willRequestUndo
{
    UIAlertView *alert = [UIAlertView new];
    [alert setTitle:NSLocalizedString(@"Undo Typing", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Undo", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [alert setCancelButtonIndex:1];
    [alert setDelegate:self];
    [alert show];
}


#pragma mark - Private Actions

- (void)didTapTableView
{
    [self dismissKeyboard:YES];
}

- (void)editText:(NSString *)text
{
    if (![self.textContainerView canEditText:text]) {
        return;
    }
    
    [self.textContainerView beginTextEditing];
    
    [self.textView setText:text];
    
    [self.textView scrollToCaretPositonAnimated:NO];
    
    if (![self.textView isFirstResponder]) {
        [self presentKeyboard:YES];
    }
}

- (void)didCommitTextEditing:(id)sender
{
    if (!self.isEditing) {
        return;
    }
    
    [self didCancelTextEditing:sender];
}

- (void)didCancelTextEditing:(id)sender
{
    if (!self.isEditing) {
        return;
    }

    [self.textContainerView endTextEdition];

    [self.textView setText:nil];
}

- (void)shouldHitReturnKey:(id)sender
{
    if (self.isEditing) {
        [self didCommitTextEditing:sender];
        return;
    }
    
    [self performRightAction];
}

- (void)shouldHitEscapeKey:(id)sender
{
    if (self.isAutoCompleting) {
        [self cancelAutoCompletion];
        return;
    }
    
    if (self.isEditing) {
        [self didCancelTextEditing:sender];
        return;
    }
    
    [self dismissKeyboard:YES];
}

- (void)performRightAction
{
    NSArray *actions = [self.rightButton actionsForTarget:self forControlEvent:UIControlEventTouchUpInside];
    
    if (actions.count > 0 && [self canPressRightButton]) {
        [self.rightButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)insertNewLineBreak
{
    [self.textView insertNewLineBreak];
}


#pragma mark - Notification Events

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    endFrame = adjustEndFrame(endFrame, self.interfaceOrientation);
    
    if (!isKeyboardFrameValid(endFrame)) return;

    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect inputFrame = self.textContainerView.frame;
    inputFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(inputFrame);
    
    // Updates the height constraints' constants
    self.keyboardHC.constant = show ? endFrame.size.height : 0.0;
    self.tableViewHC.constant = [self tableHeight];
    
    CGFloat delta = CGRectGetHeight(endFrame);
    CGFloat offsetY = self.tableView.contentOffset.y+(show ? delta : -delta);
    
    CGFloat currentYOffset = self.tableView.contentOffset.y;
    CGFloat maxYOffset = self.tableView.contentSize.height-(CGRectGetHeight(self.view.frame)-CGRectGetHeight(inputFrame));
    
    BOOL scroll = (((!show && offsetY != currentYOffset && offsetY > (minYOffset-delta) && offsetY < (maxYOffset-delta+minYOffset)) || show) && [self.tableView canScrollToBottom]);
    
    if (!show && self.isAutoCompleting) {
        [self hideautoCompletionView];
    }
    
    // Only for this animation, we set bo to bounce since we want to give the impression that the text input is glued to the keyboard.
    [self.view animateLayoutIfNeededWithBounce:NO curve:curve animations:^{
        if (scroll && offsetY >= 0) {
            [self.tableView setContentOffset:CGPointMake(0, offsetY)];
        }
    }];
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    endFrame = adjustEndFrame(endFrame, self.interfaceOrientation);
    
    if (!isKeyboardFrameValid(endFrame)) return;
    
    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardDidShowNotification];
    
    // After showing keyboard, check if the current cursor position could diplay auto-completion
    if (show) {
        [self processTextForAutoCompletion];
    }
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
    if (self.keyboardHC.constant == 0) {
        return;
    }

    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect inputFrame = self.textContainerView.frame;
    
    inputFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(inputFrame);

    self.keyboardHC.constant = CGRectGetHeight(self.view.frame)-endFrame.origin.y;
    self.tableViewHC.constant = [self tableHeight];
    
    [self.view layoutIfNeeded];
}

- (void)willChangeTextView:(NSNotification *)notification
{
    SCKTextView *textView = (SCKTextView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    [self textWillUpdate];
}

- (void)didChangeTextViewText:(NSNotification *)notification
{
    SCKTextView *textView = (SCKTextView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    [self textDidUpdate:YES];
}

- (void)willShowOrHideTypeIndicatorView:(NSNotification *)notification
{
    SCKTypeIndicatorView *indicatorView = (SCKTypeIndicatorView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![indicatorView isEqual:self.typeIndicatorView]) {
        return;
    }
    
    if (self.isEditing || self.isAutoCompleting) {
        return;
    }
    
    self.typeIndicatorViewHC.constant = indicatorView.isVisible ? indicatorView.height : 0.0;
    self.tableViewHC.constant -= self.typeIndicatorViewHC.constant;
    
    CGFloat offsetDelta = indicatorView.isVisible ? indicatorView.height : -indicatorView.height;
    CGFloat offsetY = self.tableView.contentOffset.y+offsetDelta;
    
    BOOL scroll = [self.tableView canScrollToBottom];
    
    [self.view animateLayoutIfNeededWithBounce:self.bounces
                               curve:UIViewAnimationOptionCurveEaseInOut
                          animations:^{
                              if (scroll && offsetY >= 0) {
                                  [self.tableView setContentOffset:CGPointMake(0.0, offsetY)];
                              }
                          }];
}

- (void)didChangeTextViewContentSize:(NSNotification *)notification
{
//    NSString *text = self.textView.text;
//    
//    if (text.length > 0) {
//        NSString *lastString = [text substringWithRange:NSMakeRange(text.length-1, 1)];
//        
//        if ([lastString isEqualToString:@"\n"] || self.isEditing) {
//            [self textDidUpdate:YES];
//        }
//    }
    
    [self textDidUpdate:YES];
}

- (void)didChangeTextViewSelection:(NSNotification *)notification
{
    NSRange selectedRange = [notification.userInfo[@"range"] rangeValue];
    
    // Updates auto-completion if the caret is not selecting just re-positioning
    // The text view must be first responder too
    if (selectedRange.length == 0 && [self.textView isFirstResponder]) {
        [self processTextForAutoCompletion];
    }
}

- (void)didChangeTextViewPasteboard:(NSNotification *)notification
{
    UIImage *image = notification.object;
    
    // Notifies only if the pasted object is a valid UIImage instance
    if ([image isKindOfClass:[UIImage class]]) {
        [self didPasteImage:image];
    }
}

- (void)didShakeTextView:(NSNotification *)notification
{
    // Notifies of the shake gesture if undo mode is on and the text view is not empty
    if (self.allowUndo && self.textView.text.length > 0) {
        [self willRequestUndo];
    }
}


#pragma mark - Auto-Completion Text Processing

- (void)registerKeysForAutoCompletion:(NSArray *)keys
{
    // Creates the array if not exitent
    if (!self.keysLookupList) {
        self.keysLookupList = [[NSMutableArray alloc] initWithCapacity:keys.count];
    }
    
    for (NSString *key in keys) {
        // Skips if the key is not a valid string or longer than 1 letter
        if (![key isKindOfClass:[NSString class]] || key.length == 0 || key.length > 1) {
            continue;
        }
        
        // Adds the key if not contained already
        if (![self.keysLookupList containsObject:key]) {
            [self.keysLookupList addObject:key];
        }
    }
}

- (void)processTextForAutoCompletion
{
    // Avoids text processing for auto-completion if the key lookup list is empty.
    if (self.keysLookupList.count == 0) {
        return;
    }
    
    NSString *text = self.textView.text;
    
    // No need to process for auto-completion if there is no text to process
    if (text.length == 0) {
        [self cancelAutoCompletion];
        return;
    }

    NSRange range;
    NSString *word = [self.textView wordAtCaretRange:&range];
        
    for (NSString *sign in self.keysLookupList) {
        
        NSRange keyRange = [word rangeOfString:sign];
        
        if (keyRange.location == 0 || (keyRange.length == 1)) {
            self.detectedKey = sign;
            self.detectedKeyRange = NSMakeRange(range.location, sign.length);
        }
    }
    
    if (self.detectedKey.length > 0) {
        if (range.length == 0 || range.length != word.length) {
            [self cancelAutoCompletion];
        }
        
        if (word.length > 0) {
            self.detectedWord = [word stringByReplacingOccurrencesOfString:self.detectedKey withString:@""];
        }
        else {
            [self cancelAutoCompletion];
        }
    }

    BOOL canShow = [self canShowAutoCompletion];
    
    [self.autoCompletionView reloadData];
    
    [self showAutoCompletionView:canShow];
}

- (void)cancelAutoCompletion
{
    self.detectedKey = nil;
    self.detectedKeyRange = NSRangeFromString(nil);
    
    if (self.isAutoCompleting) {
        [self showAutoCompletionView:NO];
    }
}

- (void)acceptAutoCompletionWithString:(NSString *)string
{
    if (string.length == 0) {
        return;
    }
    
    NSString *word = nil;
    if (self.detectedKey.length > 0) {
        word = [self.detectedWord stringByReplacingOccurrencesOfString:self.detectedKey withString:@""];
    }
    
    SCKTextView *textView = self.textView;
    NSRange insertionRange = textView.selectedRange;
    
    if (word.length > 0) {
        NSRange range = [self.textView.text rangeOfString:word];
        insertionRange = [textView insertText:string inRange:range];
    }
    else {
        NSRange range = NSMakeRange(self.detectedKeyRange.location+1, 0.0);
        insertionRange = [textView insertText:string inRange:range];
    }
    
    textView.selectedRange = NSMakeRange(insertionRange.location, 0);
    
    [self cancelAutoCompletion];
}

- (void)hideautoCompletionView
{
    [self showAutoCompletionView:NO];
}

- (void)showAutoCompletionView:(BOOL)show
{
    CGFloat viewHeight = show ? [self heightForAutoCompletionView] : 0.0;
    
    if (self.autoCompletionViewHC.constant == viewHeight) {
        return;
    }
    
    // If the auto-completion view height is bigger than the maximum height allows, it is reduce to that size. Default 140 pts.
    if (viewHeight > [self maximumHeightForAutoCompletionView]) {
        viewHeight = [self maximumHeightForAutoCompletionView];
    }
    
    CGFloat tableHeight = self.tableViewHC.constant;
    
    // If the the view controller extends it layout beneath it navigation bar and/or status bar, we then reduce it from the table view height
    if (self.edgesForExtendedLayout == UIRectEdgeAll || self.edgesForExtendedLayout == UIRectEdgeTop) {
        tableHeight -= CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        tableHeight -= self.navigationController.navigationBar.frame.size.height;
    }

    // On iPhone, the auto-completion view can't extend beyond the table view height
    if (viewHeight > tableHeight) {
        viewHeight = tableHeight;
    }
    
    CGFloat offsetDelta = show ? viewHeight : -self.autoCompletionViewHC.constant;
    CGFloat offsetY = self.tableView.contentOffset.y+offsetDelta;
    
    self.autoCompletionViewHC.constant = viewHeight;
    
    BOOL scroll = [self.tableView canScrollToBottom];
    
    [self.view animateLayoutIfNeededWithBounce:self.bounces
                                         curve:UIViewAnimationOptionCurveEaseInOut
                                    animations:^{
                                        if (scroll && offsetY >= 0) {
                                            [self.tableView setContentOffset:CGPointMake(0.0, offsetY)];
                                        }
                                    }];
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.singleTapGesture isEqual:gestureRecognizer]) {
        return [self.textContainerView.textView isFirstResponder];
    }
    
    return YES;
}


#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != [alertView cancelButtonIndex] ) {
        [self.textView setText:nil];
    }
}


#pragma mark - NSNotificationCenter register/unregister

- (void)registerNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeyboardFrame:) name:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
    
    // TextView notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeTextView:) name:SCKTextViewTextWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewContentSize:) name:SCKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewSelection:) name:SCKTextViewSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewPasteboard:) name:SCKTextViewDidPasteImageNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShakeTextView:) name:SCKTextViewDidShakeNotification object:nil];

    
    // TypeIndicator notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideTypeIndicatorView:) name:SCKTypeIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideTypeIndicatorView:) name:SCKTypeIndicatorViewWillHideNotification object:nil];
}

- (void)unregisterNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
    // TextView notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTextViewTextWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTextViewDidPasteImageNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTextViewDidShakeNotification object:nil];

    // TypeIndicator notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTypeIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTypeIndicatorViewWillHideNotification object:nil];
}


#pragma mark - View Auto-Layout

- (void)setupViewConstraints
{
    // Removes all constraints
    [self.view removeConstraints:self.view.constraints];
    
    NSDictionary *views = @{@"tableView": self.tableView,
                            @"autoCompletionView": self.autoCompletionView,
                            @"typeIndicatorView": self.typeIndicatorView,
                            @"textContainerView": self.textContainerView,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView(==0@250)][autoCompletionView(0)][typeIndicatorView(0)][textContainerView(>=0)]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[autoCompletionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[typeIndicatorView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textContainerView]|" options:0 metrics:nil views:views]];

    NSArray *heightConstraints = [self.view constraintsForAttribute:NSLayoutAttributeHeight];
    NSArray *bottomConstraints = [self.view constraintsForAttribute:NSLayoutAttributeBottom];
    
    self.tableViewHC = heightConstraints[0];
    self.autoCompletionViewHC = heightConstraints[1];
    self.typeIndicatorViewHC = heightConstraints[2];
    self.containerViewHC = heightConstraints[3];
    self.keyboardHC = bottomConstraints[0];
    
    self.containerViewHC.constant = self.textContainerView.minHeight;
    self.tableViewHC.constant = [self tableHeight];
    
    if (self.isEditing) {
        self.containerViewHC.constant += kEditingViewHeight;
    }
    
    [self.view layoutIfNeeded];
}


#pragma mark - External Keyboard Support

- (NSArray *)keyCommands
{
    return @[
             // Pressing Return key
             [UIKeyCommand keyCommandWithInput:@"\r"
                                 modifierFlags:0
                                        action:@selector(shouldHitReturnKey:)],
             [UIKeyCommand keyCommandWithInput:@"\r"
                                 modifierFlags:UIKeyModifierShift
                                        action:@selector(insertNewLineBreak)],
             [UIKeyCommand keyCommandWithInput:@"\r"
                                 modifierFlags:UIKeyModifierAlternate
                                        action:@selector(insertNewLineBreak)],
             [UIKeyCommand keyCommandWithInput:@"\r"
                                 modifierFlags:UIKeyModifierControl
                                        action:@selector(insertNewLineBreak)],
             
             // Pressing Esc key
             [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                 modifierFlags:0
                                        action:@selector(shouldHitEscapeKey:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                 modifierFlags:UIKeyModifierShift
                                        action:@selector(shouldHitEscapeKey:)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                 modifierFlags:UIKeyModifierControl
                                        action:@selector(shouldHitEscapeKey:)],
             ];
}


#pragma mark - Convenience Methods

CGRect adjustEndFrame(CGRect endFrame, UIInterfaceOrientation orientation) {
    
    // Inverts the end rect for landscape orientation
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        endFrame = CGRectMake(0.0, endFrame.origin.x, endFrame.size.height, endFrame.size.width);
    }
    
    return endFrame;
}

BOOL isKeyboardFrameValid(CGRect frame) {
    if ((frame.origin.y > CGRectGetHeight([UIScreen mainScreen].bounds)) ||
        (frame.size.height < 1) || (frame.size.width < 1) || (frame.origin.y < 0)) {
        return NO;
    }
    return YES;
}


#pragma mark - View Auto-Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{

}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
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

- (void)dealloc
{
    [self unregisterNotifications];
}

@end
