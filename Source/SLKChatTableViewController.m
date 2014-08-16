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

@interface SLKInputAccessoryView : UIView
@end

@interface SLKChatTableViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) UITableViewStyle tableStyle;
@property (nonatomic, strong) UIToolbar *toolBar;

@property (nonatomic, strong) UIGestureRecognizer *dismissingGesture;

@property (nonatomic) BOOL wasDragging;
@property (nonatomic) CGFloat minOffset;
@property (nonatomic) CGRect inputViewRect;
@property (nonatomic, readonly) SLKKeyboardStatus keyboardStatus;
@end

@implementation SLKChatTableViewController

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
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.toolBar];
    
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
    
    _minOffset = _tableView.contentOffset.y;
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
    }
    return _tableView;
}

- (UIToolbar *)toolBar
{
    if (!_toolBar)
    {
        _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-44.0, self.view.bounds.size.width, 44.0)];
        _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _toolBar.items = @[[[UIBarButtonItem alloc] initWithCustomView:self.textView]];
        _toolBar.barTintColor = [UIColor whiteColor];
        _toolBar.translucent = NO;

        _inputViewRect = _toolBar.frame;
    }
    return _toolBar;
}

- (SLKTextView *)textView
{
    if (!_textView)
    {
        _textView = [[SLKTextView alloc] initWithFrame:CGRectMake(0, 0, 290, 30)];
        _textView.placeholder = @"Message";
        _textView.font = [UIFont systemFontOfSize:15.0f];
        _textView.textContainer.maximumNumberOfLines = 0;
        _textView.layer.cornerRadius = 5.0f;
        _textView.layer.borderWidth = 1.0f;
        _textView.layer.borderColor =  [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:205.0f/255.0f alpha:1.0f].CGColor;
        _textView.inputAccessoryView = [SLKInputAccessoryView new];
    }
    return _textView;
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

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect frameBegin = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect frameEnd   = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration   = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve   = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    frameBegin = [_toolBar.superview convertRect:frameBegin fromView:nil];
    frameEnd   = [_toolBar.superview convertRect:frameEnd fromView:nil];
    
    if (![self isKeyboardFrameValid:frameEnd]) return;
    
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect inputFrame = self.toolBar.frame;
    inputFrame.origin.y  = CGRectGetMinY(frameEnd)-CGRectGetHeight(inputFrame);
    
    _keyboardStatus = show ? SLKKeyboardStatusWillShow : SLKKeyboardStatusWillHide;
    
    CGFloat scrollingGap = CGRectGetHeight(frameEnd);
    CGFloat scrollingOffset = self.tableView.contentOffset.y+(show ? scrollingGap : -scrollingGap);
    
    CGFloat minOffset = self.tableView.contentOffset.y;
    CGFloat maxOffset = self.tableView.contentSize.height-(CGRectGetHeight(self.view.frame)-CGRectGetHeight(inputFrame));
    
    BOOL scroll = ((!show && (scrollingOffset > (minOffset-scrollingGap)) && (scrollingOffset < (maxOffset-scrollingGap+_minOffset))) || show);
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         self.toolBar.frame = inputFrame;
                         self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(inputFrame));
                         
                         if (!self.wasDragging && scroll) {
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
    CGRect frameBegin = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect frameEnd   = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    frameBegin = [_toolBar.superview convertRect:frameBegin fromView:nil];
    frameEnd   = [_toolBar.superview convertRect:frameEnd fromView:nil];
    
    if (![self isKeyboardFrameValid:frameEnd]) return;
    
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect frame = self.toolBar.frame;
    frame.origin.y  = CGRectGetMinY(frameEnd)-CGRectGetHeight(frame);
    
    _keyboardStatus = show ? SLKKeyboardStatusDidShow : SLKKeyboardStatusDidHide;

    self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(frame));
}

- (void)didChangeKeywordFrame:(NSNotification *)notification
{
    if (_keyboardStatus == SLKKeyboardStatusWillShow || _keyboardStatus == SLKKeyboardStatusWillHide) return;
    
    CGRect endFrame   = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect frame      = endFrame;
    CGRect inputFrame = _toolBar.frame;
    
    if (CGRectEqualToRect(inputFrame, _inputViewRect)) {
        _keyboardStatus = SLKKeyboardStatusDidHide;
    }
    else {
        _keyboardStatus = SLKKeyboardStatusDragging;
    }
    
    inputFrame.origin.y = CGRectGetMinY(frame)-CGRectGetHeight(inputFrame);
    
    _toolBar.frame = inputFrame;
    
    self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(frame));
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

#pragma mark - NSNotificationCenter register/unregister

- (void)registerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeywordFrame:) name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
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
