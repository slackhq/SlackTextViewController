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

#import <objc/runtime.h>

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
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

// The keyboard commands available for external keyboards
@property (nonatomic, strong) NSArray *keyboardCommands;

// YES if the user is moving the keyboard with a gesture
@property (nonatomic, getter = isMovingKeyboard) BOOL movingKeyboard;

// The current QuicktypeBar mode (hidden, collapsed or expanded)
@property (nonatomic) SLKQuicktypeBarMode quicktypeBarMode;

// The current keyboard status (hidden, showing, etc.)
@property (nonatomic) SLKKeyboardStatus keyboardStatus;

// YES if a new word has been typed recently
@property (nonatomic) BOOL newWordInserted;

// YES if the view controller did appear and everything is finished configurating. This allows blocking some layout animations among other things.
@property (nonatomic) BOOL didFinishConfigurating;

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
    return [self init];
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
        [self tableViewWithStyle:style];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    NSAssert([self class] != [SLKTextViewController class], @"Oops! You must subclass SLKTextViewController.");
    
    if (self = [super initWithNibName:nil bundle:nil])
    {
        [self collectionViewWithLayout:layout];
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
            [self collectionViewWithLayout:collectionViewLayout];
        }
        else if (tableViewStyle == UITableViewStylePlain || tableViewStyle == UITableViewStyleGrouped) {
            [self tableViewWithStyle:tableViewStyle];
        }
        else {
            return nil;
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
    self.undoShakingEnabled = NO;
    self.keyboardPanningEnabled = YES;
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
        
    [self.view addSubview:self.scrollViewProxy];
    [self.view addSubview:self.autoCompletionView];
    [self.view addSubview:self.typingIndicatorView];
    [self.view addSubview:self.textInputbar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    self.didFinishConfigurating = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Stops the keyboard from being dismissed during the navigation controller's "swipe-to-pop"
    self.textView.didNotResignFirstResponder = self.isMovingFromParentViewController;
    
    self.didFinishConfigurating = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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
        
        [self setScrollViewProxy:self.tableView];
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
        
        [self setScrollViewProxy:self.collectionView];
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
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanTextView:)];
        self.panGesture.delegate = self;
        [_textInputbar.textView addGestureRecognizer:self.panGesture];
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

- (BOOL)isPresentedInPopover
{
    return _presentedInPopover && UI_IS_IPAD;
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
    if (!self.keyboardPanningEnabled) {
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
    
    [self checkForExternalKeyboardInNotification:notification];
    
    // Return 0 if an external keyboard has been detected
    if (self.isExternalKeyboardDetected) {
        return 0.0;
    }
    
    CGFloat keyboardHeight = 0.0;
    CGFloat tabBarHeight = ([self.tabBarController.tabBar isHidden] || self.hidesBottomBarWhenPushed) ? 0.0 : CGRectGetHeight(self.tabBarController.tabBar.frame);
    
    // The height of the keyboard
    if (!UI_IS_IOS8_AND_HIGHER && [notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        keyboardHeight = MIN(CGRectGetWidth(endFrame), CGRectGetHeight(endFrame));
    }
    else {
        if (!UI_IS_IOS8_AND_HIGHER && UI_IS_LANDSCAPE) {
            keyboardHeight = MIN(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
            keyboardHeight -= MAX(endFrame.origin.x, endFrame.origin.y);
        }
        else {
            keyboardHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
            keyboardHeight -= endFrame.origin.y;
        }
    }
    
    keyboardHeight -= tabBarHeight;
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


#pragma mark - Setters

- (void)setScrollViewProxy:(UIScrollView *)scrollView
{
    if (self.scrollViewProxy) {
        return;
    }
    
    _scrollViewProxy = scrollView;
    
    _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapScrollView:)];
    _singleTapGesture.delegate = self;
    [_scrollViewProxy addGestureRecognizer:self.singleTapGesture];
}

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
    
    if (UI_IS_IOS8_AND_HIGHER)
    {
        // Updates the iOS8 QuickType bar mode based on the keyboard height constant
        CGFloat quicktypeBarHeight = self.keyboardHC.constant-minimumKeyboardHeight();
        
        // Updates the QuickType bar mode based on the keyboard height constant
        self.quicktypeBarMode = SLKQuicktypeBarModeForHeight(quicktypeBarHeight);
    }
    // On iOS7, it should always disable auto-correction and spell checking if autocompletion is enabled.
    else {
        [self.textView setTypingSuggestionEnabled:!autoCompleting];
    }
}

- (void)setQuicktypeBarMode:(SLKQuicktypeBarMode)mode
{
    _quicktypeBarMode = mode;
    
    // Skips if the QuickType Bar is minimised
    if (mode != SLKQuicktypeBarModeCollapsed) {
        
        // When predictive mode is enabled, the QuicktypeBar is hidden
        // Spelling check is also disabled
        [self.textView setTypingSuggestionEnabled:!self.autoCompleting];
    }
}

- (void)setKeyboardPanningEnabled:(BOOL)enabled
{
    if (self.keyboardPanningEnabled == enabled) {
        return;
    }
    
    _keyboardPanningEnabled = enabled;
    
    if (enabled) {
        self.scrollViewProxy.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeyboardFrame:) name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    }
    else {
        self.scrollViewProxy.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
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
    
    // Only updates the input view if the number of line changed
    [self reloadInputAccessoryViewIfNeeded];
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


#pragma mark - Private Actions

- (void)didTapScrollView:(UIGestureRecognizer *)gesture
{
    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }
    
    // Skips if using an external keyboard
    if (self.isExternalKeyboardDetected) {
        return;
    }
    
    [self dismissKeyboard:YES];
}

- (void)didPanTextView:(id)sender
{
    // Skips if the text view is already first responder
    if ([self.textView isFirstResponder]) {
        return;
    }
    
    // Become first responder and enable keyboard
    [self.textView becomeFirstResponder];
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

- (void)postKeyboarStatusNotification:(NSNotification *)notification
{
    NSMutableDictionary *userInfo = [notification.userInfo mutableCopy];
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    endFrame.size.height = self.keyboardHC.constant;
    [userInfo setObject:[NSValue valueWithCGRect:endFrame] forKey:UIKeyboardFrameEndUserInfoKey];
    
    NSString *name = [self appropriateKeyboardNotificationName:notification];
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:userInfo];
}

- (void)checkForExternalKeyboardInNotification:(NSNotification *)notification
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
        
        // Reduces the tab bar height (if it's visible)
        CGFloat tabBarHeight = ([self.tabBarController.tabBar isHidden] || self.hidesBottomBarWhenPushed) ? 0.0 : CGRectGetHeight(self.tabBarController.tabBar.frame);
        maxKeyboardHeight -= tabBarHeight;
        
        _externalKeyboardDetected = maxKeyboardHeight > CGRectGetHeight(self.view.bounds);
    }
    
    if (CGRectIsNull(keyboardFrame)) {
        _externalKeyboardDetected = NO;
    }
}

- (void)reloadInputAccessoryViewIfNeeded
{
    // Reload only if the input views if the text view is first responder
    if (!self.keyboardPanningEnabled || ![self.textView isFirstResponder]) {
        
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
        return;
    }
    
    if (self.isEditing) {
        [self didCancelTextEditing:sender];
        return;
    }
    
    [self dismissKeyboard:YES];
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
    if (willShow) {
        [self.scrollViewProxy slk_stopScrolling];
    }
    
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
    [self postKeyboarStatusNotification:notification];
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
    if (didShow && !self.isAutoCompleting) {
        [self processTextForAutoCompletion];
    }
    
    // Reloads the input accessory view
    [self reloadInputAccessoryViewIfNeeded];
    
    // Updates and notifies about the keyboard status update
    self.keyboardStatus = didShow ? SLKKeyboardStatusDidShow : SLKKeyboardStatusDidHide;
    [self postKeyboarStatusNotification:notification];
    
    // Very important to invalidate this flag back
    self.movingKeyboard = NO;
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
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
    
    self.movingKeyboard = self.scrollViewProxy.isDragging;
    
    if (!self.movingKeyboard) {
        return;
    }
    
    self.keyboardHC.constant = [self appropriateKeyboardHeight:notification];
    self.scrollViewHC.constant = [self appropriateScrollViewHeight];
    
    if (self.isInverted && self.isMovingKeyboard && !CGPointEqualToPoint(self.scrollViewProxy.contentOffset, _draggingOffset)) {
        if (!self.scrollViewProxy.isDecelerating) {
            self.scrollViewProxy.contentOffset = _draggingOffset;
        }
    }
    
    [self.view layoutIfNeeded];
}

- (void)willChangeTextViewText:(NSNotification *)notification
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
    
    // Animated only if the view already appeared
    [self textDidUpdate:self.didFinishConfigurating];
}

- (void)didChangeTextViewContentSize:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![self.textView isEqual:notification.object]) {
        return;
    }
    
    // Animated only if the view already appeared
    [self textDidUpdate:self.didFinishConfigurating];
}

- (void)didChangeTextViewPasteboard:(NSNotification *)notification
{
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    // Notifies only if the pasted item is nested in a dictionary
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
    if (self.undoShakingEnabled && self.textView.text.length > 0) {
        [self willRequestUndo];
    }
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
    
    // Process in the background
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
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
    
    BOOL canShow = [self canShowAutoCompletion];
    
    // Reload the tableview before showing it
    [self.autoCompletionView reloadData];
    [self.autoCompletionView setContentOffset:CGPointZero];
    
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


#pragma mark - UITextViewDelegate Methods

- (BOOL)textViewShouldBeginEditing:(SLKTextView *)textView
{
    return YES;
}

- (BOOL)textViewShouldEndEditing:(SLKTextView *)textView
{
    return YES;
}

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
    if (!self.scrollViewProxy.scrollsToTop) {
        return NO;
    }
    
    if (self.isInverted) {
        [scrollView slk_scrollToBottomAnimated:YES];
        return NO;
    }
    else {
        return ![scrollView slk_isAtTop];
    }
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
        return [self.textInputbar.textView isFirstResponder];
    }
    
    if ([gesture isEqual:self.panGesture]) {
        
        if ([self.textView isFirstResponder]) {
            return NO;
        }
        
        CGPoint velocity = [self.panGesture velocityInView:self.view];
        
        // Vertical panning, from bottom to top only
        if (velocity.y < 0 && ABS(velocity.y) > ABS(velocity.x) && ![self.textInputbar.textView isFirstResponder]) {
            return YES;
        }
        return NO;
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
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView(0@750)][autoCompletionView(0)][typingIndicatorView(0)]-0@999-[textInputbar(>=0)]|" options:0 metrics:nil views:views]];
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
          [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:@selector(didPressEscapeKey:)]
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
    
    // TextView notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeTextViewText:) name:SLKTextViewTextWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewContentSize:) name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextViewPasteboard:) name:SLKTextViewDidPasteItemNotification object:nil];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewDidPasteItemNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewDidShakeNotification object:nil];
    
    // TypeIndicator notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTypingIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTypingIndicatorViewWillHideNotification object:nil];
}


#pragma mark - View Auto-Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
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
