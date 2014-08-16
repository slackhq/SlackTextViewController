//
//  SLKChatTableViewController.m
//  SLKChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SLKChatTableViewController.h"

typedef NS_ENUM(NSUInteger, SLKKeyboardStatus) {
    SLKKeyboardStatusDidHide,
    SLKKeyboardStatusWillHide,
    SLKKeyboardStatusDidShow,
    SLKKeyboardStatusWillShow,
    SLKKeyboardStatusDragging,
};

extern NSString * const SLKInputAccessoryViewKeyboardFrameDidChangeNotification;

#define kTextViewVerticalPadding 5
#define kTextViewHorizontalPadding 8

@interface SLKInputAccessoryView : UIView
@end

@interface SLKChatTableViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) UITableViewStyle tableStyle;

@property (nonatomic, strong) UIGestureRecognizer *dismissingGesture;

@property (nonatomic) BOOL wasDragging;
@property (nonatomic) CGFloat minOffset;
@property (nonatomic) CGRect inputViewRect;
@property (nonatomic) SLKKeyboardStatus keyboardStatus;
@end

@implementation SLKChatTableViewController
@synthesize tableView = _tableView;
@synthesize textView = _textView;
@synthesize textContainerView = _textContainerView;

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if (self = [super init]) {
        _tableStyle = style;
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self configure];
    }
    return self;
}

- (void)configure
{
    self.rightButtonTitle = @"Send";
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.textContainerView];
    
    [self registerNotifications];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _minOffset = self.tableView.contentOffset.y;
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


#pragma mark - Getter Methods

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-44.0) style:_tableStyle ? : UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        _tableView.scrollsToTop = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _dismissingGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
        _dismissingGesture.delegate = self;
        [_tableView addGestureRecognizer:self.dismissingGesture];
        
        NSLog(@"self.tableView : %@", self.tableView);
    }
    return _tableView;
}

- (UIView *)textContainerView
{
    if (!_textContainerView)
    {
        _textContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-44.0, self.view.bounds.size.width, 44.0)];
        _textContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _textContainerView.backgroundColor = [UIColor whiteColor];
        
        [_textContainerView addSubview:self.leftButton];
        [_textContainerView addSubview:self.rightButton];
        [_textContainerView addSubview:self.textView];
        
        [self setupViewConstraints];

        _inputViewRect = _textContainerView.frame;
    }
    return _textContainerView;
}

- (SLKTextView *)textView
{
    if (!_textView)
    {
        _textView = [[SLKTextView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:15.0f];
        _textView.textContainer.maximumNumberOfLines = 0;
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.layer.cornerRadius = 5.0f;
        _textView.layer.borderWidth = 1.0f;
        _textView.layer.borderColor =  [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:205.0f/255.0f alpha:1.0f].CGColor;
        _textView.inputAccessoryView = [SLKInputAccessoryView new];
    }
    return _textView;
}

- (UIButton *)leftButton
{
    if (!_leftButton)
    {
        _leftButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _leftButton;
}

- (UIButton *)rightButton
{
    if (!_rightButton)
    {
        _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        
        [self.rightButton setTitle:self.rightButtonTitle forState:UIControlStateNormal];
        [self.rightButton sizeToFit];
        [self.rightButton setTitle:@"" forState:UIControlStateNormal];
    }
    return _rightButton;
}


#pragma mark - Setters



#pragma mark - Actions

- (void)dismissKeyboard:(id)sender
{
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}


#pragma mark - Observers and Selectors

- (void)didChangeTextView:(NSNotification *)notification
{
    NSString *title = (self.textView.text.length > 0) ? self.rightButtonTitle : @"";
    NSString *rightTitle = [self.rightButton titleForState:UIControlStateNormal];

    if (![title isEqualToString:rightTitle]) {
        [_rightButton setTitle:title forState:UIControlStateNormal];
        [self refreshViewConstraints];
    }
}

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect frameEnd = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    if (![self isKeyboardFrameValid:frameEnd]) return;
    
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect inputFrame = self.textContainerView.frame;
    inputFrame.origin.y  = CGRectGetMinY(frameEnd)-CGRectGetHeight(inputFrame);
    
    self.keyboardStatus = show ? SLKKeyboardStatusWillShow : SLKKeyboardStatusWillHide;
    
    CGFloat scrollingGap = CGRectGetHeight(frameEnd);
    CGFloat scrollingOffset = self.tableView.contentOffset.y+(show ? scrollingGap : -scrollingGap);
    
    CGFloat minOffset = self.tableView.contentOffset.y;
    CGFloat maxOffset = self.tableView.contentSize.height-(CGRectGetHeight(self.view.frame)-CGRectGetHeight(inputFrame));
    
    BOOL scroll = (((!show && scrollingOffset != minOffset && scrollingOffset > (_minOffset-scrollingGap) && scrollingOffset < (maxOffset-scrollingGap+_minOffset)) || show) && !self.wasDragging);
    
//    NSLog(@"show ? %@", show ? @"YES" : @"NO");
//    NSLog(@"scrollingOffset(%f) != %f ? %@", scrollingOffset, minOffset, scrollingOffset != minOffset ? @"YES" : @"NO");
//    NSLog(@"scrollingOffset(%f) >= %f ? %@", scrollingOffset, (_minOffset-scrollingGap), scrollingOffset > (_minOffset-scrollingGap) ? @"YES" : @"NO");
//    NSLog(@"scrollingOffset(%f) < %f ? %@", scrollingOffset, (maxOffset-scrollingGap+_minOffset), (scrollingOffset < (maxOffset-scrollingGap+_minOffset)) ? @"YES" : @"NO");
//    NSLog(@"wasDragging : %@", self.wasDragging ? @"YES" : @"NO");
//    NSLog(@"scroll : %@", scroll ? @"YES" : @"NO");
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         self.textContainerView.frame = inputFrame;
                         self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(inputFrame));
                         
                         if (scroll) {
                             self.tableView.contentOffset = CGPointMake(0, scrollingOffset);
                         }
                     }
                     completion:^(BOOL finished) {
                         if (self.wasDragging) {
                             self.wasDragging = NO;
                         }
                     }];
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect frameEnd   = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (![self isKeyboardFrameValid:frameEnd]) return;
    
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect frame = self.textContainerView.frame;
    frame.origin.y  = CGRectGetMinY(frameEnd)-CGRectGetHeight(frame);
    
    self.keyboardStatus = show ? SLKKeyboardStatusDidShow : SLKKeyboardStatusDidHide;

    self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(frame));
}

- (void)didChangeKeywordFrame:(NSNotification *)notification
{
    if (self.keyboardStatus == SLKKeyboardStatusWillShow || self.keyboardStatus == SLKKeyboardStatusWillHide) return;
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect frame = endFrame;
    CGRect inputFrame = self.textContainerView.frame;
    
    if (CGRectEqualToRect(inputFrame, _inputViewRect)) {
        self.keyboardStatus = SLKKeyboardStatusDidHide;
    }
    else {
        self.keyboardStatus = SLKKeyboardStatusDragging;
    }
    
    inputFrame.origin.y = CGRectGetMinY(frame)-CGRectGetHeight(inputFrame);
    
    self.textContainerView.frame = inputFrame;
    self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(inputFrame));
}

- (BOOL)isKeyboardFrameValid:(CGRect)frame
{
    if ((frame.origin.y > CGRectGetHeight([UIScreen mainScreen].bounds)) ||
        (frame.size.height < 1) || (frame.size.width < 1) || (frame.origin.y < 0)) {
        return NO;
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

#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.dismissingGesture isEqual:gestureRecognizer]) {
        return [self.textView isFirstResponder];
    }
    
    return YES;
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (!self.wasDragging) {
        self.wasDragging = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
{
    if (self.wasDragging) {
        self.wasDragging = NO;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.wasDragging) {
        self.wasDragging = NO;
    }
}

#pragma mark - NSNotificationCenter register/unregister

- (void)registerNotifications
{
    // textView notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];

    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeywordFrame:) name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterNotifications
{
    // textView notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];

    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

#pragma mark - View Auto-Layout

- (void)updateViewConstraints
{
    [super updateViewConstraints];
}

- (void)refreshViewConstraints
{
    [self.textContainerView removeConstraints:self.textContainerView.constraints];
    
    [self setupViewConstraints];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
         usingSpringWithDamping:0.65
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [_rightButton sizeToFit];
                         [self.textContainerView layoutIfNeeded];
                     }
                     completion:NULL];
}

- (void)setupViewConstraints
{
    CGFloat height = CGRectGetHeight(self.textContainerView.frame);
    CGFloat leftButtonMargin = roundf((height - self.leftButton.frame.size.height) / 2.0f);
    CGFloat rightButtonMargin = roundf((height - self.rightButton.frame.size.height) / 2.0f);
    
    NSString *rightTitle = [self.rightButton titleForState:UIControlStateNormal];
    CGSize rigthButtonSize = [rightTitle sizeWithAttributes:@{NSFontAttributeName: self.rightButton.titleLabel.font}];
    CGFloat rightButtonWidth = rigthButtonSize.width+kTextViewHorizontalPadding/2.0f;

    NSDictionary *views = @{@"textView": self.textView, @"leftButton": self.leftButton, @"rightButton": self.rightButton};
    NSDictionary *metrics = @{@"hor" : @(kTextViewHorizontalPadding), @"ver" : @(kTextViewVerticalPadding), @"leftButtonMargin" : @(leftButtonMargin), @"rightButtonMargin" : @(rightButtonMargin), @"rightButtonWidth": @(rightButtonWidth)};
    
    [self.textContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[leftButton]-(==hor)-[textView]-(==hor)-[rightButton(rightButtonWidth)]-(==hor)-|" options:0 metrics:metrics views:views]];
    [self.textContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=leftButtonMargin)-[leftButton]-(==leftButtonMargin)-|" options:0 metrics:metrics views:views]];
    [self.textContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=rightButtonMargin)-[rightButton]-(==rightButtonMargin)-|" options:0 metrics:metrics views:views]];
    [self.textContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==ver)-[textView]-(==ver)-|" options:0 metrics:metrics views:views]];
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


@implementation SLKInputAccessoryView

NSString * const SLKInputAccessoryViewKeyboardFrameDidChangeNotification = @"com.slack.chatkit.keyboard.frameDidChange";

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
    }
    
    [newSuperview addObserver:self forKeyPath:NSStringFromSelector(@selector(frame)) options:0 context:NULL];
    
    [super willMoveToSuperview:newSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.superview] && [keyPath isEqualToString:NSStringFromSelector(@selector(frame))])
    {
        NSDictionary *userInfo = @{UIKeyboardFrameEndUserInfoKey:[NSValue valueWithCGRect:[object frame]]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil userInfo:userInfo];
    }
}

@end
