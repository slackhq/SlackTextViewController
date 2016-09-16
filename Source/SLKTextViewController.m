//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTextViewController.h"
#import "SLKInputAccessoryView.h"

#import "UIResponder+SLKAdditions.h"
#import "SLKUIConstants.h"

/** Feature flagged while waiting to implement a more reliable technique. */
#define SLKBottomPanningEnabled 0

#define kSLKAlertViewClearTextTag [NSStringFromClass([SLKTextViewController class]) hash]

NSString * const SLKKeyboardWillShowNotification =      @"SLKKeyboardWillShowNotification";
NSString * const SLKKeyboardDidShowNotification =       @"SLKKeyboardDidShowNotification";
NSString * const SLKKeyboardWillHideNotification =      @"SLKKeyboardWillHideNotification";
NSString * const SLKKeyboardDidHideNotification =       @"SLKKeyboardDidHideNotification";

CGFloat const SLKAutoCompletionViewDefaultHeight = 140.0;

@interface SLKTextViewController ()
{
    CGPoint _scrollViewOffsetBeforeDragging;
    CGFloat _keyboardHeightBeforeDragging;
}

// The shared scrollView pointer, either a tableView or collectionView
@property (nonatomic, weak) UIScrollView *scrollViewProxy;

// A hairline displayed on top of the auto-completion view, to better separate the content from the control.
@property (nonatomic, strong) UIView *autoCompletionHairline;

// Auto-Layout height constraints used for updating their constants
@property (nonatomic, strong) NSLayoutConstraint *scrollViewHC;
@property (nonatomic, strong) NSLayoutConstraint *textInputbarHC;
@property (nonatomic, strong) NSLayoutConstraint *typingIndicatorViewHC;
@property (nonatomic, strong) NSLayoutConstraint *autoCompletionViewHC;
@property (nonatomic, strong) NSLayoutConstraint *keyboardHC;

// YES if the user is moving the keyboard with a gesture
@property (nonatomic, assign, getter = isMovingKeyboard) BOOL movingKeyboard;

// YES if the view controller did appear and everything is finished configurating. This allows blocking some layout animations among other things.
@property (nonatomic, getter=isViewVisible) BOOL viewVisible;

// YES if the view controller's view's size is changing by its parent (i.e. when its window rotates or is resized)
@property (nonatomic, getter = isTransitioning) BOOL transitioning;

// Optional classes to be used instead of the default ones.
@property (nonatomic, strong) Class textViewClass;
@property (nonatomic, strong) Class typingIndicatorViewClass;

@end

@implementation SLKTextViewController
@synthesize tableView = _tableView;
@synthesize collectionView = _collectionView;
@synthesize scrollView = _scrollView;
@synthesize typingIndicatorProxyView = _typingIndicatorProxyView;
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
    NSAssert(style == UITableViewStylePlain || style == UITableViewStyleGrouped, @"Oops! You must pass a valid UITableViewStyle.");

    if (self = [super initWithNibName:nil bundle:nil])
    {
        self.scrollViewProxy = [self tableViewWithStyle:style];
        [self slk_commonInit];
    }
    return self;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    NSAssert([self class] != [SLKTextViewController class], @"Oops! You must subclass SLKTextViewController.");
    NSAssert([layout isKindOfClass:[UICollectionViewLayout class]], @"Oops! You must pass a valid UICollectionViewLayout object.");

    if (self = [super initWithNibName:nil bundle:nil])
    {
        self.scrollViewProxy = [self collectionViewWithLayout:layout];
        [self slk_commonInit];
    }
    return self;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
    NSAssert([self class] != [SLKTextViewController class], @"Oops! You must subclass SLKTextViewController.");
    NSAssert([scrollView isKindOfClass:[UIScrollView class]], @"Oops! You must pass a valid UIScrollView object.");

    if (self = [super initWithNibName:nil bundle:nil])
    {
        _scrollView = scrollView;
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO; // Makes sure the scrollView plays nice with auto-layout
        
        self.scrollViewProxy = _scrollView;
        [self slk_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    NSAssert([self class] != [SLKTextViewController class], @"Oops! You must subclass SLKTextViewController.");
    NSAssert([decoder isKindOfClass:[NSCoder class]], @"Oops! You must pass a valid decoder object.");

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
        
        [self slk_commonInit];
    }
    return self;
}

- (void)slk_commonInit
{
    [self slk_registerNotifications];
    
    self.bounces = YES;
    self.inverted = YES;
    self.shakeToClearEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.shouldClearTextAtRightButtonPress = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.scrollViewProxy];
    [self.view addSubview:self.autoCompletionView];
    [self.view addSubview:self.typingIndicatorProxyView];
    [self.view addSubview:self.textInputbar];
    
    [self slk_setupViewConstraints];
    
    [self slk_registerKeyCommands];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Invalidates this flag when the view appears
    self.textView.didNotResignFirstResponder = NO;
    
    // Forces laying out the recently added subviews and update their constraints
    [self.view layoutIfNeeded];
    
    [UIView performWithoutAnimation:^{
        // Reloads any cached text
        [self slk_reloadTextView];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.scrollViewProxy flashScrollIndicators];
    
    self.viewVisible = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Stops the keyboard from being dismissed during the navigation controller's "swipe-to-pop"
    self.textView.didNotResignFirstResponder = self.isMovingFromParentViewController;
    
    self.viewVisible = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Caches the text before it's too late!
    [self cacheTextView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self slk_adjustContentConfigurationIfNeeded];
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
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:style];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.scrollsToTop = YES;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.clipsToBounds = NO;
    }
    return _tableView;
}

- (UICollectionView *)collectionViewWithLayout:(UICollectionViewLayout *)layout
{
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionView.scrollsToTop = YES;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
    }
    return _collectionView;
}

- (UITableView *)autoCompletionView
{
    if (!_autoCompletionView) {
        _autoCompletionView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _autoCompletionView.translatesAutoresizingMaskIntoConstraints = NO;
        _autoCompletionView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        _autoCompletionView.scrollsToTop = NO;
        _autoCompletionView.dataSource = self;
        _autoCompletionView.delegate = self;
        
#ifdef __IPHONE_9_0
        if ([_autoCompletionView respondsToSelector:@selector(cellLayoutMarginsFollowReadableWidth)]) {
            _autoCompletionView.cellLayoutMarginsFollowReadableWidth = NO;
        }
#endif
        
        CGRect rect = CGRectZero;
        rect.size = CGSizeMake(CGRectGetWidth(self.view.frame), 0.5);
        
        _autoCompletionHairline = [[UIView alloc] initWithFrame:rect];
        _autoCompletionHairline.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _autoCompletionHairline.backgroundColor = _autoCompletionView.separatorColor;
        [_autoCompletionView addSubview:_autoCompletionHairline];
    }
    return _autoCompletionView;
}

- (SLKTextInputbar *)textInputbar
{
    if (!_textInputbar) {
        _textInputbar = [[SLKTextInputbar alloc] initWithTextViewClass:self.textViewClass];
        _textInputbar.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_textInputbar.leftButton addTarget:self action:@selector(didPressLeftButton:) forControlEvents:UIControlEventTouchUpInside];
        [_textInputbar.rightButton addTarget:self action:@selector(didPressRightButton:) forControlEvents:UIControlEventTouchUpInside];
        [_textInputbar.editorLeftButton addTarget:self action:@selector(didCancelTextEditing:) forControlEvents:UIControlEventTouchUpInside];
        [_textInputbar.editorRightButton addTarget:self action:@selector(didCommitTextEditing:) forControlEvents:UIControlEventTouchUpInside];
        
        _textInputbar.textView.delegate = self;
        
        _verticalPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(slk_didPanTextInputBar:)];
        _verticalPanGesture.delegate = self;
        
        [_textInputbar addGestureRecognizer:self.verticalPanGesture];
    }
    return _textInputbar;
}

- (UIView <SLKTypingIndicatorProtocol> *)typingIndicatorProxyView
{
    if (!_typingIndicatorProxyView) {
        Class class = self.typingIndicatorViewClass ? : [SLKTypingIndicatorView class];
        
        _typingIndicatorProxyView = [[class alloc] init];
        _typingIndicatorProxyView.translatesAutoresizingMaskIntoConstraints = NO;
        _typingIndicatorProxyView.hidden = YES;
        
        [_typingIndicatorProxyView addObserver:self forKeyPath:@"visible" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _typingIndicatorProxyView;
}

- (SLKTypingIndicatorView *)typingIndicatorView
{
    if ([_typingIndicatorProxyView isKindOfClass:[SLKTypingIndicatorView class]]) {
        return (SLKTypingIndicatorView *)self.typingIndicatorProxyView;
    }
    return nil;
}

- (BOOL)isPresentedInPopover
{
    return _presentedInPopover && SLK_IS_IPAD;
}

- (BOOL)isTextInputbarHidden
{
    return _textInputbar.hidden;
}

- (SLKTextView *)textView
{
    return _textInputbar.textView;
}

- (UIButton *)leftButton
{
    return _textInputbar.leftButton;
}

- (UIButton *)rightButton
{
    return _textInputbar.rightButton;
}

- (UIModalPresentationStyle)modalPresentationStyle
{
    if (self.navigationController) {
        return self.navigationController.modalPresentationStyle;
    }
    return [super modalPresentationStyle];
}

- (CGFloat)slk_appropriateKeyboardHeightFromNotification:(NSNotification *)notification
{
    // Let's first detect keyboard special states such as external keyboard, undocked or split layouts.
    [self slk_detectKeyboardStatesInNotification:notification];
    
    if ([self ignoreTextInputbarAdjustment]) {
        return [self slk_appropriateBottomMargin];
    }
    
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    return [self slk_appropriateKeyboardHeightFromRect:keyboardRect];
}

- (CGFloat)slk_appropriateKeyboardHeightFromRect:(CGRect)rect
{
    CGRect keyboardRect = [self.view convertRect:rect fromView:nil];
    
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    CGFloat keyboardMinY = CGRectGetMinY(keyboardRect);
    
    CGFloat keyboardHeight = MAX(0.0, viewHeight - keyboardMinY);
    CGFloat bottomMargin = [self slk_appropriateBottomMargin];
    
    // When the keyboard height is zero, we can assume there is no keyboard visible
    // In that case, let's see if there are any other views outside of the view hiearchy
    // requiring to adjust the text input bottom margin
    if (keyboardHeight < bottomMargin) {
        keyboardHeight = bottomMargin;
    }
    
    return keyboardHeight;
}

- (CGFloat)slk_appropriateBottomMargin
{
    // A bottom margin is required only if the view is extended out of it bounds
    if ((self.edgesForExtendedLayout & UIRectEdgeBottom) > 0) {
        
        UITabBar *tabBar = self.tabBarController.tabBar;
        
        // Considers the bottom tab bar, unless it will be hidden
        if (tabBar && !tabBar.hidden && !self.hidesBottomBarWhenPushed) {
            return CGRectGetHeight(tabBar.frame);
        }
    }
    
    return 0.0;
}

- (CGFloat)slk_appropriateScrollViewHeight
{
    CGFloat scrollViewHeight = CGRectGetHeight(self.view.bounds);
    
    scrollViewHeight -= self.keyboardHC.constant;
    scrollViewHeight -= self.textInputbarHC.constant;
    scrollViewHeight -= self.autoCompletionViewHC.constant;
    scrollViewHeight -= self.typingIndicatorViewHC.constant;
    
    if (scrollViewHeight < 0) return 0;
    else return scrollViewHeight;
}

- (CGFloat)slk_topBarsHeight
{
    // No need to adjust if the edge isn't available
    if ((self.edgesForExtendedLayout & UIRectEdgeTop) == 0) {
        return 0.0;
    }
    
    CGFloat topBarsHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    
    if ((SLK_IS_IPHONE && SLK_IS_LANDSCAPE && SLK_IS_IOS8_AND_HIGHER) ||
        (SLK_IS_IPAD && self.modalPresentationStyle == UIModalPresentationFormSheet) ||
        self.isPresentedInPopover) {
        return topBarsHeight;
    }
    
    topBarsHeight += CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    
    return topBarsHeight;
}

- (NSString *)slk_appropriateKeyboardNotificationName:(NSNotification *)notification
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

- (SLKKeyboardStatus)slk_keyboardStatusForNotification:(NSNotification *)notification
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

- (BOOL)slk_isIllogicalKeyboardStatus:(SLKKeyboardStatus)newStatus
{
    if ((self.keyboardStatus == SLKKeyboardStatusDidHide && newStatus == SLKKeyboardStatusWillShow) ||
        (self.keyboardStatus == SLKKeyboardStatusWillShow && newStatus == SLKKeyboardStatusDidShow) ||
        (self.keyboardStatus == SLKKeyboardStatusDidShow && newStatus == SLKKeyboardStatusWillHide) ||
        (self.keyboardStatus == SLKKeyboardStatusWillHide && newStatus == SLKKeyboardStatusDidHide)) {
        return NO;
    }
    return YES;
}


#pragma mark - Setters

- (void)setEdgesForExtendedLayout:(UIRectEdge)rectEdge
{
    if (self.edgesForExtendedLayout == rectEdge) {
        return;
    }
    
    [super setEdgesForExtendedLayout:rectEdge];
    
    [self slk_updateViewConstraints];
}

- (void)setScrollViewProxy:(UIScrollView *)scrollView
{
    if ([_scrollViewProxy isEqual:scrollView]) {
        return;
    }
    
    _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(slk_didTapScrollView:)];
    _singleTapGesture.delegate = self;
    [_singleTapGesture requireGestureRecognizerToFail:scrollView.panGestureRecognizer];
    
    [scrollView addGestureRecognizer:self.singleTapGesture];
    
    [scrollView.panGestureRecognizer addTarget:self action:@selector(slk_didPanTextInputBar:)];
    
    _scrollViewProxy = scrollView;
}

- (void)setAutoCompleting:(BOOL)autoCompleting
{
    if (_autoCompleting == autoCompleting) {
        return;
    }
    
    _autoCompleting = autoCompleting;
    
    self.scrollViewProxy.scrollEnabled = !autoCompleting;
}

- (void)setInverted:(BOOL)inverted
{
    if (_inverted == inverted) {
        return;
    }
    
    _inverted = inverted;
    
    self.scrollViewProxy.transform = inverted ? CGAffineTransformMake(1, 0, 0, -1, 0, 0) : CGAffineTransformIdentity;
}

- (void)setBounces:(BOOL)bounces
{
    _bounces = bounces;
    _textInputbar.bounces = bounces;
}

- (BOOL)slk_updateKeyboardStatus:(SLKKeyboardStatus)status
{
    // Skips if trying to update the same status
    if (_keyboardStatus == status) {
        return NO;
    }
    
    // Skips illogical conditions
    // Forces the keyboard status when didHide to avoid any inconsistency.
    if (status != SLKKeyboardStatusDidHide && [self slk_isIllogicalKeyboardStatus:status]) {
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
    // Dismisses the keyboard from any first responder in the window.
    if (![self.textView isFirstResponder] && self.keyboardHC.constant > 0) {
        [self.view.window endEditing:NO];
    }
    
    if (!animated) {
        [UIView performWithoutAnimation:^{
            [self.textView resignFirstResponder];
        }];
    }
    else {
        [self.textView resignFirstResponder];
    }
}

- (BOOL)forceTextInputbarAdjustmentForResponder:(UIResponder *)responder
{
    return NO;
}

- (BOOL)ignoreTextInputbarAdjustment
{
    if (self.isExternalKeyboardDetected || self.isKeyboardUndocked) {
        return YES;
    }
    
    return NO;
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
    if (self.isTextInputbarHidden) {
        return;
    }
    
    CGFloat inputbarHeight = _textInputbar.appropriateHeight;
    
    _textInputbar.rightButton.enabled = [self canPressRightButton];
    _textInputbar.editorRightButton.enabled = [self canPressRightButton];
    
    if (inputbarHeight != self.textInputbarHC.constant)
    {
        self.textInputbarHC.constant = inputbarHeight;
        self.scrollViewHC.constant = [self slk_appropriateScrollViewHeight];
        
        if (animated) {
            
            BOOL bounces = self.bounces && [self.textView isFirstResponder];
            
            __weak typeof(self) weakSelf = self;
            
            [self.view slk_animateLayoutIfNeededWithBounce:bounces
                                                   options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                                animations:^{
                                                    if (weakSelf.textInputbar.isEditing) {
                                                        [weakSelf.textView slk_scrollToCaretPositonAnimated:NO];
                                                    }
                                                }];
        }
        else {
            [self.view layoutIfNeeded];
        }
    }
    
    // Toggles auto-correction if requiered
    [self slk_enableTypingSuggestionIfNeeded];
}

- (void)textSelectionDidChange
{
    // The text view must be first responder
    if (![self.textView isFirstResponder] || self.keyboardStatus != SLKKeyboardStatusDidShow) {
        return;
    }
    
    // Skips there is a real text selection
    if (self.textView.isTrackpadEnabled) {
        return;
    }
    
    if (self.textView.selectedRange.length > 0) {
        if (self.isAutoCompleting && [self shouldProcessTextForAutoCompletion:self.textView.text]) {
            [self cancelAutoCompletion];
        }
        return;
    }
    
    // Process the text at every caret movement
    [self slk_processTextForAutoCompletion];
}

- (BOOL)canPressRightButton
{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (text.length > 0 && ![_textInputbar limitExceeded]) {
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
        // Clears the text and the undo manager
        [self.textView slk_clearText:YES];
    }
    
    // Clears cache
    [self clearCachedText];
}

- (void)editText:(NSString *)text
{
    NSAttributedString *attributedText = [self.textView slk_defaultAttributedStringForText:text];
    [self editAttributedText:attributedText];
}

- (void)editAttributedText:(NSAttributedString *)attributedText
{
    if (![_textInputbar canEditText:attributedText.string]) {
        return;
    }
    
    // Caches the current text, in case the user cancels the edition
    [self slk_cacheAttributedTextToDisk:self.textView.attributedText];
    
    [_textInputbar beginTextEditing];
    
    // Setting the text after calling -beginTextEditing is safer
    [self.textView setAttributedText:attributedText];
    
    [self.textView slk_scrollToCaretPositonAnimated:YES];
    
    // Brings up the keyboard if needed
    [self presentKeyboard:YES];
}

- (void)didCommitTextEditing:(id)sender
{
    if (!_textInputbar.isEditing) {
        return;
    }
    
    [_textInputbar endTextEdition];
    
    // Clears the text and but not the undo manager
    [self.textView slk_clearText:NO];
}

- (void)didCancelTextEditing:(id)sender
{
    if (!_textInputbar.isEditing) {
        return;
    }
    
    [_textInputbar endTextEdition];
    
    // Clears the text and but not the undo manager
    [self.textView slk_clearText:NO];
    
    // Restores any previous cached text before entering in editing mode
    [self slk_reloadTextView];
}

- (BOOL)canShowTypingIndicator
{
    // Don't show if the text is being edited or auto-completed.
    if (_textInputbar.isEditing || self.isAutoCompleting) {
        return NO;
    }
    
    return YES;
}

- (CGFloat)heightForAutoCompletionView
{
    return 0.0;
}

- (CGFloat)maximumHeightForAutoCompletionView
{
    CGFloat maxiumumHeight = SLKAutoCompletionViewDefaultHeight;
    
    if (self.isAutoCompleting) {
        CGFloat scrollViewHeight = self.scrollViewHC.constant;
        scrollViewHeight -= [self slk_topBarsHeight];
        
        if (scrollViewHeight < maxiumumHeight) {
            maxiumumHeight = scrollViewHeight;
        }
    }
    
    return maxiumumHeight;
}

- (void)didPasteMediaContent:(NSDictionary *)userInfo
{
    // No implementation here. Meant to be overriden in subclass.
}

- (void)willRequestUndo
{
    NSString *title = NSLocalizedString(@"Undo Typing", nil);
    NSString *acceptTitle = NSLocalizedString(@"Undo", nil);
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    
#ifdef __IPHONE_8_0
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:acceptTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Clears the text but doesn't clear the undo manager
        if (self.shakeToClearEnabled) {
            [self.textView slk_clearText:NO];
        }
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:NULL]];
    
    [self presentViewController:alertController animated:YES completion:nil];
#else
    UIAlertView *alert = [UIAlertView new];
    [alert setTitle:title];
    [alert addButtonWithTitle:acceptTitle];
    [alert addButtonWithTitle:cancelTitle];
    [alert setCancelButtonIndex:1];
    [alert setTag:kSLKAlertViewClearTextTag];
    [alert setDelegate:self];
    [alert show];
#endif
}

- (void)setTextInputbarHidden:(BOOL)hidden
{
    [self setTextInputbarHidden:hidden animated:NO];
}

- (void)setTextInputbarHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (self.isTextInputbarHidden == hidden) {
        return;
    }
    
    _textInputbar.hidden = hidden;
    
    __weak typeof(self) weakSelf = self;
    
    void (^animations)() = ^void(){
        
        weakSelf.textInputbarHC.constant = hidden ? 0 : weakSelf.textInputbar.appropriateHeight;
        
        [weakSelf.view layoutIfNeeded];
    };
    
    void (^completion)(BOOL finished) = ^void(BOOL finished){
        if (hidden) {
            [self dismissKeyboard:YES];
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:animations completion:completion];
    }
    else {
        animations();
        completion(NO);
    }
}


#pragma mark - Private Methods

- (void)slk_didPanTextInputBar:(UIPanGestureRecognizer *)gesture
{
    // Textinput dragging isn't supported when
    if (!self.view.window || !self.keyboardPanningEnabled ||
        [self ignoreTextInputbarAdjustment] || self.isPresentedInPopover) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self slk_handlePanGestureRecognizer:gesture];
    });
}

- (void)slk_handlePanGestureRecognizer:(UIPanGestureRecognizer *)gesture
{
    // Local variables
    static CGPoint startPoint;
    static CGRect originalFrame;
    static BOOL dragging = NO;
    static BOOL presenting = NO;
    
    __block UIView *keyboardView = [_textInputbar.inputAccessoryView keyboardViewProxy];
    
    // When no keyboard view has been detecting, let's skip any handling.
    if (!keyboardView) {
        return;
    }
    
    // Dynamic variables
    CGPoint gestureLocation = [gesture locationInView:self.view];
    CGPoint gestureVelocity = [gesture velocityInView:self.view];
    
    CGFloat keyboardMaxY = CGRectGetHeight(SLKKeyWindowBounds());
    CGFloat keyboardMinY = keyboardMaxY - CGRectGetHeight(keyboardView.frame);
    
    
    // Skips this if it's not the expected textView.
    // Checking the keyboard height constant helps to disable the view constraints update on iPad when the keyboard is undocked.
    // Checking the keyboard status allows to keep the inputAccessoryView valid when still reacing the bottom of the screen.
    CGFloat bottomMargin = [self slk_appropriateBottomMargin];
    if (![self.textView isFirstResponder] || (self.keyboardHC.constant == bottomMargin && self.keyboardStatus == SLKKeyboardStatusDidHide)) {
#if SLKBottomPanningEnabled
        if ([gesture.view isEqual:self.scrollViewProxy]) {
            if (gestureVelocity.y > 0) {
                return;
            }
            else if ((self.isInverted && ![self.scrollViewProxy slk_isAtTop]) || (!self.isInverted && ![self.scrollViewProxy slk_isAtBottom])) {
                return;
            }
        }
        
        presenting = YES;
#else
        if ([gesture.view isEqual:_textInputbar] && gestureVelocity.y < 0) {
            [self presentKeyboard:YES];
        }
        return;
#endif
    }
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            
            startPoint = CGPointZero;
            dragging = NO;
            
            if (presenting) {
                // Let's first present the keyboard without animation
                [self presentKeyboard:NO];
                
                // So we can capture the keyboard's view
                keyboardView = [_textInputbar.inputAccessoryView keyboardViewProxy];
                
                originalFrame = keyboardView.frame;
                originalFrame.origin.y = CGRectGetMaxY(self.view.frame);
                
                // And move the keyboard to the bottom edge
                // TODO: Fix an occasional layout glitch when the keyboard appears for the first time.
                keyboardView.frame = originalFrame;
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged: {
            
            if (CGRectContainsPoint(_textInputbar.frame, gestureLocation) || dragging || presenting){
                
                if (CGPointEqualToPoint(startPoint, CGPointZero)) {
                    startPoint = gestureLocation;
                    dragging = YES;
                    
                    if (!presenting) {
                        originalFrame = keyboardView.frame;
                    }
                }
                
                self.movingKeyboard = YES;
                
                CGPoint transition = CGPointMake(gestureLocation.x - startPoint.x, gestureLocation.y - startPoint.y);
                
                CGRect keyboardFrame = originalFrame;
                
                if (presenting) {
                    keyboardFrame.origin.y += transition.y;
                }
                else {
                    keyboardFrame.origin.y += MAX(transition.y, 0.0);
                }
                
                // Makes sure they keyboard is always anchored to the bottom
                if (CGRectGetMinY(keyboardFrame) < keyboardMinY) {
                    keyboardFrame.origin.y = keyboardMinY;
                }
                
                keyboardView.frame = keyboardFrame;
                
                
                self.keyboardHC.constant = [self slk_appropriateKeyboardHeightFromRect:keyboardFrame];
                self.scrollViewHC.constant = [self slk_appropriateScrollViewHeight];
                
                // layoutIfNeeded must be called before any further scrollView internal adjustments (content offset and size)
                [self.view layoutIfNeeded];
                
                // Overrides the scrollView's contentOffset to allow following the same position when dragging the keyboard
                CGPoint offset = _scrollViewOffsetBeforeDragging;
                
                if (self.isInverted) {
                    if (!self.scrollViewProxy.isDecelerating && self.scrollViewProxy.isTracking) {
                        self.scrollViewProxy.contentOffset = _scrollViewOffsetBeforeDragging;
                    }
                }
                else {
                    CGFloat keyboardHeightDelta = _keyboardHeightBeforeDragging-self.keyboardHC.constant;
                    offset.y -= keyboardHeightDelta;
                    
                    self.scrollViewProxy.contentOffset = offset;
                }
            }
            
            break;
        }
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed: {
            
            if (!dragging) {
                break;
            }
            
            CGPoint transition = CGPointMake(0.0, fabs(gestureLocation.y - startPoint.y));
            
            CGRect keyboardFrame = originalFrame;
            
            if (presenting) {
                keyboardFrame.origin.y = keyboardMinY;
            }
            
            // The velocity can be changed to hide or show the keyboard based on the gesture
            CGFloat minVelocity = 20.0;
            CGFloat minDistance = CGRectGetHeight(keyboardFrame)/2.0;
            
            BOOL hide = (gestureVelocity.y > minVelocity) || (presenting && transition.y < minDistance) || (!presenting && transition.y > minDistance);
            
            if (hide) keyboardFrame.origin.y = keyboardMaxY;
            
            self.keyboardHC.constant = [self slk_appropriateKeyboardHeightFromRect:keyboardFrame];
            self.scrollViewHC.constant = [self slk_appropriateScrollViewHeight];
            
            [UIView animateWithDuration:0.25
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 [self.view layoutIfNeeded];
                                 keyboardView.frame = keyboardFrame;
                             }
                             completion:^(BOOL finished) {
                                 if (hide) {
                                     [self dismissKeyboard:NO];
                                 }
                                 
                                 // Tear down
                                 startPoint = CGPointZero;
                                 originalFrame = CGRectZero;
                                 dragging = NO;
                                 presenting = NO;
                                 
                                 self.movingKeyboard = NO;
                             }];
            
            break;
        }
            
        default:
            break;
    }
}

- (void)slk_didTapScrollView:(UIGestureRecognizer *)gesture
{
    if (!self.isPresentedInPopover && ![self ignoreTextInputbarAdjustment]) {
        [self dismissKeyboard:YES];
    }
}

- (void)slk_didPanTextView:(UIGestureRecognizer *)gesture
{
    [self presentKeyboard:YES];
}

- (void)slk_performRightAction
{
    NSArray *actions = [self.rightButton actionsForTarget:self forControlEvent:UIControlEventTouchUpInside];
    
    if (actions.count > 0 && [self canPressRightButton]) {
        [self.rightButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)slk_postKeyboarStatusNotification:(NSNotification *)notification
{
    if ([self ignoreTextInputbarAdjustment] || self.isTransitioning) {
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
    
    CGFloat keyboardHeight = CGRectGetHeight(endFrame);
    
    beginFrame.size.height = keyboardHeight;
    endFrame.size.height = keyboardHeight;
    
    [userInfo setObject:[NSValue valueWithCGRect:beginFrame] forKey:UIKeyboardFrameBeginUserInfoKey];
    [userInfo setObject:[NSValue valueWithCGRect:endFrame] forKey:UIKeyboardFrameEndUserInfoKey];
    
    NSString *name = [self slk_appropriateKeyboardNotificationName:notification];
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self.textView userInfo:userInfo];
}

- (void)slk_enableTypingSuggestionIfNeeded
{
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    BOOL enable = !self.isAutoCompleting;
    
    NSString *inputPrimaryLanguage = self.textView.textInputMode.primaryLanguage;

    // Toggling autocorrect on Japanese keyboards breaks autocompletion by replacing the autocompletion prefix by an empty string.
    // So for now, let's not disable autocorrection for Japanese.
    if ([inputPrimaryLanguage isEqualToString:@"ja-JP"]) {
        return;
    }
    
    // Let's avoid refreshing the text view while dictation mode is enabled.
    // This solves a crash some users were experiencing when auto-completing with the dictation input mode.
    if ([inputPrimaryLanguage isEqualToString:@"dictation"]) {
        return;
    }
    
    // During text autocompletion, the iOS 8 QuickType bar is hidden and auto-correction and spell checking are disabled.
    [self.textView setTypingSuggestionEnabled:enable];
}

- (void)slk_dismissTextInputbarIfNeeded
{
    CGFloat bottomMargin = [self slk_appropriateBottomMargin];
    if (self.keyboardHC.constant == bottomMargin) {
        return;
    }
    
    self.keyboardHC.constant = bottomMargin;
    self.scrollViewHC.constant = [self slk_appropriateScrollViewHeight];
    
    [self slk_hideAutoCompletionViewIfNeeded];
    
    [self.view layoutIfNeeded];
}

- (void)slk_detectKeyboardStatesInNotification:(NSNotification *)notification
{
    // Tear down
    _externalKeyboardDetected = NO;
    _keyboardUndocked = NO;
    
    if (self.isMovingKeyboard) {
        return;
    }
    
    // Based on http://stackoverflow.com/a/5760910/287403
    // We can determine if the external keyboard is showing by adding the origin.y of the target finish rect (end when showing, begin when hiding) to the inputAccessoryHeight.
    // If it's greater(or equal) the window height, it's an external keyboard.
    CGRect beginRect = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Grab the base view for conversions as we don't want window coordinates in < iOS 8
    // iOS 8 fixes the whole coordinate system issue for us, but iOS 7 doesn't rotate the app window coordinate space.
    UIView *baseView = self.view.window.rootViewController.view;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    // Convert the main screen bounds into the correct coordinate space but ignore the origin.
    CGRect viewBounds = [self.view convertRect:SLKKeyWindowBounds() fromView:nil];
    viewBounds = CGRectMake(0, 0, viewBounds.size.width, viewBounds.size.height);
    
    // We want these rects in the correct coordinate space as well.
    CGRect convertBegin = [baseView convertRect:beginRect fromView:nil];
    CGRect convertEnd = [baseView convertRect:endRect fromView:nil];
    
    if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        if (convertEnd.origin.y >= viewBounds.size.height) {
            _externalKeyboardDetected = YES;
        }
    }
    else if ([notification.name isEqualToString:UIKeyboardWillHideNotification]) {
        // The additional logic check here (== to width) accounts for a glitch (iOS 8 only?) where the window has rotated it's coordinates
        // but the beginRect doesn't yet reflect that. It should never cause a false positive.
        if (convertBegin.origin.y >= viewBounds.size.height ||
            convertBegin.origin.y == viewBounds.size.width) {
            _externalKeyboardDetected = YES;
        }
    }
    
    if (SLK_IS_IPAD && CGRectGetMaxY(convertEnd) < CGRectGetMaxY(screenBounds)) {
        
        // The keyboard is undocked or split (iPad Only)
        _keyboardUndocked = YES;
        
        // An external keyboard cannot be detected anymore
        _externalKeyboardDetected = NO;
    }
}

- (void)slk_adjustContentConfigurationIfNeeded
{
    UIEdgeInsets contentInset = self.scrollViewProxy.contentInset;
    
    // When inverted, we need to substract the top bars height (generally status bar + navigation bar's) to align the top of the
    // scrollView correctly to its top edge.
    if (self.inverted) {
        contentInset.bottom = [self slk_topBarsHeight];
        contentInset.top = contentInset.bottom > 0.0 ? 0.0 : contentInset.top;
    }
    else {
        contentInset.bottom = 0.0;
    }
    
    self.scrollViewProxy.contentInset = contentInset;
    self.scrollViewProxy.scrollIndicatorInsets = contentInset;
}

- (void)slk_prepareForInterfaceTransitionWithDuration:(NSTimeInterval)duration
{
    self.transitioning = YES;
    
    [self.view layoutIfNeeded];
    
    if ([self.textView isFirstResponder]) {
        [self.textView slk_scrollToCaretPositonAnimated:NO];
    }
    else {
        [self.textView slk_scrollToBottomAnimated:NO];
    }
    
    // Disables the flag after the rotation animation is finished
    // Hacky but works.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.transitioning = NO;
    });
}


#pragma mark - Keyboard Events

- (void)didPressReturnKey:(UIKeyCommand *)keyCommand
{
    if (_textInputbar.isEditing) {
        [self didCommitTextEditing:keyCommand];
    }
    else {
        [self slk_performRightAction];
    }
}

- (void)didPressEscapeKey:(UIKeyCommand *)keyCommand
{
    if (self.isAutoCompleting) {
        [self cancelAutoCompletion];
    }
    else if (_textInputbar.isEditing) {
        [self didCancelTextEditing:keyCommand];
    }
   
    CGFloat bottomMargin = [self slk_appropriateBottomMargin];
    if ([self ignoreTextInputbarAdjustment] || ([self.textView isFirstResponder] && self.keyboardHC.constant == bottomMargin)) {
        return;
    }
    
    [self dismissKeyboard:YES];
}

- (void)didPressArrowKey:(UIKeyCommand *)keyCommand
{
    [self.textView didPressArrowKey:keyCommand];
}


#pragma mark - Notification Events

- (void)slk_willShowOrHideKeyboard:(NSNotification *)notification
{
    SLKKeyboardStatus status = [self slk_keyboardStatusForNotification:notification];
    
    // Skips if the view isn't visible.
    if (!self.isViewVisible) {
        return;
    }
    
    // Skips if it is presented inside of a popover.
    if (self.isPresentedInPopover) {
        return;
    }
    
    // Skips if textview did refresh only.
    if (self.textView.didNotResignFirstResponder) {
        return;
    }
    
    UIResponder *currentResponder = [UIResponder slk_currentFirstResponder];
    
    // Skips if it's not the expected textView and shouldn't force adjustment of the text input bar.
    // This will also dismiss the text input bar if it's visible, and exit auto-completion mode if enabled.
    if (![currentResponder isEqual:self.textView] && ![self forceTextInputbarAdjustmentForResponder:currentResponder]) {
        [self slk_dismissTextInputbarIfNeeded];
        return;
    }
    
    // Skips if it's the current status
    if (self.keyboardStatus == status) {
        return;
    }
    
    // Programatically stops scrolling before updating the view constraints (to avoid scrolling glitch).
    if (status == SLKKeyboardStatusWillShow) {
        [self.scrollViewProxy slk_stopScrolling];
    }
    
    // Stores the previous keyboard height
    CGFloat previousKeyboardHeight = self.keyboardHC.constant;
    
    // Updates the height constraints' constants
    self.keyboardHC.constant = [self slk_appropriateKeyboardHeightFromNotification:notification];
    self.scrollViewHC.constant = [self slk_appropriateScrollViewHeight];
    
    // Updates and notifies about the keyboard status update
    if ([self slk_updateKeyboardStatus:status]) {
        // Posts custom keyboard notification, if logical conditions apply
        [self slk_postKeyboarStatusNotification:notification];
    }
    
    // Hides the auto-completion view if the keyboard is being dismissed.
    if (![self.textView isFirstResponder] || status == SLKKeyboardStatusWillHide) {
        [self slk_hideAutoCompletionViewIfNeeded];
    }
    
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect beginFrame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    void (^animations)() = ^void() {
        // Scrolls to bottom only if the keyboard is about to show.
        if (self.shouldScrollToBottomAfterKeyboardShows && self.keyboardStatus == SLKKeyboardStatusWillShow) {
            if (self.isInverted) {
                [self.scrollViewProxy slk_scrollToTopAnimated:YES];
            }
            else {
                [self.scrollViewProxy slk_scrollToBottomAnimated:YES];
            }
        }
    };
    
    // Begin and end frames are the same when the keyboard is shown during navigation controller's push animation.
    // The animation happens in window coordinates (slides from right to left) but doesn't in the view controller's view coordinates.
    // Second condition: check if the height of the keyboard changed.
    if (!CGRectEqualToRect(beginFrame, endFrame) || fabs(previousKeyboardHeight - self.keyboardHC.constant) > 0.0)
    {
        // Only for this animation, we set bo to bounce since we want to give the impression that the text input is glued to the keyboard.
        [self.view slk_animateLayoutIfNeededWithDuration:duration
                                                  bounce:NO
                                                 options:(curve<<16)|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState
                                              animations:animations
                                              completion:NULL];
    }
    else {
        animations();
    }
}

- (void)slk_didShowOrHideKeyboard:(NSNotification *)notification
{
    SLKKeyboardStatus status = [self slk_keyboardStatusForNotification:notification];
    
    // Skips if the view isn't visible
    if (!self.isViewVisible) {
        if (status == SLKKeyboardStatusDidHide && self.keyboardStatus == SLKKeyboardStatusWillHide) {
            // Even if the view isn't visible anymore, let's still continue to update all states.
        }
        else {
            return;
        }
    }
    
    // Skips if it is presented inside of a popover
    if (self.isPresentedInPopover) {
        return;
    }
    
    // Skips if textview did refresh only
    if (self.textView.didNotResignFirstResponder) {
        return;
    }
    
    // Skips if it's the current status
    if (self.keyboardStatus == status) {
        return;
    }
    
    // Updates and notifies about the keyboard status update
    if ([self slk_updateKeyboardStatus:status]) {
        // Posts custom keyboard notification, if logical conditions apply
        [self slk_postKeyboarStatusNotification:notification];
    }
    
    // After showing keyboard, check if the current cursor position could diplay autocompletion
    if ([self.textView isFirstResponder] && status == SLKKeyboardStatusDidShow && !self.isAutoCompleting) {
        
        // Wait till the end of the current run loop
        dispatch_async(dispatch_get_main_queue(), ^{
            [self slk_processTextForAutoCompletion];
        });
    }
    
    // Very important to invalidate this flag after the keyboard is dismissed or presented, to start with a clean state next time.
    self.movingKeyboard = NO;
}

- (void)slk_didPostSLKKeyboardNotification:(NSNotification *)notification
{
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    // Used for debug only
    NSLog(@"%@ %s: %@", NSStringFromClass([self class]), __FUNCTION__, notification);
}

- (void)slk_willChangeTextViewText:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    [self textWillUpdate];
}

- (void)slk_didChangeTextViewText:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    // Animated only if the view already appeared.
    [self textDidUpdate:self.isViewVisible];
    
    // Process the text at every change, when the view is visible
    if (self.isViewVisible) {
        [self slk_processTextForAutoCompletion];
    }
}

- (void)slk_didChangeTextViewContentSize:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    // Animated only if the view already appeared.
    [self textDidUpdate:self.isViewVisible];
}

- (void)slk_didChangeTextViewSelectedRange:(NSNotification *)notification
{
    // Skips this it's not the expected textView.
    if (![notification.object isEqual:self.textView]) {
        return;
    }
    
    [self textSelectionDidChange];
}

- (void)slk_didChangeTextViewPasteboard:(NSNotification *)notification
{
    // Skips this if it's not the expected textView.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    // Notifies only if the pasted item is nested in a dictionary.
    if (notification.userInfo) {
        [self didPasteMediaContent:notification.userInfo];
    }
}

- (void)slk_didShakeTextView:(NSNotification *)notification
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

- (void)slk_willShowOrHideTypeIndicatorView:(UIView <SLKTypingIndicatorProtocol> *)view
{
    // Skips if the typing indicator should not show. Ignores the checking if it's trying to hide.
    if (![self canShowTypingIndicator] && view.isVisible) {
        return;
    }
    
    CGFloat systemLayoutSizeHeight = [view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    CGFloat height = view.isVisible ? systemLayoutSizeHeight : 0.0;
    
    self.typingIndicatorViewHC.constant = height;
    self.scrollViewHC.constant -= height;
    
    if (view.isVisible) {
        view.hidden = NO;
    }
    
    [self.view slk_animateLayoutIfNeededWithBounce:self.bounces
                                           options:UIViewAnimationOptionCurveEaseInOut
                                        animations:NULL
                                        completion:^(BOOL finished) {
                                            if (!view.isVisible) {
                                                view.hidden = YES;
                                            }
                                        }];
}


#pragma mark - KVO Events

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object conformsToProtocol:@protocol(SLKTypingIndicatorProtocol)] && [keyPath isEqualToString:@"visible"]) {
        [self slk_willShowOrHideTypeIndicatorView:object];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Auto-Completion Text Processing

- (void)registerPrefixesForAutoCompletion:(NSArray <NSString *> *)prefixes
{
    if (prefixes.count == 0) {
        return;
    }
    
    NSMutableSet *set = [NSMutableSet setWithSet:self.registeredPrefixes];
    [set addObjectsFromArray:[prefixes copy]];
    
    _registeredPrefixes = [NSSet setWithSet:set];
}

- (BOOL)shouldProcessTextForAutoCompletion:(NSString *)text
{
    if (!_registeredPrefixes || _registeredPrefixes.count == 0) {
        return NO;
    }
    
    return YES;
}

- (void)didChangeAutoCompletionPrefix:(NSString *)prefix andWord:(NSString *)word
{
    // No implementation here. Meant to be overriden in subclass.
}

- (void)showAutoCompletionView:(BOOL)show
{
    // Reloads the tableview before showing/hiding
    [_autoCompletionView reloadData];
    
    self.autoCompleting = show;
    
    // Toggles auto-correction if requiered
    [self slk_enableTypingSuggestionIfNeeded];
    
    CGFloat viewHeight = show ? [self heightForAutoCompletionView] : 0.0;
    
    if (self.autoCompletionViewHC.constant == viewHeight) {
        return;
    }
    
    // If the auto-completion view height is bigger than the maximum height allows, it is reduce to that size. Default 140 pts.
    CGFloat maximumHeight = [self maximumHeightForAutoCompletionView];
    
    if (viewHeight > maximumHeight) {
        viewHeight = maximumHeight;
    }
    
    CGFloat contentViewHeight = self.scrollViewHC.constant + self.autoCompletionViewHC.constant;
    
    // On iPhone, the auto-completion view can't extend beyond the content view height
    if (SLK_IS_IPHONE && viewHeight > contentViewHeight) {
        viewHeight = contentViewHeight;
    }
    
    self.autoCompletionViewHC.constant = viewHeight;
    
    [self.view slk_animateLayoutIfNeededWithBounce:self.bounces
                                           options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction
                                        animations:NULL];
}

- (void)showAutoCompletionViewWithPrefix:(NSString *)prefix andWord:(NSString *)word prefixRange:(NSRange)prefixRange
{
    if ([self.registeredPrefixes containsObject:prefix]) {
        _foundPrefix = prefix;
        _foundWord = word;
        _foundPrefixRange = prefixRange;
        [self didChangeAutoCompletionPrefix:self.foundPrefix andWord:self.foundWord];
        [self showAutoCompletionView:YES];
    }
}

- (void)acceptAutoCompletionWithString:(NSString *)string
{
    [self acceptAutoCompletionWithString:string keepPrefix:YES];
}

- (void)acceptAutoCompletionWithString:(NSString *)string keepPrefix:(BOOL)keepPrefix
{
    if (string.length == 0) {
        return;
    }
    
    NSUInteger location = self.foundPrefixRange.location;
    if (keepPrefix) {
        location += self.foundPrefixRange.length;
    }
    
    NSUInteger length = self.foundWord.length;
    if (!keepPrefix) {
        length += self.foundPrefixRange.length;
    }
    
    NSRange range = NSMakeRange(location, length);
    NSRange insertionRange = [self.textView slk_insertText:string inRange:range];
    
    self.textView.selectedRange = NSMakeRange(insertionRange.location, 0);
    
    [self.textView slk_scrollToCaretPositonAnimated:NO];
    
    [self cancelAutoCompletion];
}

- (void)cancelAutoCompletion
{
    [self slk_invalidateAutoCompletion];
    [self slk_hideAutoCompletionViewIfNeeded];
}

- (void)slk_processTextForAutoCompletion
{
    NSString *text = self.textView.text;
    
    if ((!self.isAutoCompleting && text.length == 0) || self.isTransitioning || ![self shouldProcessTextForAutoCompletion:text]) {
        return;
    }
    
    [self.textView lookForPrefixes:self.registeredPrefixes
                        completion:^(NSString *prefix, NSString *word, NSRange wordRange) {
                            
                            if (prefix.length > 0 && word.length > 0) {
                                
                                // Captures the detected symbol prefix
                                _foundPrefix = prefix;
                                
                                // Removes the found prefix, or not.
                                _foundWord = [word substringFromIndex:prefix.length];
                                
                                // Used later for replacing the detected range with a new string alias returned in -acceptAutoCompletionWithString:
                                _foundPrefixRange = NSMakeRange(wordRange.location, prefix.length);
                                
                                [self slk_handleProcessedWord:word wordRange:wordRange];
                            }
                            else {
                                [self cancelAutoCompletion];
                            }
                        }];
}

- (void)slk_handleProcessedWord:(NSString *)word wordRange:(NSRange)wordRange
{
    // Cancel auto-completion if the cursor is placed before the prefix
    if (self.textView.selectedRange.location <= self.foundPrefixRange.location) {
        return [self cancelAutoCompletion];
    }
    
    if (self.foundPrefix.length > 0) {
        if (wordRange.length == 0 || wordRange.length != word.length) {
            return [self cancelAutoCompletion];
        }
        
        if (word.length > 0) {
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
    
    [self didChangeAutoCompletionPrefix:self.foundPrefix andWord:self.foundWord];
}

- (void)slk_invalidateAutoCompletion
{
    _foundPrefix = nil;
    _foundWord = nil;
    _foundPrefixRange = NSMakeRange(0,0);
    
    [_autoCompletionView setContentOffset:CGPointZero];
}

- (void)slk_hideAutoCompletionViewIfNeeded
{
    if (self.isAutoCompleting) {
        [self showAutoCompletionView:NO];
    }
}


#pragma mark - Text Caching

- (NSString *)keyForTextCaching
{
    // No implementation here. Meant to be overriden in subclass.
    return nil;
}

- (NSString *)slk_keyForPersistency
{
    NSString *key = [self keyForTextCaching];
    if (key == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@.%@", SLKTextViewControllerDomain, key];
}

- (void)slk_reloadTextView
{
    NSString *key = [self slk_keyForPersistency];
    if (key == nil) {
        return;
    }
    NSAttributedString *cachedAttributedText = [[NSAttributedString alloc] initWithString:@""];
    
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (obj) {
        if ([obj isKindOfClass:[NSString class]]) {
            cachedAttributedText = [[NSAttributedString alloc] initWithString:obj];
        }
        else if ([obj isKindOfClass:[NSData class]]) {
            cachedAttributedText = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
        }
    }
    
    if (self.textView.attributedText.length == 0 || cachedAttributedText.length > 0) {
        self.textView.attributedText = cachedAttributedText;
    }
}

- (void)cacheTextView
{
    [self slk_cacheAttributedTextToDisk:self.textView.attributedText];
}

- (void)clearCachedText
{
    [self slk_cacheAttributedTextToDisk:nil];
}

- (void)slk_cacheAttributedTextToDisk:(NSAttributedString *)attributedText
{
    NSString *key = [self slk_keyForPersistency];
    
    if (!key || key.length == 0) {
        return;
    }
    
    NSAttributedString *cachedAttributedText = [[NSAttributedString alloc] initWithString:@""];
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (obj) {
        if ([obj isKindOfClass:[NSString class]]) {
            cachedAttributedText = [[NSAttributedString alloc] initWithString:obj];
        }
        else if ([obj isKindOfClass:[NSData class]]) {
            cachedAttributedText = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
        }
    }
    
    // Caches text only if its a valid string and not already cached
    if (attributedText.length > 0 && ![attributedText isEqualToAttributedString:cachedAttributedText]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:attributedText];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
    }
    // Clears cache only if it exists
    else if (attributedText.length == 0 && cachedAttributedText.length > 0) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    else {
        // Skips so it doesn't hit 'synchronize' unnecessarily
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)slk_cacheTextToDisk:(NSString *)text
{
    NSString *key = [self slk_keyForPersistency];
    
    if (!key || key.length == 0) {
        return;
    }
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text];
    [self slk_cacheAttributedTextToDisk:attributedText];
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


#pragma mark - Customization

- (void)registerClassForTextView:(Class)aClass
{
    if (aClass == nil) {
        return;
    }
    
    NSAssert([aClass isSubclassOfClass:[SLKTextView class]], @"The registered class is invalid, it must be a subclass of SLKTextView.");
    self.textViewClass = aClass;
}

- (void)registerClassForTypingIndicatorView:(Class)aClass
{
    if (aClass == nil) {
        return;
    }
    
    NSAssert([aClass isSubclassOfClass:[UIView class]], @"The registered class is invalid, it must be a subclass of UIView.");
    self.typingIndicatorViewClass = aClass;
}


#pragma mark - UITextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (![textView isKindOfClass:[SLKTextView class]]) {
        return YES;
    }
    
    BOOL newWordInserted = ([text rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound);
    
    // Records text for undo for every new word
    if (newWordInserted) {
        [textView slk_prepareForUndo:@"Word Change"];
    }
    
    // Detects double spacebar tapping, to replace the default "." insert with a formatting symbol, if needed.
    if (textView.isFormattingEnabled && range.location > 0 && text.length > 0 &&
        [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[text characterAtIndex:0]] &&
        [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[textView.text characterAtIndex:range.location - 1]]) {
        
        BOOL shouldChange = YES;
        
        // Since we are moving 2 characters to the left, we need for to make sure that the string's lenght,
        // before the caret position, is higher than 2.
        if ([textView.text substringToIndex:textView.selectedRange.location].length < 2) {
            return YES;
        }
        
        NSRange wordRange = range;
        wordRange.location -= 2; // minus the white space added with the double space bar tapping
        
        if (wordRange.location == NSNotFound) {
            return YES;
        }
        
        NSArray *symbols = textView.registeredSymbols;
        
        NSMutableCharacterSet *invalidCharacters = [NSMutableCharacterSet new];
        [invalidCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [invalidCharacters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        [invalidCharacters removeCharactersInString:[symbols componentsJoinedByString:@""]];
        
        for (NSString *symbol in symbols) {
            
            // Detects the closest registered symbol to the caret, from right to left
            NSRange searchRange = NSMakeRange(0, wordRange.location);
            NSRange prefixRange = [textView.text rangeOfString:symbol options:NSBackwardsSearch range:searchRange];
            
            if (prefixRange.location == NSNotFound) {
                continue;
            }
            
            NSRange nextCharRange = NSMakeRange(prefixRange.location+1, 1);
            NSString *charAfterSymbol = [textView.text substringWithRange:nextCharRange];
            
            if (prefixRange.location != NSNotFound && ![invalidCharacters characterIsMember:[charAfterSymbol characterAtIndex:0]]) {
                
                if ([self textView:textView shouldInsertSuffixForFormattingWithSymbol:symbol prefixRange:prefixRange]) {
                    
                    NSRange suffixRange;
                    [textView wordAtRange:wordRange rangeInText:&suffixRange];
                    
                    // Skip if the detected word already has a suffix
                    if ([[textView.text substringWithRange:suffixRange] hasSuffix:symbol]) {
                        continue;
                    }
                    
                    suffixRange.location += suffixRange.length;
                    suffixRange.length = 0;
                    
                    NSString *lastCharacter = [textView.text substringWithRange:NSMakeRange(suffixRange.location, 1)];
                    
                    // Checks if the last character was a line break, so we append the symbol in the next line too
                    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[lastCharacter characterAtIndex:0]]) {
                        suffixRange.location += 1;
                    }
                    
                    [textView slk_insertText:symbol inRange:suffixRange];
                    shouldChange = NO;
                    
                    // Reset the original cursor location +1 for the new character
                    NSRange adjustedCursorPosition = NSMakeRange(range.location + 1, 0);
                    textView.selectedRange = adjustedCursorPosition;
                    
                    break; // exit
                }
            }
        }
        
        return shouldChange;
    }
    else if ([text isEqualToString:@"\n"]) {
        //Detected break. Should insert new line break programatically instead.
        [textView slk_insertNewLineBreak];
        
        return NO;
    }
    else {
        NSDictionary *userInfo = @{@"text": text, @"range": [NSValue valueWithRange:range]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewTextWillChangeNotification object:self.textView userInfo:userInfo];
        
        return YES;
    }
}

- (void)textViewDidChange:(SLKTextView *)textView
{
    // Keep to avoid unnecessary crashes. Was meant to be overriden in subclass while calling super.
}

- (void)textViewDidChangeSelection:(SLKTextView *)textView
{
    // Keep to avoid unnecessary crashes. Was meant to be overriden in subclass while calling super.
}

- (BOOL)textViewShouldBeginEditing:(SLKTextView *)textView
{
    return YES;
}

- (BOOL)textViewShouldEndEditing:(SLKTextView *)textView
{
    return YES;
}

- (void)textViewDidBeginEditing:(SLKTextView *)textView
{
    // No implementation here. Meant to be overriden in subclass.
}

- (void)textViewDidEndEditing:(SLKTextView *)textView
{
    // No implementation here. Meant to be overriden in subclass.
}


#pragma mark - SLKTextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldOfferFormattingForSymbol:(NSString *)symbol
{
    return YES;
}

- (BOOL)textView:(SLKTextView *)textView shouldInsertSuffixForFormattingWithSymbol:(NSString *)symbol prefixRange:(NSRange)prefixRange
{
    if (prefixRange.location > 0) {
        NSRange previousCharRange = NSMakeRange(prefixRange.location-1, 1);
        NSString *previousCharacter = [self.textView.text substringWithRange:previousCharRange];
        
        // Only insert a suffix if the character before the prefix was a whitespace or a line break
        if ([previousCharacter rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
            return YES;
        }
        else {
            return NO;
        }
    }
    
    return YES;
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
    if (!self.scrollViewProxy.scrollsToTop || self.keyboardStatus == SLKKeyboardStatusWillShow) {
        return NO;
    }
    
    if (self.isInverted) {
        [self.scrollViewProxy slk_scrollToBottomAnimated:YES];
        return NO;
    }
    else {
        return YES;
    }
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
    if ([scrollView isEqual:_autoCompletionView]) {
        CGRect frame = self.autoCompletionHairline.frame;
        frame.origin.y = scrollView.contentOffset.y;
        self.autoCompletionHairline.frame = frame;
    }
    else {
        if (!self.isMovingKeyboard) {
            _scrollViewOffsetBeforeDragging = scrollView.contentOffset;
            _keyboardHeightBeforeDragging = self.keyboardHC.constant;
        }
    }
}


#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture
{
    if ([gesture isEqual:self.singleTapGesture]) {
        return [self.textView isFirstResponder] && ![self ignoreTextInputbarAdjustment];
    }
    else if ([gesture isEqual:self.verticalPanGesture]) {
        return self.keyboardPanningEnabled && ![self ignoreTextInputbarAdjustment];
    }
    
    return NO;
}


#pragma mark - UIAlertViewDelegate Methods

#ifndef __IPHONE_8_0
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag != kSLKAlertViewClearTextTag || buttonIndex == [alertView cancelButtonIndex] ) {
        return;
    }
    
    // Clears the text but doesn't clear the undo manager
    if (self.shakeToClearEnabled) {
        [self.textView slk_clearText:NO];
    }
}
#endif


#pragma mark - View Auto-Layout

- (void)slk_setupViewConstraints
{
    NSDictionary *views = @{@"scrollView": self.scrollViewProxy,
                            @"autoCompletionView": self.autoCompletionView,
                            @"typingIndicatorView": self.typingIndicatorProxyView,
                            @"textInputbar": self.textInputbar,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView(0@750)][typingIndicatorView(0)]-0@999-[textInputbar(0)]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[autoCompletionView(0@750)][typingIndicatorView]" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[autoCompletionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[typingIndicatorView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textInputbar]|" options:0 metrics:nil views:views]];
    
    self.scrollViewHC = [self.view slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.scrollViewProxy secondItem:nil];
    self.autoCompletionViewHC = [self.view slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.autoCompletionView secondItem:nil];
    self.typingIndicatorViewHC = [self.view slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.typingIndicatorProxyView secondItem:nil];
    self.textInputbarHC = [self.view slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.textInputbar secondItem:nil];
    self.keyboardHC = [self.view slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self.view secondItem:self.textInputbar];
    
    [self slk_updateViewConstraints];
}

- (void)slk_updateViewConstraints
{
    self.textInputbarHC.constant = self.textInputbar.minimumInputbarHeight;
    self.scrollViewHC.constant = [self slk_appropriateScrollViewHeight];
    self.keyboardHC.constant = [self slk_appropriateKeyboardHeightFromRect:CGRectNull];
    
    if (_textInputbar.isEditing) {
        self.textInputbarHC.constant += self.textInputbar.editorContentViewHeight;
    }
    
    [super updateViewConstraints];
}


#pragma mark - Keyboard Command registration

- (void)slk_registerKeyCommands
{
    __weak typeof(self) weakSelf = self;

    // Enter Key
    [self.textView observeKeyInput:@"\r" modifiers:0 title:NSLocalizedString(@"Send/Accept", nil) completion:^(UIKeyCommand *keyCommand) {
        [weakSelf didPressReturnKey:keyCommand];
    }];
    
    // Esc Key
    [self.textView observeKeyInput:UIKeyInputEscape modifiers:0 title:NSLocalizedString(@"Dismiss", nil) completion:^(UIKeyCommand *keyCommand) {
        [weakSelf didPressEscapeKey:keyCommand];
    }];
    
    // Up Arrow
    [self.textView observeKeyInput:UIKeyInputUpArrow modifiers:0 title:nil completion:^(UIKeyCommand *keyCommand) {
        [weakSelf didPressArrowKey:keyCommand];
    }];
    
    // Down Arrow
    [self.textView observeKeyInput:UIKeyInputDownArrow modifiers:0 title:nil completion:^(UIKeyCommand *keyCommand) {
        [weakSelf didPressArrowKey:keyCommand];
    }];
}

- (NSArray *)keyCommands
{
    // Important to keep this in, for backwards compatibility.
    return @[];
}


#pragma mark - NSNotificationCenter registration

- (void)slk_registerNotifications
{
    [self slk_unregisterNotifications];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // Keyboard notifications
    [notificationCenter addObserver:self selector:@selector(slk_willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
    
#if SLK_KEYBOARD_NOTIFICATION_DEBUG
    [notificationCenter addObserver:self selector:@selector(slk_didPostSLKKeyboardNotification:) name:SLKKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didPostSLKKeyboardNotification:) name:SLKKeyboardDidShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didPostSLKKeyboardNotification:) name:SLKKeyboardWillHideNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didPostSLKKeyboardNotification:) name:SLKKeyboardDidHideNotification object:nil];
#endif
    
    // TextView notifications
    [notificationCenter addObserver:self selector:@selector(slk_willChangeTextViewText:) name:SLKTextViewTextWillChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didChangeTextViewContentSize:) name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didChangeTextViewSelectedRange:) name:SLKTextViewSelectedRangeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didChangeTextViewPasteboard:) name:SLKTextViewDidPasteItemNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(slk_didShakeTextView:) name:SLKTextViewDidShakeNotification object:nil];
    
    // Application notifications
    [notificationCenter addObserver:self selector:@selector(cacheTextView) name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(cacheTextView) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(cacheTextView) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)slk_unregisterNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    // Keyboard notifications
    [notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [notificationCenter removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [notificationCenter removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
#if SLK_KEYBOARD_NOTIFICATION_DEBUG
    [notificationCenter removeObserver:self name:SLKKeyboardWillShowNotification object:nil];
    [notificationCenter removeObserver:self name:SLKKeyboardDidShowNotification object:nil];
    [notificationCenter removeObserver:self name:SLKKeyboardWillHideNotification object:nil];
    [notificationCenter removeObserver:self name:SLKKeyboardDidHideNotification object:nil];
#endif
    
    // TextView notifications
    [notificationCenter removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [notificationCenter removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
    [notificationCenter removeObserver:self name:SLKTextViewTextWillChangeNotification object:nil];
    [notificationCenter removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [notificationCenter removeObserver:self name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [notificationCenter removeObserver:self name:SLKTextViewSelectedRangeDidChangeNotification object:nil];
    [notificationCenter removeObserver:self name:SLKTextViewDidPasteItemNotification object:nil];
    [notificationCenter removeObserver:self name:SLKTextViewDidShakeNotification object:nil];
    
    // Application notifications
    [notificationCenter removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}


#pragma mark - View Auto-Rotation

#ifdef __IPHONE_8_0
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self slk_prepareForInterfaceTransitionWithDuration:coordinator.transitionDuration];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
#else
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self respondsToSelector:@selector(viewWillTransitionToSize:withTransitionCoordinator:)]) {
        return;
    }
    
    [self slk_prepareForInterfaceTransitionWithDuration:duration];
}
#endif

#ifdef __IPHONE_9_0
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
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
    [self slk_unregisterNotifications];

    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView = nil;
    
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    _collectionView = nil;
    
    _scrollView = nil;
    
    _autoCompletionView.delegate = nil;
    _autoCompletionView.dataSource = nil;
    _autoCompletionView = nil;
    
    _textInputbar = nil;
    _textViewClass = nil;
    
    [_typingIndicatorProxyView removeObserver:self forKeyPath:@"visible"];
    _typingIndicatorProxyView = nil;
    _typingIndicatorViewClass = nil;
    
    _registeredPrefixes = nil;
    _singleTapGesture.delegate = nil;
    _singleTapGesture = nil;
    _verticalPanGesture.delegate = nil;
    _verticalPanGesture = nil;
    _scrollViewHC = nil;
    _textInputbarHC = nil;
    _typingIndicatorViewHC = nil;
    _autoCompletionViewHC = nil;
    _keyboardHC = nil;
}

@end
