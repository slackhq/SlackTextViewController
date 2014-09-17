//
//  SCKChatViewController.m
//  SlackChatKit
//  https://github.com/tinyspeck/slack-chat-kit
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//  Licence: MIT-Licence
//

#import "SCKChatViewController.h"

@interface SCKChatViewController () <UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
    CGPoint _draggingOffset;
}

// Used for Auto-Layout constraints, and update its constants
@property (nonatomic, strong) NSLayoutConstraint *scrollViewHC;
@property (nonatomic, strong) NSLayoutConstraint *chatToolbarHC;
@property (nonatomic, strong) NSLayoutConstraint *typeIndicatorViewHC;
@property (nonatomic, strong) NSLayoutConstraint *autoCompletionViewHC;
@property (nonatomic, strong) NSLayoutConstraint *keyboardHC;

@property (nonatomic, strong) UIGestureRecognizer *singleTapGesture;

@property (nonatomic, readonly, getter = isPanningKeyboard) BOOL panningKeyboard;

// Used for Auto-Completion
@property (nonatomic, readonly) NSRange foundPrefixRange;

@end

@implementation SCKChatViewController
@synthesize tableView = _tableView;
@synthesize collectionView = _collectionView;
@synthesize typeIndicatorView = _typeIndicatorView;
@synthesize chatToolbar = _chatToolbar;
@synthesize autoCompletionView = _autoCompletionView;
@synthesize autoCompleting = _autoCompleting;

#pragma mark - Initializer

- (instancetype)init
{
    return [self initWithTableViewStyle:UITableViewStylePlain];
}

- (instancetype)initWithTableViewStyle:(UITableViewStyle)style
{
    if (self = [super init]) {
        [self tableViewWithStyle:style];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    if (self = [super init]) {
        [self collectionViewWithLayout:layout];
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [self registerNotifications];
    
    self.bounces = YES;
    self.inverted = YES;
    self.undoShakingEnabled = NO;
    self.keyboardPanningEnabled = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.scrollViewProxy];
    [self.view addSubview:self.autoCompletionView];
    [self.view addSubview:self.typeIndicatorView];
    [self.view addSubview:self.chatToolbar];
    
    [self setupViewConstraints];
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.scrollViewProxy flashScrollIndicators];
}


#pragma mark - Getters

- (UITableView *)tableViewWithStyle:(UITableViewStyle)style
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:style];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.scrollsToTop = YES;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        _tableView.tableFooterView = [UIView new];

        _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapScrollView)];
        _singleTapGesture.delegate = self;
        [_tableView addGestureRecognizer:self.singleTapGesture];
    }
    return _tableView;
}

- (UICollectionView *)collectionViewWithLayout:(UICollectionViewLayout *)layout
{
    if (!_collectionView)
    {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.scrollsToTop = YES;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapScrollView)];
        _singleTapGesture.delegate = self;
        [_collectionView addGestureRecognizer:self.singleTapGesture];
    }
    return _collectionView;
}

- (UIScrollView *)scrollViewProxy
{
    if (_tableView) {
        return _tableView;
    }
    else if (_collectionView) {
        return _collectionView;
    }
    return nil;
}

- (UITableView *)autoCompletionView
{
    if (!_autoCompletionView)
    {
        _autoCompletionView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _autoCompletionView.translatesAutoresizingMaskIntoConstraints = NO;
        _autoCompletionView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        _autoCompletionView.scrollsToTop = NO;
        _autoCompletionView.dataSource = self;
        _autoCompletionView.delegate = self;
    }
    return _autoCompletionView;
}

- (SCKChatToolbar *)chatToolbar
{
    if (!_chatToolbar)
    {
        _chatToolbar = [SCKChatToolbar new];
        _chatToolbar.translatesAutoresizingMaskIntoConstraints = NO;
        _chatToolbar.controller = self;
        
        [_chatToolbar.leftButton addTarget:self action:@selector(didPressLeftButton:) forControlEvents:UIControlEventTouchUpInside];
        [_chatToolbar.rightButton addTarget:self action:@selector(didPressRightButton:) forControlEvents:UIControlEventTouchUpInside];
        [_chatToolbar.editortLeftButton addTarget:self action:@selector(didCancelTextEditing:) forControlEvents:UIControlEventTouchUpInside];
        [_chatToolbar.editortRightButton addTarget:self action:@selector(didCommitTextEditing:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chatToolbar;
}

- (SCKTypeIndicatorView *)typeIndicatorView
{
    if (!_typeIndicatorView)
    {
        _typeIndicatorView = [SCKTypeIndicatorView new];
        _typeIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        _typeIndicatorView.canResignByTouch = NO;
    }
    return _typeIndicatorView;
}

- (UIView *)inputAccessoryView
{
    if (_keyboardPanningEnabled) {
        
        static dispatch_once_t onceToken;
        static SCKInputAccessoryView *_inputAccessoryView = nil;
        
        dispatch_once(&onceToken, ^{
            _inputAccessoryView = [SCKInputAccessoryView new];
        });
        
        return _inputAccessoryView;
    }
    return nil;
}

- (BOOL)isEditing
{
    return self.chatToolbar.isEditing;
}

- (SCKTextView *)textView
{
    return self.chatToolbar.textView;
}

- (UIButton *)leftButton
{
    return self.chatToolbar.leftButton;
}

- (UIButton *)rightButton
{
    return self.chatToolbar.rightButton;
}

- (CGFloat)deltaToolbarHeight
{
    return self.textView.intrinsicContentSize.height-self.textView.font.lineHeight;
}

- (CGFloat)minimumToolbarHeight
{
    return self.chatToolbar.intrinsicContentSize.height;
}

- (CGFloat)maximumToolbarHeight
{
    CGFloat height = [self deltaToolbarHeight];
    
    height += roundf(self.textView.font.lineHeight*self.textView.maxNumberOfLines);
    height += (kTextViewVerticalPadding*2.0);
    
    return height;
}

- (CGFloat)currentToolbarHeight
{
    CGFloat height = [self deltaToolbarHeight];
    
    height += roundf(self.textView.font.lineHeight*self.textView.numberOfLines);
    height += (kTextViewVerticalPadding*2.0);
    
    return height;
}

- (CGFloat)appropriateToolbarHeight
{
    CGFloat height = 0.0;
    
    if (self.textView.numberOfLines == 1) {
        height = [self minimumToolbarHeight];
    }
    else if (self.textView.numberOfLines < self.textView.maxNumberOfLines) {
        height += [self currentToolbarHeight];
    }
    else {
        height += [self maximumToolbarHeight];
    }
    
    if (height < [self minimumToolbarHeight]) {
        height = [self minimumToolbarHeight];
    }
    
    if (self.isEditing) {
        height += kAccessoryViewHeight;
    }
    
    return roundf(height);
}

- (CGFloat)appropriateScrollViewHeight
{
    CGFloat height = self.view.bounds.size.height;

    height -= self.keyboardHC.constant;
    height -= self.chatToolbarHC.constant;
    height -= self.autoCompletionViewHC.constant;
    height -= self.typeIndicatorViewHC.constant;
    
    if (height < 0) return 0;
    else return roundf(height);
}


#pragma mark - Setters

- (void)setbounces:(BOOL)bounces
{
    _bounces = bounces;
}

- (void)setAutoCompleting:(BOOL)autoCompleting
{
    if (self.autoCompleting == autoCompleting) {
        return;
    }
    
    _autoCompleting = autoCompleting;
    
    self.scrollViewProxy.scrollEnabled = !autoCompleting;
}

- (void)setKeyboardPanningEnabled:(BOOL)enabled
{
    // Disable this feature until proper fix (might need to try another technique less hacky)
    return;
    
    if (self.keyboardPanningEnabled == enabled) {
        return;
    }
    
    // Disable this feature on iOS8
    if ([UIInputViewController class]) {
        return;
    }
    
    _keyboardPanningEnabled = enabled;
    
    if (enabled) {
        self.textView.inputAccessoryView = [self inputAccessoryView];
        self.scrollViewProxy.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeyboardFrame:) name:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    }
    else {
        self.textView.inputAccessoryView = nil;
        self.scrollViewProxy.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    }
}

- (void)setInverted:(BOOL)inverted
{
    if (self.isInverted == inverted) {
        return;
    }
    
    _inverted = inverted;
    
    self.scrollViewProxy.transform = CGAffineTransformMake(1, 0, 0, inverted ? -1 : 1, 0, 0);
    self.edgesForExtendedLayout = inverted ? UIRectEdgeNone : UIRectEdgeAll;
}


#pragma mark - Subclassable Methods

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

- (void)textDidUpdate:(BOOL)animated
{
    self.chatToolbar.rightButton.enabled = [self canPressRightButton];
    self.chatToolbar.editortRightButton.enabled = [self canPressRightButton];

    CGFloat toolbarHeight = [self appropriateToolbarHeight];
    
    if (toolbarHeight != self.chatToolbarHC.constant)
    {
        self.chatToolbarHC.constant = toolbarHeight;
        self.scrollViewHC.constant = [self appropriateScrollViewHeight];
        
        if (animated) {
            
            BOOL bounces = self.bounces && [self.textView isFirstResponder];
            
            [self.view animateLayoutIfNeededWithBounce:bounces
                                                 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                            animations:^{
                                                if (self.isEditing) {
                                                    [self.textView scrollToCaretPositonAnimated:NO];
                                                }
                                            }];
        }
        else {
            [self.view layoutIfNeeded];
        }
    }
}

- (BOOL)canPressRightButton
{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return text.length > 0 ? YES : NO;
}

- (void)didPressLeftButton:(id)sender
{
    // No implementation here. Meant to be overriden in subclass.
}

- (void)didPressRightButton:(id)sender
{
    [self.textView setText:nil];
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
    
    [self.chatToolbar endTextEdition];
    
    [self.textView setText:nil];
}

- (BOOL)canShowTypeIndicator
{
    // Don't show if the text is being edited or auto-completed.
    if (self.isEditing || self.isAutoCompleting) {
        return NO;
    }
    
    // Don't show if the content offset is not at top (when inverted) or at bottom (when not inverted)
    if ((self.isInverted && ![self.scrollViewProxy isAtTop]) || (!self.isInverted && ![self.scrollViewProxy isAtBottom])) {
        return NO;
    }
    
    return YES;
}

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

- (void)didPressReturnKey:(id)sender
{
    if (self.isEditing) {
        [self didCommitTextEditing:sender];
        return;
    }
    
    [self performRightAction];
}

- (void)didPressEscapeKey:(id)sender
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

- (void)didTapScrollView
{
    [self dismissKeyboard:YES];
}

- (void)editText:(NSString *)text
{
    if (![self.chatToolbar canEditText:text]) {
        return;
    }
    
    // Updates the constraints before inserting text, if not first responder yet
    if (![self.textView isFirstResponder]) {
        [self.chatToolbar beginTextEditing];
    }

    [self.textView setText:text];
    [self.textView scrollToCaretPositonAnimated:YES];
    
    // Updates the constraints after inserting text, if already first responder
    if ([self.textView isFirstResponder]) {
        [self.chatToolbar beginTextEditing];
    }
    
    if (![self.textView isFirstResponder]) {
        [self presentKeyboard:YES];
    }
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
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGFloat keyboardHeight = MIN(CGRectGetWidth(endFrame), CGRectGetHeight(endFrame));
    
    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    // Programatically stops scrolling before updating the view constraints (to avoid scrolling glitch)
    [self.scrollViewProxy stopScrolling];
    
    // Updates the height constraints' constants
    self.keyboardHC.constant = show ? keyboardHeight : 0.0;
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    if (!show && self.isAutoCompleting) {
        [self hideautoCompletionView];
    }
    
    // Only for this animation, we set bo to bounce since we want to give the impression that the text input is glued to the keyboard.
    [self.view animateLayoutIfNeededWithDuration:duration
                                          bounce:NO
                                         options:(curve<<16)|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                      animations:NULL];
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification
{
    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardDidShowNotification];
    
    // After showing keyboard, check if the current cursor position could diplay auto-completion
    if (show) {
        [self processTextForAutoCompletion];
    }
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
    // Skips this if it's not the expected textView.
    // Checking the keyboard height constant helps to disable the view constraints update on iPad when the keyboard is undocked.
    if (![self.textView isFirstResponder] || self.keyboardHC.constant == 0) {
        return;
    }
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.keyboardHC.constant = CGRectGetHeight([UIScreen mainScreen].bounds)-endFrame.origin.y;
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    _panningKeyboard = self.scrollViewProxy.isDragging;
    
    if (self.isInverted && self.isPanningKeyboard && !CGPointEqualToPoint(self.scrollViewProxy.contentOffset, _draggingOffset)) {
        self.scrollViewProxy.contentOffset = _draggingOffset;
    }

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
    
    // Skips this it's not the expected textView.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    [self textDidUpdate:YES];
}

- (void)willShowOrHideTypeIndicatorView:(NSNotification *)notification
{
    SCKTypeIndicatorView *indicatorView = (SCKTypeIndicatorView *)notification.object;
    
    // Skips if it's not the expected typing indicator view.
    if (![indicatorView isEqual:self.typeIndicatorView]) {
        return;
    }
    
    // Skips if the typing indicator should not show. Ignores the checking if it's trying to hide.
    if (![self canShowTypeIndicator] && !self.typeIndicatorView.isVisible) {
        return;
    }
    
    self.typeIndicatorViewHC.constant = indicatorView.isVisible ?  0.0 : indicatorView.height;
    self.scrollViewHC.constant -= self.typeIndicatorViewHC.constant;
    
    [self.view animateLayoutIfNeededWithBounce:self.bounces
                               options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                          animations:NULL];
}

- (void)didChangeTextViewContentSize:(NSNotification *)notification
{
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
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    UIImage *image = notification.object;
    
    // Notifies only if the pasted object is a valid UIImage instance
    if ([image isKindOfClass:[UIImage class]]) {
        [self didPasteImage:image];
    }
}

- (void)didShakeTextView:(NSNotification *)notification
{
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    // Notifies of the shake gesture if undo mode is on and the text view is not empty
    if (self.undoShakingEnabled && self.textView.text.length > 0) {
        [self willRequestUndo];
    }
}


#pragma mark - Auto-Completion Text Processing

- (void)registerPrefixesForAutoCompletion:(NSArray *)prefixes
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.registeredPrefixes];
    
    for (NSString *prefix in prefixes) {
        // Skips if the prefix is not a valid string
        if (![prefix isKindOfClass:[NSString class]] || prefix.length == 0) {
            continue;
        }
        
        // Adds the prefix if not contained already
        if (![array containsObject:prefix]) {
            [array addObject:prefix];
        }
    }
    
    if (_registeredPrefixes) {
        _registeredPrefixes = nil;
    }
    
    _registeredPrefixes = [[NSArray alloc] initWithArray:array];
}

- (void)processTextForAutoCompletion
{
    // Avoids text processing for auto-completion if the registered prefix list is empty.
    if (self.registeredPrefixes.count == 0) {
        return;
    }
    
    NSString *text = self.textView.text;
    
    // No need to process for auto-completion if there is no text to process
    if (text.length == 0) {
        return [self cancelAutoCompletion];
    }

    NSRange range;
    NSString *word = [self.textView wordAtCaretRange:&range];
    
    for (NSString *sign in self.registeredPrefixes) {
        
        NSRange keyRange = [word rangeOfString:sign];
        
        if (keyRange.location == 0 || (keyRange.length >= 1)) {
            
            // Captures the detected symbol prefix
            _foundPrefix = sign;
            
            // Used later for replacing the detected range with a new string alias returned in -acceptAutoCompletionWithString:
            _foundPrefixRange = NSMakeRange(range.location, sign.length);
        }
    }
    
    // Cancel auto-completion if the cursor is placed before the prefix
    if (self.textView.selectedRange.location <= _foundPrefixRange.location) {
        return [self cancelAutoCompletion];
    }
    
    if (self.foundPrefix.length > 0) {
        if (range.length == 0 || range.length != word.length) {
            return [self cancelAutoCompletion];
        }
        
        if (word.length > 0) {
            // Removes the first character, containing the symbol prefix
            _foundWord = [word substringFromIndex:1];
            
            // If the prefix is still contained in the word, cancels
            if ([_foundWord rangeOfString:_foundPrefix].location != NSNotFound) {
                return [self cancelAutoCompletion];
            }
        }
        else {
            return [self cancelAutoCompletion];
        }
    }
    else {
        return [self cancelAutoCompletion];
    }

    BOOL canShow = [self canShowAutoCompletion];
    
    [self.autoCompletionView reloadData];
    
    [self showAutoCompletionView:canShow];
}

- (void)cancelAutoCompletion
{
    _foundPrefix = nil;
    _foundWord = nil;
    _foundPrefixRange = NSMakeRange(0,0);
    
    [self.autoCompletionView setContentOffset:CGPointZero];
    
    if (self.isAutoCompleting) {
        [self showAutoCompletionView:NO];
    }
}

- (void)acceptAutoCompletionWithString:(NSString *)string
{
    if (string.length == 0) {
        return;
    }

    SCKTextView *textView = self.textView;
    
    NSRange range = NSMakeRange(self.foundPrefixRange.location+1, self.foundWord.length);
    NSRange insertionRange = [textView insertText:string inRange:range];
    
    textView.selectedRange = NSMakeRange(insertionRange.location, 0);
    
    [self cancelAutoCompletion];
    
    [textView scrollToCaretPositonAnimated:NO];
}

- (void)hideautoCompletionView
{
    [self showAutoCompletionView:NO];
}

- (void)showAutoCompletionView:(BOOL)show
{
    CGFloat viewHeight = show ? [self heightForAutoCompletionView] : 0.0;
    
    self.autoCompleting = show;
    
    if (self.autoCompletionViewHC.constant == viewHeight) {
        return;
    }

    // If the auto-completion view height is bigger than the maximum height allows, it is reduce to that size. Default 140 pts.
    if (viewHeight > [self maximumHeightForAutoCompletionView]) {
        viewHeight = [self maximumHeightForAutoCompletionView];
    }
    
    CGFloat tableHeight = self.scrollViewHC.constant;
    
    // If the the view controller extends it layout beneath it navigation bar and/or status bar, we then reduce it from the table view height
    if (self.edgesForExtendedLayout == UIRectEdgeAll || self.edgesForExtendedLayout == UIRectEdgeTop) {
        tableHeight -= CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        tableHeight -= self.navigationController.navigationBar.frame.size.height;
    }

    // On iPhone, the auto-completion view can't extend beyond the table view height
    if (viewHeight > tableHeight) {
        viewHeight = tableHeight;
    }
    
    self.autoCompletionViewHC.constant = viewHeight;
    
    [self.view animateLayoutIfNeededWithBounce:self.bounces
                                         options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                    animations:NULL];
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


#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.isPanningKeyboard) {
        _draggingOffset = scrollView.contentOffset;
    }
}


#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.singleTapGesture isEqual:gestureRecognizer]) {
        return [self.chatToolbar.textView isFirstResponder];
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


#pragma mark - View Auto-Layout

- (void)setupViewConstraints
{
    NSDictionary *views = @{@"scrollView": self.scrollViewProxy,
                            @"autoCompletionView": self.autoCompletionView,
                            @"typeIndicatorView": self.typeIndicatorView,
                            @"chatToolbar": self.chatToolbar,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView(==0@750)][autoCompletionView(0)][typeIndicatorView(0)][chatToolbar(>=0)]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[autoCompletionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[typeIndicatorView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[chatToolbar]|" options:0 metrics:nil views:views]];

    NSArray *bottomConstraints = [self.view constraintsForAttribute:NSLayoutAttributeBottom];
    NSArray *heightConstraints = [self.view constraintsForAttribute:NSLayoutAttributeHeight];
    
    self.scrollViewHC = heightConstraints[0];
    self.autoCompletionViewHC = heightConstraints[1];
    self.typeIndicatorViewHC = heightConstraints[2];
    self.chatToolbarHC = heightConstraints[3];
    self.keyboardHC = bottomConstraints[0];
    
    self.chatToolbarHC.constant = [self minimumToolbarHeight];
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    if (self.isEditing) {
        self.chatToolbarHC.constant += kAccessoryViewHeight;
    }
}


#pragma mark - External Keyboard Support

- (NSArray *)keyCommands
{
    return @[
             // Pressing Return key
             [UIKeyCommand keyCommandWithInput:@"\r"
                                 modifierFlags:0
                                        action:@selector(didPressReturnKey:)],
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
                                        action:@selector(didPressEscapeKey:)]
             ];
}


#pragma mark - NSNotificationCenter register/unregister

- (void)registerNotifications
{
    // Keyboard notifications
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


#pragma mark - View Auto-Rotation

// iOS7 only
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

// iOS8 only
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
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
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView = nil;
    
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    _collectionView = nil;
    
    _autoCompletionView.delegate = nil;
    _autoCompletionView.dataSource = nil;
    _autoCompletionView = nil;
    
    _chatToolbar = nil;
    _typeIndicatorView = nil;
    
    _registeredPrefixes = nil;
    
    _singleTapGesture = nil;
    _scrollViewHC = nil;
    _chatToolbarHC = nil;
    _chatToolbarHC = nil;
    _typeIndicatorViewHC = nil;
    _autoCompletionViewHC = nil;
    _keyboardHC = nil;
    
    [self unregisterNotifications];
}

@end
