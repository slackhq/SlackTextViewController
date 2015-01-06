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
#import "SLKInputAccessoryView.h"
#import "SLKUIConstants.h"

NSString * const SLKKeyboardWillShowNotification =  @"SLKKeyboardWillShowNotification";
NSString * const SLKKeyboardDidShowNotification =   @"SLKKeyboardDidShowNotification";
NSString * const SLKKeyboardWillHideNotification =  @"SLKKeyboardWillHideNotification";
NSString * const SLKKeyboardDidHideNotification =   @"SLKKeyboardDidHideNotification";

@interface SLKTextViewController () <UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
    CGPoint _draggingOffset;
}

// The shared scrollView pointer, either a tableView or collectionView
@property (nonatomic, weak) UIScrollView *scrollViewProxy;

// Auto-Layout height constraints used for updating their constants
@property (nonatomic, strong) NSLayoutConstraint *scrollViewHC;
@property (nonatomic, strong) NSLayoutConstraint *textInputbarHC;
@property (nonatomic, strong) NSLayoutConstraint *typingIndicatorViewHC;
@property (nonatomic, strong) NSLayoutConstraint *autoCompletionViewHC;
@property (nonatomic, strong) NSLayoutConstraint *keyboardHC;

// The pan gesture used for bringing the keyboard from the bottom
@property (nonatomic, strong) UIPanGestureRecognizer *verticalPanGesture;

// The keyboard commands available for external keyboards
@property (nonatomic, strong) NSArray *keyboardCommands;

// YES if the user is moving the keyboard with a gesture
@property (nonatomic, assign, getter = isMovingKeyboard) BOOL movingKeyboard;

// The setter of isExternalKeyboardDetected, for private use.
@property (nonatomic, assign) BOOL externalKeyboardDetected;

// The current keyboard status (hidden, showing, etc.)
@property (nonatomic) SLKKeyboardStatus keyboardStatus;

// YES if a new word has been typed recently
@property (nonatomic) BOOL newWordInserted;

// YES if the view controller did appear and everything is finished configurating. This allows blocking some layout animations among other things.
@property (nonatomic) BOOL didFinishConfigurating;

// The setter of isExternalKeyboardDetected, for private use.
@property (nonatomic, getter = isRotating) BOOL rotating;

@end

@implementation SLKTextViewController
@synthesize tableView = _tableView;
@synthesize collectionView = _collectionView;
@synthesize typingIndicatorView = _typingIndicatorView;
@synthesize textInputbar = _textInputbar;
@synthesize autoCompletionView = _autoCompletionView;
@synthesize autoCompleting = _autoCompleting;
@synthesize scrollViewProxy = _scrollViewProxy;
@synthesize presentedInPopover = _presentedInPopover;

#pragma mark - Initializer

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithTableViewStyle:UITableViewStylePlain];
}

- (instancetype)init
{
    return [self initWithTableViewStyle:UITableViewStylePlain];
}

- (instancetype)initWithTableViewStyle:(UITableViewStyle)style
{
    NSAssert([self class] != [SLKTextViewController class], @"Oops! You must subclass SLKTextViewController.");
    
    if (self = [super initWithNibName:nil bundle:nil])
    {
        self.scrollViewProxy = [self tableViewWithStyle:style];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    NSAssert([self class] != [SLKTextViewController class], @"Oops! You must subclass SLKTextViewController.");
    
    if (self = [super initWithNibName:nil bundle:nil])
    {
        self.scrollViewProxy = [self collectionViewWithLayout:layout];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSAssert([self class] != [SLKTextViewController class], @"Oops! You must subclass SLKTextViewController.");
    
    if (self = [super initWithCoder:decoder])
    {
        UITableViewStyle tableViewStyle = [[self class] tableViewStyleForCoder:decoder];
        UICollectionViewLayout *collectionViewLayout = [[self class] collectionViewLayoutForCoder:decoder];
        
        if ([collectionViewLayout isKindOfClass:[UICollectionViewLayout class]]) {
            self.scrollViewProxy = [self collectionViewWithLayout:collectionViewLayout];
        }
        else {
            self.scrollViewProxy = [self tableViewWithStyle:tableViewStyle];
        }
        
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [self registerNotifications];
    
    self.bounces = YES;
    self.inverted = YES;
    self.shakeToClearEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.shouldClearTextAtRightButtonPress = YES;
    self.shouldForceTextInputbarAdjustment = NO;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
        
    [self.view addSubview:self.scrollViewProxy];
    [self.view addSubview:self.autoCompletionView];
    [self.view addSubview:self.typingIndicatorView];
    [self.view addSubview:self.textInputbar];
    
    [self setupViewConstraints];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Invalidates this flag when the view appears
    self.textView.didNotResignFirstResponder = NO;
    
    [UIView performWithoutAnimation:^{
        // Reloads any cached text
        [self reloadTextView];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.scrollViewProxy flashScrollIndicators];
    
    self.didFinishConfigurating = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Stops the keyboard from being dismissed during the navigation controller's "swipe-to-pop"
    self.textView.didNotResignFirstResponder = self.isMovingFromParentViewController;
    
    self.didFinishConfigurating = NO;
    
    // Caches the text before it's too late!
    [self cacheTextView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}


#pragma mark - Getters

+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}

+ (UICollectionViewLayout *)collectionViewLayoutForCoder:(NSCoder *)decoder
{
    return nil;
}

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
    }
    return _collectionView;
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
        
        _textInputbar.textView.delegate = self;
        
        self.verticalPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanTextView:)];
        self.verticalPanGesture.delegate = self;
        [_textInputbar.textView addGestureRecognizer:self.verticalPanGesture];
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

- (BOOL)isExternalKeyboardDetected
{
    return _externalKeyboardDetected;
}

- (BOOL)isPresentedInPopover
{
    return _presentedInPopover && SLK_IS_IPAD;
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

- (SLKInputAccessoryView *)emptyInputAccessoryView
{
    if (!self.isKeyboardPanningEnabled) {
        return nil;
    }
    
    SLKInputAccessoryView *view = [[SLKInputAccessoryView alloc] initWithFrame:self.textInputbar.bounds];
    view.backgroundColor = [UIColor clearColor];
    view.userInteractionEnabled = NO;
    
#if SLK_INPUT_ACCESSORY_DEBUG
    view.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
#endif
    
    return view;
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
    CGFloat minimumHeight = [self minimumInputbarHeight];
    
    if (self.textView.numberOfLines == 1) {
        height = minimumHeight;
    }
    else if (self.textView.numberOfLines < self.textView.maxNumberOfLines) {
        height = [self inputBarHeightForLines:self.textView.numberOfLines];
    }
    else {
        height = [self inputBarHeightForLines:self.textView.maxNumberOfLines];
    }
    
    
    if (height < minimumHeight) {
        height = minimumHeight;
    }
    
    if (self.isEditing) {
        height += self.textInputbar.accessoryViewHeight;
    }
    
    return roundf(height);
}

- (CGFloat)appropriateKeyboardHeight:(NSNotification *)notification
{
    CGFloat keyboardHeight = 0.0;

    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.externalKeyboardDetected = [self detectExternalKeyboardInNotification:notification];
    
    // Always return 0 if an external keyboard has been detected
    if (self.externalKeyboardDetected) {
        return keyboardHeight;
    }
    
    // Sets the minimum height of the keyboard
    if (self.isMovingKeyboard) {
        if (!SLK_IS_IOS8_AND_HIGHER && SLK_IS_LANDSCAPE) {
            keyboardHeight = MIN(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
            keyboardHeight -= MAX(endFrame.origin.x, endFrame.origin.y);
        }
        else {
            keyboardHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
            keyboardHeight -= endFrame.origin.y;
        }
    }
    else {
        if ([notification.name isEqualToString:UIKeyboardWillShowNotification] || [notification.name isEqualToString:UIKeyboardDidShowNotification]) {
            CGRect convertedRect = [self.view convertRect:endFrame toView:self.view.window];
            keyboardHeight = CGRectGetHeight(convertedRect);
        }
        else {
            keyboardHeight = 0.0;
        }
    }
    
    keyboardHeight -= [self appropriateBottomMarginToWindow];
    keyboardHeight -= CGRectGetHeight(self.textView.inputAccessoryView.bounds);
    
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

- (CGFloat)appropriateBottomMarginToWindow
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    CGRect windowFrame = [window convertRect:window.frame fromView:self.view];
    windowFrame.origin = CGPointZero;
    
    CGRect viewRect = [window convertRect:self.view.frame fromView:nil];
    
    CGFloat bottomWindow = CGRectGetMaxY(windowFrame);
    CGFloat bottomView = CGRectGetMaxY(viewRect);
    
    // Retrieve the status bar's height when the in-call status bar is displayed
    if (CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) > 20.0) {
        bottomView += CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)/2.0;
    }
    
    CGFloat margin = bottomWindow - bottomView;
    
    // Do NOT consider a status bar height gap
    return (margin > 20) ? margin : 0.0;
}

- (NSString *)appropriateKeyboardNotificationName:(NSNotification *)notification
{
    NSString *name = notification.name;
    
    if ([name isEqualToString:UIKeyboardWillShowNotification]) {
        return SLKKeyboardWillShowNotification;
    }
    if ([name isEqualToString:UIKeyboardWillHideNotification]) {
        return SLKKeyboardWillHideNotification;
    }
    if ([name isEqualToString:UIKeyboardDidShowNotification]) {
        return SLKKeyboardDidShowNotification;
    }
    if ([name isEqualToString:UIKeyboardDidHideNotification]) {
        return SLKKeyboardDidHideNotification;
    }
    return nil;
}

- (SLKKeyboardStatus)keyboardStatusForNotification:(NSNotification *)notification
{
    NSString *name = notification.name;

    if ([name isEqualToString:UIKeyboardWillShowNotification]) {
        return SLKKeyboardStatusWillShow;
    }
    if ([name isEqualToString:UIKeyboardDidShowNotification]) {
        return SLKKeyboardStatusDidShow;
    }
    if ([name isEqualToString:UIKeyboardWillHideNotification]) {
        return SLKKeyboardStatusWillHide;
    }
    if ([name isEqualToString:UIKeyboardDidHideNotification]) {
        return SLKKeyboardStatusDidHide;
    }
    return -1;
}

- (BOOL)isIllogicalKeyboardStatus:(SLKKeyboardStatus)status
{
    if ((self.keyboardStatus == 0 && status == 1) ||
        (self.keyboardStatus == 1 && status == 2) ||
        (self.keyboardStatus == 2 && status == 3) ||
        (self.keyboardStatus == 3 && status == 0)) {
        return NO;
    }
    return YES;
}


#pragma mark - Setters

- (void)setScrollViewProxy:(UIScrollView *)scrollView
{
    if ([self.scrollViewProxy isEqual:scrollView]) {
        return;
    }
    
    _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapScrollView:)];
    _singleTapGesture.delegate = self;
    [_singleTapGesture requireGestureRecognizerToFail:scrollView.panGestureRecognizer];
    
    [scrollView addGestureRecognizer:self.singleTapGesture];
    
    _scrollViewProxy = scrollView;
}

- (void)setAutoCompleting:(BOOL)autoCompleting
{
    if (self.autoCompleting == autoCompleting) {
        return;
    }
    
    _autoCompleting = autoCompleting;
    
    self.scrollViewProxy.scrollEnabled = !autoCompleting;
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

- (void)setUndoShakingEnabled:(BOOL)enabled
{
    _shakeToClearEnabled = enabled;
}

- (void)setKeyboardPanningEnabled:(BOOL)enabled
{
    if (self.keyboardPanningEnabled == enabled) {
        return;
    }
    
    self.scrollViewProxy.keyboardDismissMode = enabled ? UIScrollViewKeyboardDismissModeInteractive : UIScrollViewKeyboardDismissModeNone;
    
    _keyboardPanningEnabled = enabled;
}

- (BOOL)updateKeyboardStatus:(SLKKeyboardStatus)status
{
    // Skips if trying to update the same status
    if (self.keyboardStatus == status) {
        return NO;
    }
    
    // Skips illogical conditions
    if ([self isIllogicalKeyboardStatus:status]) {
        return NO;
    }
    
    _keyboardStatus = status;
    
    [self didChangeKeyboardStatus:status];
    
    return YES;
}


#pragma mark - Public & Subclassable Methods

- (void)presentKeyboard:(BOOL)animated
{
    // Skips if already first responder
    if ([self.textView isFirstResponder]) {
        return;
    }
    
    if (!animated) {
        [UIView performWithoutAnimation:^{
            [self.textView becomeFirstResponder];
        }];
    }
    else {
        [self.textView becomeFirstResponder];
    }
}

- (void)dismissKeyboard:(BOOL)animated
{
    if (![self.textView isFirstResponder]) {
        
        // Dismisses the keyboard from any first responder in the window.
        if (self.keyboardHC.constant > 0) {
            [self.view.window endEditing:NO];
        }
        return;
    }
    
    if (!animated)
    {
        [UIView performWithoutAnimation:^{
            [self.textView resignFirstResponder];
        }];
    }
    else {
        [self.textView resignFirstResponder];
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
    
    // Only updates the input view if the number of line changed
    [self reloadInputAccessoryViewIfNeeded];
    
    // Toggles auto-correction if requiered
    [self enableTypingSuggestionIfNeeded];
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
    if (self.shouldClearTextAtRightButtonPress) {
        [self.textView setText:nil];
    }
    
    // Clears cache
    [self clearCachedText];
    
    // Clears the undo manager
    if (self.textView.undoManagerEnabled) {
        [self.textView.undoManager removeAllActions];
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

- (void)didPasteImage:(UIImage *)image
{
    // Deprecated. User -didPasteMediaContent: instead.
}

- (void)didPasteMediaContent:(NSDictionary *)userInfo
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


#pragma mark - Private Methods

- (void)didTapScrollView:(UIGestureRecognizer *)gesture
{
    if (!self.isPresentedInPopover && !self.isExternalKeyboardDetected) {
        [self dismissKeyboard:YES];
    }
}

- (void)didPanTextView:(UIGestureRecognizer *)gesture
{
    [self presentKeyboard:YES];
}

- (void)editText:(NSString *)text
{
    if (![self.textInputbar canEditText:text]) {
        return;
    }
    
    if (!SLK_IS_LANDSCAPE) {
        [self.textView setText:text];
    }
    
    [self.textInputbar beginTextEditing];
    
    // Setting the text after calling -beginTextEditing is safer when in landscape orientation
    if (SLK_IS_LANDSCAPE) {
        [self.textView setText:text];
    }
    
    [self.textView slk_scrollToCaretPositonAnimated:YES];
    
    // Brings up the keyboard if needed
    [self presentKeyboard:YES];
}

- (void)performRightAction
{
    NSArray *actions = [self.rightButton actionsForTarget:self forControlEvent:UIControlEventTouchUpInside];
    
    if (actions.count > 0 && [self canPressRightButton]) {
        [self.rightButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)postKeyboarStatusNotification:(NSNotification *)notification
{
    if (self.isExternalKeyboardDetected || self.isRotating) {
        return;
    }
    
    NSMutableDictionary *userInfo = [notification.userInfo mutableCopy];
    
    CGRect beginFrame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Fixes iOS7 oddness with inverted values on landscape orientation
    if (!SLK_IS_IOS8_AND_HIGHER && SLK_IS_LANDSCAPE) {
        beginFrame = SLKRectInvert(beginFrame);
        endFrame = SLKRectInvert(endFrame);
    }
    
    CGFloat keyboardHeight = CGRectGetHeight(endFrame)-CGRectGetHeight(self.textView.inputAccessoryView.bounds);
    
    beginFrame.size.height = keyboardHeight;
    endFrame.size.height = keyboardHeight;
    
    [userInfo setObject:[NSValue valueWithCGRect:beginFrame] forKey:UIKeyboardFrameBeginUserInfoKey];
    [userInfo setObject:[NSValue valueWithCGRect:endFrame] forKey:UIKeyboardFrameEndUserInfoKey];
    
    NSString *name = [self appropriateKeyboardNotificationName:notification];
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self.textView userInfo:userInfo];
}

- (BOOL)scrollToTopIfNeeded
{
    if (!self.scrollViewProxy.scrollsToTop || self.keyboardStatus == SLKKeyboardStatusWillShow) {
        return NO;
    }
    
    if (self.isInverted) {
        [self.scrollViewProxy slk_scrollToTopAnimated:YES];
        return NO;
    }
    else {
        return YES;
    }
}

- (BOOL)scrollToBottomIfNeeded
{
    // Scrolls to bottom only if the keyboard is about to show.
    if (!self.shouldScrollToBottomAfterKeyboardShows || self.keyboardStatus != SLKKeyboardStatusWillShow) {
        return NO;
    }

    if (self.isInverted) {
        [self.scrollViewProxy slk_scrollToTopAnimated:YES];
    }
    else {
        [self.scrollViewProxy slk_scrollToBottomAnimated:YES];
    }
    
    return YES;
}

- (void)enableTypingSuggestionIfNeeded
{
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    BOOL enable = !self.isAutoCompleting;
    
    // Skips if the QuickType Bar isn't visible and it's trying to disable it. And the inverted logic.
    if (enable == self.textView.isTypingSuggestionEnabled) {
        return;
    }
    
    // During text autocompletion, the iOS 8 QuickType bar is hidden and auto-correction and spell checking are disabled.
    [self.textView setTypingSuggestionEnabled:enable];
}

- (void)dismissTextInputbarIfNeeded
{
    if (self.keyboardHC.constant == 0) {
        return;
    }
    
    self.keyboardHC.constant = 0.0;
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    [self hideAutoCompletionViewIfNeeded];
    
    // Forces the keyboard status change
    [self updateKeyboardStatus:SLKKeyboardStatusDidHide];
    
    [self.view layoutIfNeeded];
}

- (BOOL)detectExternalKeyboardInNotification:(NSNotification *)notification
{
    CGRect targetRect = CGRectZero;
    
    if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        targetRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    }
    else if ([notification.name isEqualToString:UIKeyboardWillHideNotification]) {
        targetRect = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    }
    
    CGRect keyboardFrame = [self.view convertRect:[self.view.window convertRect:targetRect fromWindow:nil] fromView:nil];

    if (!self.isMovingKeyboard) {
        CGFloat maxKeyboardHeight = keyboardFrame.origin.y + keyboardFrame.size.height;
        maxKeyboardHeight -= [self appropriateBottomMarginToWindow];

        return (maxKeyboardHeight > CGRectGetHeight(self.view.bounds));
    }
    else {
        return NO;
    }
}

- (void)reloadInputAccessoryViewIfNeeded
{
    // Reload only if the input views if the text view is first responder
    if (!self.isKeyboardPanningEnabled || ![self.textView isFirstResponder]) {
        
        // Disables the input accessory when not first responder so when showing the keyboard back, there is no delay in the animation
        if (self.textView.inputAccessoryView) {
            self.textView.inputAccessoryView = nil;
            [self.textView refreshInputViews];
        }
    }
    // Reload only if the input views if the frame doesn't match the text input bar's
    else if (CGRectGetHeight(self.textView.inputAccessoryView.frame) != CGRectGetHeight(self.textInputbar.bounds)) {
        self.textView.inputAccessoryView = [self emptyInputAccessoryView];
        [self.textView refreshInputViews];
    }
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


#pragma mark - Keyboard Events

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
    }
    else if (self.isEditing) {
        [self didCancelTextEditing:sender];
    }
    
    if (self.isExternalKeyboardDetected || ([self.textView isFirstResponder] && self.keyboardHC.constant == 0)) {
        return;
    }
    
    [self dismissKeyboard:YES];
}

- (void)didPressArrowKey:(id)sender
{
    [self.textView didPressAnyArrowKey:sender];
}


#pragma mark - Notification Events

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    // Skips if the view isn't visible
    if (!self.view.window) {
        return;
    }

    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }

    // Skips if textview did refresh only
    if (self.textView.didNotResignFirstResponder) {
        return;
    }
    
    // Skips this it's not the expected textView and shouldn't force adjustment of the text input bar.
    // This will also dismiss the text input bar if it's visible, and exit auto-completion mode if enabled.
    if (![self.textView isFirstResponder] && !self.shouldForceTextInputbarAdjustment) {
        return [self dismissTextInputbarIfNeeded];
    }
    
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    SLKKeyboardStatus status = [self keyboardStatusForNotification:notification];

    // Programatically stops scrolling before updating the view constraints (to avoid scrolling glitch)
    if (status == SLKKeyboardStatusWillShow) {
        [self.scrollViewProxy slk_stopScrolling];
    }
    
    // Updates the height constraints' constants
    self.keyboardHC.constant = [self appropriateKeyboardHeight:notification];
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    // Hides the autocompletion view if the keyboard is being dismissed
    if (![self.textView isFirstResponder] || status == SLKKeyboardStatusWillHide) {
        [self hideAutoCompletionViewIfNeeded];
    }
    
    // Updates and notifies about the keyboard status update
    if ([self updateKeyboardStatus:status]) {
        // Posts custom keyboard notification, if logical conditions apply
        [self postKeyboarStatusNotification:notification];
    }
    
    // Only for this animation, we set bo to bounce since we want to give the impression that the text input is glued to the keyboard.
    [self.view slk_animateLayoutIfNeededWithDuration:duration
                                              bounce:NO
                                             options:(curve<<16)|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                          animations:^{
                                              [self scrollToBottomIfNeeded];
                                          }];
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification
{
    // Skips if the view isn't visible
    if (!self.view.window) {
        return;
    }
    
    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }
    
    // Skips if textview did refresh only
    if (self.textView.didNotResignFirstResponder) {
        return;
    }
    
    SLKKeyboardStatus status = [self keyboardStatusForNotification:notification];

    // Skips if it's the current status
    if (self.keyboardStatus == status) {
        return;
    }
    
    // After showing keyboard, check if the current cursor position could diplay autocompletion
    if ([self.textView isFirstResponder] && status == SLKKeyboardStatusDidShow && !self.isAutoCompleting) {
        [self processTextForAutoCompletion];
    }
    
    // Updates and notifies about the keyboard status update
    if ([self updateKeyboardStatus:status]) {
        // Posts custom keyboard notification, if logical conditions apply
        [self postKeyboarStatusNotification:notification];
    }
    
    // Updates the dismiss mode and input accessory view, if needed.
    [self reloadInputAccessoryViewIfNeeded];

    // Very important to invalidate this flag after the keyboard is dismissed or presented
    self.movingKeyboard = NO;
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
    // Skips if the view isn't visible
    if (!self.view.window) {
        return;
    }
    
    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }
    
    // Skips this if it's not the expected textView.
    // Checking the keyboard height constant helps to disable the view constraints update on iPad when the keyboard is undocked.
    // Checking the keyboard status allows to keep the inputAccessoryView valid when still reacing the bottom of the screen.
    if (![self.textView isFirstResponder] || (self.keyboardHC.constant == 0 && self.keyboardStatus == SLKKeyboardStatusDidHide)) {
        return;
    }
    
    if (self.scrollViewProxy.isDragging) {
        self.movingKeyboard = YES;
    }

    if (self.isMovingKeyboard == NO) {
        return;
    }
    
    self.keyboardHC.constant = [self appropriateKeyboardHeight:notification];
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    if (self.isInverted && self.isMovingKeyboard && !CGPointEqualToPoint(self.scrollViewProxy.contentOffset, _draggingOffset)) {
        if (!self.scrollViewProxy.isDecelerating && self.scrollViewProxy.isTracking) {
            self.scrollViewProxy.contentOffset = _draggingOffset;
        }
    }
    
    [self.view layoutIfNeeded];
}

- (void)didPostSLKKeyboardNotification:(NSNotification *)notification
{
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    // Used for debug only
    NSLog(@"%@ didPostSLKKeyboardNotification : %@", NSStringFromClass([self class]), notification);
}

- (void)willChangeTextViewText:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    [self textWillUpdate];
}

- (void)didChangeTextViewText:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    // Animated only if the view already appeared.
    [self textDidUpdate:self.didFinishConfigurating];
}

- (void)didChangeTextViewContentSize:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    // Animated only if the view already appeared.
    [self textDidUpdate:self.didFinishConfigurating];
}

- (void)didChangeTextViewPasteboard:(NSNotification *)notification
{
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    // Notifies only if the pasted item is nested in a dictionary.
    if ([notification.userInfo isKindOfClass:[NSDictionary class]]) {
        [self didPasteMediaContent:notification.userInfo];
    }
}

- (void)didShakeTextView:(NSNotification *)notification
{
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    // Notifies of the shake gesture if undo mode is on and the text view is not empty
    if (self.shakeToClearEnabled && self.textView.text.length > 0) {
        [self willRequestUndo];
    }
}

- (void)didDeleteInTextView:(NSNotification *)notification
{
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    [self processTextForAutoCompletion];
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

- (void)willTerminateApplication:(NSNotification *)notification
{
    // Caches the text before it's too late!
    [self cacheTextView];
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
    if (self.isRotating || self.textView.isFastDeleting) {
        return;
    }
    
    // Avoids text processing for autocompletion if the registered prefix list is empty.
    if (self.registeredPrefixes.count == 0) {
        return;
    }
    
    NSString *text = self.textView.text;
    
    // No need to process for autocompletion if there is no text to process
    if (text.length == 0) {
        return [self cancelAutoCompletion];
    }
    
    // Process in the background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
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
        
        // Forward to the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleProcessedWord:word range:range];
        });
    });
}

- (void)handleProcessedWord:(NSString *)word range:(NSRange)range
{
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
            if ([self.foundWord rangeOfString:self.foundPrefix].location != NSNotFound) {
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
    
    [self showAutoCompletionView:[self canShowAutoCompletion]];
}

- (void)cancelAutoCompletion
{
    _foundPrefix = nil;
    _foundWord = nil;
    _foundPrefixRange = NSMakeRange(0,0);
    
    [self.autoCompletionView setContentOffset:CGPointZero];
    
    [self hideAutoCompletionViewIfNeeded];
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

- (void)hideAutoCompletionViewIfNeeded
{
    if (self.isAutoCompleting) {
        [self showAutoCompletionView:NO];
    }
}

- (void)showAutoCompletionView:(BOOL)show
{
    // Skips if rotating
    if (self.isRotating) {
        return;
    }
    
    CGFloat viewHeight = show ? [self heightForAutoCompletionView] : 0.0;
    
    if (self.autoCompletionViewHC.constant == viewHeight) {
        return;
    }
    
    if (show) {
        // Reload the tableview before showing it
        [self.autoCompletionView reloadData];
        [self.autoCompletionView setContentOffset:CGPointZero];
    }
    
    // If the autocompletion view height is bigger than the maximum height allows, it is reduce to that size. Default 140 pts.
    if (viewHeight > [self maximumHeightForAutoCompletionView]) {
        viewHeight = [self maximumHeightForAutoCompletionView];
    }
    
    CGFloat tableHeight = self.scrollViewHC.constant + self.autoCompletionViewHC.constant;
    
    // Only when the view extends its layout beyond it top edge
    if ((self.edgesForExtendedLayout & UIRectEdgeTop) > 0) {
        
        // On iOS7, the status bar isn't automatically hidden on landscape orientation
        if (SLK_IS_IPHONE && SLK_IS_LANDSCAPE && !SLK_IS_IOS8_AND_HIGHER) {
            tableHeight -= CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        }
        
        tableHeight -= CGRectGetHeight(self.navigationController.navigationBar.frame);
    }
    
    // On iPhone, the autocompletion view can't extend beyond the table view height
    if (SLK_IS_IPHONE && viewHeight > tableHeight) {
        viewHeight = tableHeight;
    }
    
    self.autoCompletionViewHC.constant = viewHeight;
    self.autoCompleting = show;
    
    // Toggles auto-correction if requiered
    [self enableTypingSuggestionIfNeeded];
    
	[self.view slk_animateLayoutIfNeededWithBounce:self.bounces
										   options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
										animations:NULL];
}


#pragma mark - Text Caching

- (NSString *)keyForTextCaching
{
    // No implementation here. Meant to be overriden in subclass.
    return nil;
}

- (NSString *)keyForPersistency
{
    NSString *keyForTextCaching = [self keyForTextCaching];
    NSString *previousCachedText = [[NSUserDefaults standardUserDefaults] objectForKey:keyForTextCaching];
    
    if ([previousCachedText isKindOfClass:[NSString class]]) {
        return keyForTextCaching;
    }
    else {
        return [NSString stringWithFormat:@"%@.%@", SLKTextViewControllerDomain, [self keyForTextCaching]];
    }
}

- (void)reloadTextView
{
    if (self.textView.text.length > 0 || !self.isCachingEnabled) {
        return;
    }

    self.textView.text = [self cachedText];
}

- (void)cacheTextView
{
    [self cacheTextToDisk:self.textView.text];
}

- (void)clearCachedText
{
    [self cacheTextToDisk:nil];
}

+ (void)clearAllCachedText
{
    NSMutableArray *cachedKeys = [NSMutableArray new];
    
    for (NSString *key in [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys]) {
        if ([key rangeOfString:SLKTextViewControllerDomain].location != NSNotFound) {
            [cachedKeys addObject:key];
        }
    }
    
    if (cachedKeys.count == 0) {
        return;
    }
    
    for (NSString *cachedKey in cachedKeys) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:cachedKey];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isCachingEnabled
{
    return ([self keyForTextCaching] != nil);
}

- (NSString *)cachedText
{
    if (!self.isCachingEnabled) {
        return nil;
    }
    
    NSString *key = [self keyForPersistency];
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)cacheTextToDisk:(NSString *)text
{
    if (!self.isCachingEnabled) {
        return;
    }
    
    NSString *cachedText = [self cachedText];
    NSString *key = [self keyForPersistency];

    // Caches text only if its a valid string and not already cached
    if (text.length > 0 && ![text isEqualToString:cachedText]) {
        [[NSUserDefaults standardUserDefaults] setObject:text forKey:key];
    }
    // Clears cache only if it exists
    else if (text.length == 0 && cachedText.length > 0) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    else {
        // Skips so it doesn't hit 'synchronize' unnecessarily
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - UITextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    self.newWordInserted = ([text rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound);
    
    // Records text for undo for every new word
    if (self.newWordInserted) {
        [self.textView prepareForUndo:@"Word Change"];
    }
    
    if ([text isEqualToString:@"\n"]) {
        //Detected break. Should insert new line break manually.
        [textView slk_insertNewLineBreak];
        
        return NO;
    }
    else {
        NSDictionary *userInfo = @{@"text": text, @"range": [NSValue valueWithRange:range]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewTextWillChangeNotification object:self.textView userInfo:userInfo];
        
        return YES;
    }
}

- (void)textViewDidChangeSelection:(SLKTextView *)textView
{
    // The text view must be first responder
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    // Skips if the loupe is visible or if there is a real text selection
    if (textView.isLoupeVisible || self.textView.selectedRange.length > 0) {
        return;
    }
    
    // Process the text at every caret movement
    [self processTextForAutoCompletion];
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

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    return [self scrollToTopIfNeeded];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.movingKeyboard = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.movingKeyboard = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.isMovingKeyboard) {
        _draggingOffset = scrollView.contentOffset;
    }
}


#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture
{
    if ([gesture isEqual:self.singleTapGesture]) {
        return [self.textView isFirstResponder] && !self.isExternalKeyboardDetected;
    }
    else if ([gesture isEqual:self.verticalPanGesture]) {
        
        if ([self.textView isFirstResponder]) {
            return NO;
        }
        
        CGPoint velocity = [self.verticalPanGesture velocityInView:self.view];
        
        // Vertical panning, from bottom to top only
        if (velocity.y < 0 && ABS(velocity.y) > ABS(velocity.x) && ![self.textInputbar.textView isFirstResponder]) {
            return YES;
        }
    }
    
    return NO;
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
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView(0@750)][autoCompletionView(0@750)][typingIndicatorView(0)]-0@999-[textInputbar(>=0)]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[autoCompletionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[typingIndicatorView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textInputbar]|" options:0 metrics:nil views:views]];
    
    self.scrollViewHC = [self.view slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.scrollViewProxy secondItem:nil];
    self.autoCompletionViewHC = [self.view slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.autoCompletionView secondItem:nil];
    self.typingIndicatorViewHC = [self.view slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.typingIndicatorView secondItem:nil];
    self.textInputbarHC = [self.view slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.textInputbar secondItem:nil];
    self.keyboardHC = [self.view slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self.view secondItem:self.textInputbar];
    
    self.textInputbarHC.constant = [self minimumInputbarHeight];
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];

    if (self.isEditing) {
        self.textInputbarHC.constant += self.textInputbar.accessoryViewHeight;
    }
}


#pragma mark - External Keyboard Support

- (NSArray *)keyCommands
{
    if (_keyboardCommands) {
        return _keyboardCommands;
    }
    
    _keyboardCommands = @[
          // Pressing Return key
          [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(didPressReturnKey:)],
          // Pressing Esc key
          [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:@selector(didPressEscapeKey:)],
          
          // Up/Down
          [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didPressArrowKey:)],
          [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(didPressArrowKey:)],
          [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(didPressArrowKey:)],
          [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(didPressArrowKey:)]
          ];
    
    return _keyboardCommands;
}


#pragma mark - NSNotificationCenter register/unregister

- (void)registerNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
    
#if SLK_KEYBOARD_NOTIFICATION_DEBUG
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPostSLKKeyboardNotification:) name:SLKKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPostSLKKeyboardNotification:) name:SLKKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPostSLKKeyboardNotification:) name:SLKKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPostSLKKeyboardNotification:) name:SLKKeyboardDidHideNotification object:nil];
#endif
    
    // Keyboard Accessory View notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeyboardFrame:) name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];

    // TextView notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeTextViewText:) name:SLKTextViewTextWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewContentSize:) name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewPasteboard:) name:SLKTextViewDidPasteItemNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShakeTextView:) name:SLKTextViewDidShakeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteInTextView:) name:SLKTextViewDidFinishDeletingNotification object:nil];

    // TypeIndicator notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideTypeIndicatorView:) name:SLKTypingIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideTypeIndicatorView:) name:SLKTypingIndicatorViewWillHideNotification object:nil];
    
    // Application notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminateApplication:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willTerminateApplication:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)unregisterNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
#if SLK_KEYBOARD_NOTIFICATION_DEBUG
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKKeyboardDidHideNotification object:nil];
#endif
    
    // TextView notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    
    // TextView notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewTextWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewDidPasteItemNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewDidShakeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewDidFinishDeletingNotification object:nil];

    // TypeIndicator notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTypingIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTypingIndicatorViewWillHideNotification object:nil];
    
    // Application notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}


#pragma mark - View Auto-Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.rotating = YES;
    
    [self prepareForInterfaceRotation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Delays the rotation flag
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.rotating = NO;
    });
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
    _keyboardCommands = nil;

    _singleTapGesture = nil;
    _verticalPanGesture = nil;
    _scrollViewHC = nil;
    _textInputbarHC = nil;
    _textInputbarHC = nil;
    _typingIndicatorViewHC = nil;
    _autoCompletionViewHC = nil;
    _keyboardHC = nil;
    
    [self unregisterNotifications];
}

@end
