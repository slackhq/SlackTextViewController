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

@interface SLKChatTableViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
{
    UITableViewStyle _tableStyle;
    SLKKeyboardStatus _keyboardStatus;
    
    CGRect _inputViewRect;
    CGFloat _minYOffset;
    
    UIGestureRecognizer *_dismissingGesture;
}

@property (nonatomic) BOOL wasDragging;

@end

@implementation SLKChatTableViewController
@synthesize tableView = _tableView;
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
    
    // We save the minimum offset of the tableView
    _minYOffset = self.tableView.contentOffset.y;
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
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-44.0) style:_tableStyle ? : UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        _tableView.scrollsToTop = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        _dismissingGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
        _dismissingGesture.delegate = self;
        [_tableView addGestureRecognizer:_dismissingGesture];
    }
    return _tableView;
}

- (SLKTextContainerView *)textContainerView
{
    if (!_textContainerView)
    {
        _textContainerView = [[SLKTextContainerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-44.0, self.view.bounds.size.width, 44.0)];
//        _textContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _inputViewRect = _textContainerView.frame;
    }
    return _textContainerView;
}

- (SLKTextView *)textView
{
    return _textContainerView.textView;
}

- (UIButton *)leftButton
{
    return _textContainerView.leftButton;
}

- (UIButton *)rightButton
{
    return _textContainerView.rightButton;
}


#pragma mark - Setters


#pragma mark - Actions

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if ([self.tableView numberOfSections] == 0) {
        return;
    }
    
    NSInteger items = [self.tableView numberOfRowsInSection:0];
    
    if (items > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:items - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:animated];
    }
}

- (void)dismissKeyboard:(id)sender
{
    if ([self.textContainerView.textView isFirstResponder]) {
        [self.textContainerView.textView resignFirstResponder];
    }
}


#pragma mark - Observers

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect frameEnd = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    if (![self isKeyboardFrameValid:frameEnd]) return;
    
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect inputFrame = self.textContainerView.frame;
    inputFrame.origin.y  = CGRectGetMinY(frameEnd)-CGRectGetHeight(inputFrame);
    
    _keyboardStatus = show ? SLKKeyboardStatusWillShow : SLKKeyboardStatusWillHide;
    
    CGFloat scrollingGap = CGRectGetHeight(frameEnd);
    CGFloat targetOffset = self.tableView.contentOffset.y+(show ? scrollingGap : -scrollingGap);
    
    CGFloat currentYOffset = self.tableView.contentOffset.y;
    CGFloat maxYOffset = self.tableView.contentSize.height-(CGRectGetHeight(self.view.frame)-CGRectGetHeight(inputFrame));
    
    BOOL scroll = (((!show && targetOffset != currentYOffset && targetOffset > (_minYOffset-scrollingGap) && targetOffset < (maxYOffset-scrollingGap+_minYOffset)) || show) && !self.wasDragging);
    
//    NSLog(@"show ? %@", show ? @"YES" : @"NO");
//    NSLog(@"scrollingOffset(%f) != %f ? %@", scrollingOffset, minYOffset, scrollingOffset != minYOffset ? @"YES" : @"NO");
//    NSLog(@"scrollingOffset(%f) >= %f ? %@", scrollingOffset, (_minYOffset-scrollingGap), scrollingOffset > (_minYOffset-scrollingGap) ? @"YES" : @"NO");
//    NSLog(@"scrollingOffset(%f) < %f ? %@", scrollingOffset, (maxYOffset-scrollingGap+_minYOffset), (scrollingOffset < (maxYOffset-scrollingGap+_minYOffset)) ? @"YES" : @"NO");
//    NSLog(@"wasDragging : %@", self.wasDragging ? @"YES" : @"NO");
//    NSLog(@"scroll : %@", scroll ? @"YES" : @"NO");
    
    [UIView animateWithDuration:duration*3
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.7
                        options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         self.textContainerView.frame = inputFrame;
                         self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(inputFrame));
                         
                         if (scroll) {
                             self.tableView.contentOffset = CGPointMake(0, targetOffset);
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
    CGRect frameEnd = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (![self isKeyboardFrameValid:frameEnd]) return;
    
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect frame = self.textContainerView.frame;
    frame.origin.y  = CGRectGetMinY(frameEnd)-CGRectGetHeight(frame);
    
    _keyboardStatus = show ? SLKKeyboardStatusDidShow : SLKKeyboardStatusDidHide;

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(frame));
                     }
                     completion:NULL];
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
    if (_keyboardStatus == SLKKeyboardStatusWillShow || _keyboardStatus == SLKKeyboardStatusWillHide) return;
    
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect frame = endFrame;
    CGRect inputFrame = self.textContainerView.frame;
    
    if (CGRectEqualToRect(inputFrame, _inputViewRect)) {
        _keyboardStatus = SLKKeyboardStatusDidHide;
    }
    else {
        _keyboardStatus = SLKKeyboardStatusDragging;
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
    if ([_dismissingGesture isEqual:gestureRecognizer]) {
        return [self.textContainerView.textView isFirstResponder];
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
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeyboardFrame:) name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterNotifications
{
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
