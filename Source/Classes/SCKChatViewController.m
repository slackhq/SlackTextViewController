//
//  SCKChatViewController.m
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SCKChatViewController.h"
#import "UIView+ChatKitAdditions.h"

@interface SCKChatViewController () <UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
    CGPoint _draggingOffset;
}

// Used for Auto-Layout constraints, and update its constants
@property (nonatomic, strong) NSLayoutConstraint *scrollViewHC;
@property (nonatomic, strong) NSLayoutConstraint *containerViewHC;
@property (nonatomic, strong) NSLayoutConstraint *typeIndicatorViewHC;
@property (nonatomic, strong) NSLayoutConstraint *autoCompletionViewHC;
@property (nonatomic, strong) NSLayoutConstraint *keyboardHC;

@property (nonatomic, strong) UIGestureRecognizer *singleTapGesture;

@property (nonatomic, readonly, getter = isPanningKeyboard) BOOL panningKeyboard;

// Used for Auto-Completion
@property (nonatomic, strong) NSMutableArray *registeredPrefixes;
@property (nonatomic, readonly) NSRange foundPrefixRange;

@end

@implementation SCKChatViewController
@synthesize tableView = _tableView;
@synthesize collectionView = _collectionView;
@synthesize typeIndicatorView = _typeIndicatorView;
@synthesize textContainerView = _textContainerView;
@synthesize autoCompletionView = _autoCompletionView;
@synthesize autoCompleting = _autoCompleting;

#pragma mark - Initializer

- (id)init
{
    return [self initWithStyle:UITableViewStylePlain];
}

- (instancetype)initWithStyle:(UITableViewStyle)style
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
    self.bounces = YES;
    self.undoShakingEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.inverted = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.scrollViewProxy];
    [self.view addSubview:self.autoCompletionView];
    [self.view addSubview:self.typeIndicatorView];
    [self.view addSubview:self.textContainerView];
    
    [self setupViewConstraints];
    
    [self registerNotifications];
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
        _typeIndicatorView.canResignByTouch = YES;
        
    }
    return _typeIndicatorView;
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

- (CGFloat)appropriateScrollViewHeight
{
    CGFloat height = self.view.bounds.size.height;
    height -= self.keyboardHC.constant;
    height -= self.containerViewHC.constant;
    height -= self.autoCompletionViewHC.constant;
    height -= self.typeIndicatorViewHC.constant;
    
    if (height < 0) return 0;
    else return roundf(height);
}


#pragma mark - Setters

- (void)setbounces:(BOOL)bounces
{
    _bounces = bounces;
    _textContainerView.bounces = self.bounces;
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
    if (self.keyboardPanningEnabled == enabled) {
        return;
    }
    
    _keyboardPanningEnabled = enabled;
    
    if (enabled) {
        self.textView.inputAccessoryView = [SCKInputAccessoryView new];
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
    self.textContainerView.rightButton.enabled = [self canPressRightButton];
    self.textContainerView.editortRightButton.enabled = [self canPressRightButton];

    CGFloat containeHeight = [self appropriateContainerViewHeight];
    
    if (containeHeight != self.containerViewHC.constant)
    {
        self.containerViewHC.constant = containeHeight;
        self.scrollViewHC.constant = [self appropriateScrollViewHeight];
        
        if (animated) {
            [self.view animateLayoutIfNeededWithBounce:self.bounces
                                                 curve:UIViewAnimationOptionCurveEaseInOut
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
    
    [self.textContainerView endTextEdition];
    
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
    if (![self.textContainerView canEditText:text]) {
        return;
    }
    
    [self.textView setText:text];
    [self.textView scrollToCaretPositonAnimated:YES];

    [self.textContainerView beginTextEditing];
    
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
    
    endFrame = adjustEndFrame(endFrame, self.interfaceOrientation);
    
    if (!isValidKeyboardFrame(endFrame)) return;

    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    // Programatically stops scrolling before updating the view constraints (to avoid scrolling glitch)
    [self.scrollViewProxy stopScrolling];
    
    // Updates the height constraints' constants
    self.keyboardHC.constant = show ? endFrame.size.height : 0.0;
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    if (!show && self.isAutoCompleting) {
        [self hideautoCompletionView];
    }
    
    // Only for this animation, we set bo to bounce since we want to give the impression that the text input is glued to the keyboard.
    [self.view animateLayoutIfNeededWithBounce:NO curve:curve animations:NULL];
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
                               curve:UIViewAnimationOptionCurveEaseInOut
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

- (void)registerPrefixesForAutoCompletion:(NSArray *)keys
{
    // Creates the array if not exitent
    if (!self.registeredPrefixes) {
        self.registeredPrefixes = [[NSMutableArray alloc] initWithCapacity:keys.count];
    }
    
    for (NSString *key in keys) {
        // Skips if the prefix is not a valid string or longer than 1 letter
        if (![key isKindOfClass:[NSString class]] || key.length == 0 || key.length > 1) {
            continue;
        }
        
        // Adds the prefix if not contained already
        if (![self.registeredPrefixes containsObject:key]) {
            [self.registeredPrefixes addObject:key];
        }
    }
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
        [self cancelAutoCompletion];
        return;
    }

    NSRange range;
    NSString *word = [self.textView wordAtCaretRange:&range];
    
    for (NSString *sign in self.registeredPrefixes) {
        
        NSRange keyRange = [word rangeOfString:sign];
        
        if (keyRange.location == 0 || (keyRange.length == 1)) {
            
            // Captures the detected symbol prefix
            _foundPrefix = sign;
            
            // Used later for replacing the detected range with a new string alias returned in -acceptAutoCompletionWithString:
            _foundPrefixRange = NSMakeRange(range.location, sign.length);
        }
    }
    
    if (self.foundPrefix.length > 0) {
        if (range.length == 0 || range.length != word.length) {
            return [self cancelAutoCompletion];
        }
        
        if (word.length > 0) {
            // Removes the first character, containing the symbol prefix
            _foundWord = [word substringFromIndex:1];
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
    _foundPrefixRange = NSRangeFromString(nil);
    
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
    NSRange insertionRange = textView.selectedRange;
    
    NSRange range = NSMakeRange(self.foundPrefixRange.location+1, self.foundWord.length);
    insertionRange = [textView insertText:string inRange:range];
    
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
                                         curve:UIViewAnimationOptionCurveEaseInOut
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


#pragma mark - View Auto-Layout

- (void)setupViewConstraints
{
    // Removes all constraints
    [self.view removeConstraints:self.view.constraints];
    
    NSDictionary *views = @{@"scrollView": self.scrollViewProxy,
                            @"autoCompletionView": self.autoCompletionView,
                            @"typeIndicatorView": self.typeIndicatorView,
                            @"textContainerView": self.textContainerView,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView(==0@250)][autoCompletionView(0)][typeIndicatorView(0)][textContainerView(>=0)]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[autoCompletionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[typeIndicatorView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textContainerView]|" options:0 metrics:nil views:views]];

    NSArray *heightConstraints = [self.view constraintsForAttribute:NSLayoutAttributeHeight];
    NSArray *bottomConstraints = [self.view constraintsForAttribute:NSLayoutAttributeBottom];
    
    self.scrollViewHC = heightConstraints[0];
    self.autoCompletionViewHC = heightConstraints[1];
    self.typeIndicatorViewHC = heightConstraints[2];
    self.containerViewHC = heightConstraints[3];
    self.keyboardHC = bottomConstraints[0];
    
    self.containerViewHC.constant = self.textContainerView.minHeight;
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
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
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView = nil;
    
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    _collectionView = nil;
    
    _autoCompletionView.delegate = nil;
    _autoCompletionView.dataSource = nil;
    _autoCompletionView = nil;
    
    _textContainerView = nil;
    _typeIndicatorView = nil;
    
    _registeredPrefixes = nil;
    
    _singleTapGesture = nil;
    _scrollViewHC = nil;
    _containerViewHC = nil;
    _containerViewHC = nil;
    _typeIndicatorViewHC = nil;
    _autoCompletionViewHC = nil;
    _keyboardHC = nil;
    
    [self unregisterNotifications];
}

@end
