//
//   Copyright 2014 Slack Technologies, Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import "SLKTextViewController.h"
#import "SLKUIConstants.h"

#import <objc/runtime.h>

@interface SLKTextViewController () <UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
    CGPoint _draggingOffset;
}

// Auto-Layout height constraints used for updating their constants
@property (nonatomic, strong) NSLayoutConstraint *scrollViewHC;
@property (nonatomic, strong) NSLayoutConstraint *textInputbarHC;
@property (nonatomic, strong) NSLayoutConstraint *typingIndicatorViewHC;
@property (nonatomic, strong) NSLayoutConstraint *autoCompletionViewHC;
@property (nonatomic, strong) NSLayoutConstraint *keyboardHC;

// The single tap gesture used to dismiss the keyboard
@property (nonatomic, strong) UIGestureRecognizer *singleTapGesture;

// YES if the user is moving the keyboard with a gesture
@property (nonatomic, getter = isMovingKeyboard) BOOL movingKeyboard;

// The current QuicktypeBar mode (hidden, collapsed or expanded)
@property (nonatomic) SLKQuicktypeBarMode quicktypeBarMode;

// The current keyboard status (hidden, showing, etc.)
@property (nonatomic) SLKKeyboardStatus keyboardStatus;

@end

@implementation SLKTextViewController
@synthesize tableView = _tableView;
@synthesize collectionView = _collectionView;
@synthesize typingIndicatorView = _typingIndicatorView;
@synthesize textInputbar = _textInputbar;
@synthesize autoCompletionView = _autoCompletionView;
@synthesize autoCompleting = _autoCompleting;
@synthesize presentedInPopover = _presentedInPopover;

#pragma mark - Initializer

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (instancetype)init
{
    return [self initWithTableViewStyle:UITableViewStylePlain];
}

- (instancetype)initWithTableViewStyle:(UITableViewStyle)style
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        [self tableViewWithStyle:style];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    if (self = [super initWithNibName:nil bundle:nil]) {
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
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.scrollViewProxy];
    [self.view addSubview:self.autoCompletionView];
    [self.view addSubview:self.typingIndicatorView];
    [self.view addSubview:self.textInputbar];
    
    [self setupViewConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.textView.didNotResignFirstResponder = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.scrollViewProxy flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Stops the keyboard from being dismissed during the navigation controller's "swipe-to-pop"
    self.textView.didNotResignFirstResponder = self.isMovingFromParentViewController;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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
    if (_collectionView) {
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

- (SLKTextInputbar *)textInputbar
{
    if (!_textInputbar)
    {
        _textInputbar = [SLKTextInputbar new];
        _textInputbar.translatesAutoresizingMaskIntoConstraints = NO;
        _textInputbar.controller = self;
        
        [_textInputbar.leftButton addTarget:self action:@selector(didPressLeftButton:) forControlEvents:UIControlEventTouchUpInside];
        [_textInputbar.rightButton addTarget:self action:@selector(didPressRightButton:) forControlEvents:UIControlEventTouchUpInside];
        [_textInputbar.editortLeftButton addTarget:self action:@selector(didCancelTextEditing:) forControlEvents:UIControlEventTouchUpInside];
        [_textInputbar.editortRightButton addTarget:self action:@selector(didCommitTextEditing:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _textInputbar;
}

- (SLKTypingIndicatorView *)typingIndicatorView
{
    if (!_typingIndicatorView)
    {
        _typingIndicatorView = [SLKTypingIndicatorView new];
        _typingIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        _typingIndicatorView.canResignByTouch = NO;
    }
    return _typingIndicatorView;
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
    if (_tableView.isEditing) {
        return YES;
    }
    
    if (self.textInputbar.isEditing) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isPresentedInPopover
{
    return _presentedInPopover && UI_IS_IPAD;
}

+ (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

- (SLKTextView *)textView
{
    return self.textInputbar.textView;
}

- (UIButton *)leftButton
{
    return self.textInputbar.leftButton;
}

- (UIButton *)rightButton
{
    return self.textInputbar.rightButton;
}

- (CGFloat)deltaInputbarHeight
{
    return self.textView.intrinsicContentSize.height-self.textView.font.lineHeight;
}

- (CGFloat)minimumInputbarHeight
{
    return self.textInputbar.intrinsicContentSize.height;
}

- (CGFloat)inputBarHeightForLines:(NSUInteger)numberOfLines
{
    CGFloat height = [self deltaInputbarHeight];
    
    height += roundf(self.textView.font.lineHeight*numberOfLines);
    height += self.textInputbar.contentInset.top+self.textInputbar.contentInset.bottom;
    
    return height;
}

- (CGFloat)appropriateInputbarHeight
{
    CGFloat height = 0.0;
    
    if (self.textView.numberOfLines == 1) {
        height = [self minimumInputbarHeight];
    }
    else if (self.textView.numberOfLines < self.textView.maxNumberOfLines) {
        height += [self inputBarHeightForLines:self.textView.numberOfLines];
    }
    else {
        height += [self inputBarHeightForLines:self.textView.maxNumberOfLines];
    }
    
    if (height < [self minimumInputbarHeight]) {
        height = [self minimumInputbarHeight];
    }
    
    if (self.isEditing) {
        height += self.textInputbar.accessoryViewHeight;
    }
    
    return roundf(height);
}

- (CGFloat)appropriateKeyboardHeight:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat keyboardHeight = 0.0;
    CGFloat tabBarHeight = ([self.tabBarController.tabBar isHidden] || self.hidesBottomBarWhenPushed) ? 0.0 : CGRectGetHeight(self.tabBarController.tabBar.frame);
    
    // The height of the keyboard if showing
    if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        keyboardHeight = MIN(CGRectGetWidth(endFrame), CGRectGetHeight(endFrame));
        keyboardHeight -= tabBarHeight;
    }
    
    // The height of the keyboard if sliding
    if ([notification.name isEqualToString:SCKInputAccessoryViewKeyboardFrameDidChangeNotification]) {
        keyboardHeight = CGRectGetHeight([UIScreen mainScreen].bounds)-endFrame.origin.y;
        keyboardHeight -= tabBarHeight;
    }
    
    if (keyboardHeight < 0) {
        keyboardHeight = 0.0;
    }
    
    return keyboardHeight;
}

- (CGFloat)appropriateScrollViewHeight
{
    CGFloat height = self.view.bounds.size.height;

    height -= self.keyboardHC.constant;
    height -= self.textInputbarHC.constant;
    height -= self.autoCompletionViewHC.constant;
    height -= self.typingIndicatorViewHC.constant;
    
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
    
    // Updates the iOS8 QuickType bar mode based on the keyboard height constant
    if (UI_IS_IOS8_AND_HIGHER) {
        [self updateQuicktypeBarMode];
    }
}

- (void)updateQuicktypeBarMode
{
    CGFloat quicktypeBarHeight = self.keyboardHC.constant-minimumKeyboardHeight();
    
    // Updates the QuickType bar mode based on the keyboard height constant
    self.quicktypeBarMode = SLKQuicktypeBarModeForHeight(quicktypeBarHeight);
}

- (void)setQuicktypeBarMode:(SLKQuicktypeBarMode)quicktypeBarMode
{
    _quicktypeBarMode = quicktypeBarMode;
    
    BOOL shouldHide = quicktypeBarMode == SLKQuicktypeBarModeExpanded  && self.autoCompleting;
    
    // Skips if the QuickType Bar is minimised
    if (quicktypeBarMode == SLKQuicktypeBarModeCollapsed) {
        return;
    }
    
    // Hides the iOS8 QuicktypeBar if visible and auto-completing mode is on
    [self.textView disableQuicktypeBar:shouldHide];
}

- (void)setKeyboardPanningEnabled:(BOOL)enabled
{
    if (self.keyboardPanningEnabled == enabled) {
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
    
    if (!inverted && ((self.edgesForExtendedLayout & UIRectEdgeBottom) > 0)) {
        self.edgesForExtendedLayout = self.edgesForExtendedLayout & ~UIRectEdgeBottom;
    }
}

- (void)setKeyboardStatus:(SLKKeyboardStatus)status
{
    // Skips if trying to update the same status
    if (self.keyboardStatus == status) {
        return;
    }
    
    // Skips illogical conditions
    if ((self.keyboardStatus == SLKKeyboardStatusDidShow && status == SLKKeyboardStatusWillShow) ||
        (self.keyboardStatus == SLKKeyboardStatusDidHide && status == SLKKeyboardStatusWillHide)) {
        return;
    }
    
    _keyboardStatus = status;
    
    [self didChangeKeyboardStatus:status];
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

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status
{
    // No implementation here. Meant to be overriden in subclass.
}

- (void)textWillUpdate
{
    // No implementation here. Meant to be overriden in subclass.
}

- (void)textDidUpdate:(BOOL)animated
{
    self.textInputbar.rightButton.enabled = [self canPressRightButton];
    self.textInputbar.editortRightButton.enabled = [self canPressRightButton];

    CGFloat inputbarHeight = [self appropriateInputbarHeight];
    
    if (inputbarHeight != self.textInputbarHC.constant)
    {
        self.textInputbarHC.constant = inputbarHeight;
        self.scrollViewHC.constant = [self appropriateScrollViewHeight];
        
        if (animated) {
            
            BOOL bounces = self.bounces && [self.textView isFirstResponder];
            
			[self.view slk_animateLayoutIfNeededWithBounce:bounces
												   options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
												animations:^{
													if (self.isEditing) {
														[self.textView slk_scrollToCaretPositonAnimated:NO];
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
    
    if (text.length > 0 && ![self.textInputbar limitExceeded]) {
        return YES;
    }
    
    return NO;
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
    
    [self.textInputbar endTextEdition];
    
    [self.textView setText:nil];
}

- (BOOL)canShowTypeIndicator
{
    // Don't show if the text is being edited or auto-completed.
    if (self.isEditing || self.isAutoCompleting) {
        return NO;
    }
    
    // Don't show if the content offset is not at top (when inverted) or at bottom (when not inverted)
    if ((self.isInverted && ![self.scrollViewProxy slk_isAtTop]) || (!self.isInverted && ![self.scrollViewProxy slk_isAtBottom])) {
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
    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }
    
    [self dismissKeyboard:YES];
}

- (void)editText:(NSString *)text
{
    if (![self.textInputbar canEditText:text]) {
        return;
    }
    
    // Updates the constraints before inserting text, if not first responder yet
    if (![self.textView isFirstResponder]) {
        [self.textInputbar beginTextEditing];
    }

    [self.textView setText:text];
    [self.textView slk_scrollToCaretPositonAnimated:YES];
    
    // Updates the constraints after inserting text, if already first responder
    if ([self.textView isFirstResponder]) {
        [self.textInputbar beginTextEditing];
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
    [self.textView slk_insertNewLineBreak];
}

- (void)prepareForInterfaceRotation
{
    [self.view layoutIfNeeded];
    
    if ([self.textView isFirstResponder]) {
        [self.textView slk_scrollToCaretPositonAnimated:NO];
    }
    else {
        [self.textView slk_scrollToBottomAnimated:NO];
    }
}


#pragma mark - Notification Events

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }
    
    // Skips if textview did refresh only
    if (self.textView.didNotResignFirstResponder) {
        return;
    }
    
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    // Checks if it's showing or hidding the keyboard
    BOOL willShow = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    // Programatically stops scrolling before updating the view constraints (to avoid scrolling glitch)
    [self.scrollViewProxy slk_stopScrolling];
    
    // Updates the height constraints' constants
    self.keyboardHC.constant = [self appropriateKeyboardHeight:notification];
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    // Hides autocompletion mode if the keyboard is being dismissed
    if (!willShow && self.isAutoCompleting) {
        [self hideAutoCompletionView];
    }
    
    // Only for this animation, we set bo to bounce since we want to give the impression that the text input is glued to the keyboard.
	[self.view slk_animateLayoutIfNeededWithDuration:duration
											  bounce:NO
											 options:(curve<<16)|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
										  animations:NULL];
    
    // Updates and notifies about the keyboard status update
    self.keyboardStatus = willShow ? SLKKeyboardStatusWillShow : SLKKeyboardStatusWillHide;
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification
{
    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }
    
    // Skips if textview did refresh only
    if (self.textView.didNotResignFirstResponder) {
        return;
    }
    
    // Checks if it's showing or hidding the keyboard
    BOOL didShow = [notification.name isEqualToString:UIKeyboardDidShowNotification];
    
    // After showing keyboard, check if the current cursor position could diplay autocompletion
    if (didShow) {
        [self processTextForAutoCompletion];
    }
    
    // Updates and notifies about the keyboard status update
    self.keyboardStatus = didShow ? SLKKeyboardStatusDidShow : SLKKeyboardStatusDidHide;
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }
    
    // Skips this if it's not the expected textView.
    // Checking the keyboard height constant helps to disable the view constraints update on iPad when the keyboard is undocked.
    if (![self.textView isFirstResponder] || self.keyboardHC.constant == 0) {
        return;
    }
    
    self.keyboardHC.constant = [self appropriateKeyboardHeight:notification];
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    self.movingKeyboard = self.scrollViewProxy.isDragging;
    
    if (self.isInverted && self.isMovingKeyboard && !CGPointEqualToPoint(self.scrollViewProxy.contentOffset, _draggingOffset)) {
        self.scrollViewProxy.contentOffset = _draggingOffset;
    }

    [self.view layoutIfNeeded];
}

- (void)willChangeTextView:(NSNotification *)notification
{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // Skips this it's not the expected textView.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    [self textWillUpdate];
}

- (void)didChangeTextViewText:(NSNotification *)notification
{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // Skips this it's not the expected textView.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    [self textDidUpdate:YES];
}

- (void)willShowOrHideTypeIndicatorView:(NSNotification *)notification
{
    SLKTypingIndicatorView *indicatorView = (SLKTypingIndicatorView *)notification.object;
    
    // Skips if it's not the expected typing indicator view.
    if (![indicatorView isEqual:self.typingIndicatorView]) {
        return;
    }
    
    // Skips if the typing indicator should not show. Ignores the checking if it's trying to hide.
    if (![self canShowTypeIndicator] && !self.typingIndicatorView.isVisible) {
        return;
    }
    
    self.typingIndicatorViewHC.constant = indicatorView.isVisible ?  0.0 : indicatorView.height;
    self.scrollViewHC.constant -= self.typingIndicatorViewHC.constant;
    
	[self.view slk_animateLayoutIfNeededWithBounce:self.bounces
										   options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
										animations:NULL];
}

- (void)didChangeTextViewContentSize:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![self.textView isEqual:notification.object]) {
        return;
    }
    
    [self textDidUpdate:YES];
}

- (void)didChangeTextViewSelection:(NSNotification *)notification
{
    NSRange selectedRange = [notification.userInfo[@"range"] rangeValue];
    
    // Updates autocompletion if the caret is not selecting just re-positioning
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
    // Avoids text processing for autocompletion if the registered prefix list is empty.
    if (self.registeredPrefixes.count == 0) {
        return;
    }
    
    NSString *text = self.textView.text;
    
    // No need to process for autocompletion if there is no text to process
    if (text.length == 0) {
        return [self cancelAutoCompletion];
    }

    NSRange range;
    NSString *word = [self.textView slk_wordAtCaretRange:&range];
    
    for (NSString *sign in self.registeredPrefixes) {
        
        NSRange keyRange = [word rangeOfString:sign];
        
        if (keyRange.location == 0 || (keyRange.length >= 1)) {
            
            // Captures the detected symbol prefix
            _foundPrefix = sign;
            
            // Used later for replacing the detected range with a new string alias returned in -acceptAutoCompletionWithString:
            _foundPrefixRange = NSMakeRange(range.location, sign.length);
        }
    }
    
    // Cancel autocompletion if the cursor is placed before the prefix
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

    SLKTextView *textView = self.textView;
    
    NSRange range = NSMakeRange(self.foundPrefixRange.location+1, self.foundWord.length);
    NSRange insertionRange = [textView slk_insertText:string inRange:range];
    
    textView.selectedRange = NSMakeRange(insertionRange.location, 0);
    
    [self cancelAutoCompletion];
    
    [textView slk_scrollToCaretPositonAnimated:NO];
}

- (void)hideAutoCompletionView
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

    // If the autocompletion view height is bigger than the maximum height allows, it is reduce to that size. Default 140 pts.
    if (viewHeight > [self maximumHeightForAutoCompletionView]) {
        viewHeight = [self maximumHeightForAutoCompletionView];
    }
    
    CGFloat tableHeight = self.scrollViewHC.constant;
    
    // If the the view controller extends it layout beneath it navigation bar and/or status bar, we then reduce it from the table view height
    if (self.edgesForExtendedLayout == UIRectEdgeAll || self.edgesForExtendedLayout == UIRectEdgeTop) {
        tableHeight -= CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        tableHeight -= self.navigationController.navigationBar.frame.size.height;
    }

    // On iPhone, the autocompletion view can't extend beyond the table view height
    if (viewHeight > tableHeight) {
        viewHeight = tableHeight;
    }
    
    self.autoCompletionViewHC.constant = viewHeight;
    
	[self.view slk_animateLayoutIfNeededWithBounce:self.bounces
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
    if (!self.isMovingKeyboard) {
        _draggingOffset = scrollView.contentOffset;
    }
}


#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.singleTapGesture isEqual:gestureRecognizer]) {
        return [self.textInputbar.textView isFirstResponder];
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
                            @"typingIndicatorView": self.typingIndicatorView,
                            @"textInputbar": self.textInputbar,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView(==0@750)][autoCompletionView(0)][typingIndicatorView(0)]-0@999-[textInputbar(>=0)]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[autoCompletionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[typingIndicatorView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textInputbar]|" options:0 metrics:nil views:views]];

    NSArray *bottomConstraints = [self.view slk_constraintsForAttribute:NSLayoutAttributeBottom];
    NSArray *heightConstraints = [self.view slk_constraintsForAttribute:NSLayoutAttributeHeight];
    
    self.scrollViewHC = heightConstraints[0];
    self.autoCompletionViewHC = heightConstraints[1];
    self.typingIndicatorViewHC = heightConstraints[2];
    self.textInputbarHC = heightConstraints[3];
    self.keyboardHC = bottomConstraints[0];
    
    self.textInputbarHC.constant = [self minimumInputbarHeight];
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    if (self.isEditing) {
        self.textInputbarHC.constant += self.textInputbar.accessoryViewHeight;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeTextView:) name:SLKTextViewTextWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewContentSize:) name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewSelection:) name:SLKTextViewSelectionDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewPasteboard:) name:SLKTextViewDidPasteImageNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShakeTextView:) name:SLKTextViewDidShakeNotification object:nil];
    
    
    // TypeIndicator notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideTypeIndicatorView:) name:SLKTypingIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideTypeIndicatorView:) name:SLKTypingIndicatorViewWillHideNotification object:nil];
}

- (void)unregisterNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];

    // TextView notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewTextWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewDidPasteImageNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewDidShakeNotification object:nil];
    
    // TypeIndicator notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTypingIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTypingIndicatorViewWillHideNotification object:nil];
}


#pragma mark - View Auto-Rotation

// iOS7 only
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (![self respondsToSelector:@selector(willTransitionToTraitCollection:withTransitionCoordinator:)]) {
        [self prepareForInterfaceRotation];
    }
}

// iOS8 only
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self prepareForInterfaceRotation];
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
    
    _textInputbar = nil;
    _typingIndicatorView = nil;
    
    _registeredPrefixes = nil;
    
    _singleTapGesture = nil;
    _scrollViewHC = nil;
    _textInputbarHC = nil;
    _textInputbarHC = nil;
    _typingIndicatorViewHC = nil;
    _autoCompletionViewHC = nil;
    _keyboardHC = nil;
    
    [self unregisterNotifications];
}

@end
