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
    SLKKeyboardStatus _keyboardStatus;
    
    CGRect _inputViewRect;
    CGFloat _minYOffset;
    
    UIGestureRecognizer *_dismissingGesture;
    
    CGFloat _tableViewHeight;
    CGFloat _bottomMargin;
}

@property (nonatomic) BOOL wasDragging;

@end

@implementation SLKChatTableViewController
@synthesize tableView = _tableView;
@synthesize textContainerView = _textContainerView;

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
        _tableView = [UITableView new];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        _tableView.scrollsToTop = YES;
        _tableView.dataSource = self;
        _tableView.delegate = self;

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
        _textContainerView = [SLKTextContainerView new];
        _textContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        
//        _inputViewRect = _textContainerView.frame;
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


#pragma mark - Notification Events

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    // Inverts end rect for landscape orientation
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        endFrame = CGRectMake(0.0, endFrame.origin.x, endFrame.size.height, endFrame.size.width);
    }
    
    if (!isKeyboardFrameValid(endFrame)) return;

    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];

    CGRect contentViewFrame = self.textContainerView.frame;
    contentViewFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(contentViewFrame);

    NSLayoutConstraint *tableViewConstaint = self.view.constraints[1];
    tableViewConstaint.constant = show ? CGRectGetMinY(contentViewFrame) : 0.0;
    
    NSLayoutConstraint *contentViewConstaint = self.view.constraints[4];
    contentViewConstaint.constant = show ? endFrame.size.height : 0.0;
    
    CGFloat scrollingGap = CGRectGetHeight(endFrame);
    CGFloat targetOffset = self.tableView.contentOffset.y+(show ? scrollingGap : -scrollingGap);
    
    CGFloat currentYOffset = self.tableView.contentOffset.y;
    CGFloat maxYOffset = self.tableView.contentSize.height-(CGRectGetHeight(self.view.frame)-CGRectGetHeight(contentViewFrame));
    
    BOOL scroll = (((!show && targetOffset != currentYOffset && targetOffset > (_minYOffset-scrollingGap) && targetOffset < (maxYOffset-scrollingGap+_minYOffset)) || show) && !self.wasDragging);

    [UIView animateWithDuration:animationDuration*3
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.7
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.view layoutIfNeeded];
                         
                         if (scroll) {
                             self.tableView.contentOffset = CGPointMake(0, targetOffset);
                         }
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // Inverts end rect for landscape orientation
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        endFrame = CGRectMake(0.0, endFrame.origin.x, endFrame.size.height, endFrame.size.width);
    }
    
    if (!isKeyboardFrameValid(endFrame)) return;
    
    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect contentViewFrame = self.textContainerView.frame;
    contentViewFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(contentViewFrame);
    
    _keyboardStatus = show ? SLKKeyboardStatusDidShow : SLKKeyboardStatusDidHide;
    
    NSLayoutConstraint *tableViewConstaint = self.view.constraints[1];
    tableViewConstaint.constant = show ? CGRectGetMinY(contentViewFrame) : 0.0;

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:NULL];
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
//    if (_keyboardStatus == SLKKeyboardStatusWillShow || _keyboardStatus == SLKKeyboardStatusWillHide) return;
//    
//    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    CGRect frame = endFrame;
//    CGRect inputFrame = self.textContainerView.frame;
//    
//    if (CGRectEqualToRect(inputFrame, _inputViewRect)) {
//        _keyboardStatus = SLKKeyboardStatusDidHide;
//    }
//    else {
//        _keyboardStatus = SLKKeyboardStatusDragging;
//    }
//    
//    inputFrame.origin.y = CGRectGetMinY(frame)-CGRectGetHeight(inputFrame);
//    
//    self.textContainerView.frame = inputFrame;
//    self.tableView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetMinY(inputFrame));
}

BOOL isKeyboardFrameValid(CGRect frame) {
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
    // Removes all constraints
    [self.view removeConstraints:self.view.constraints];
    
    NSDictionary *views = @{@"tableView": self.tableView, @"textContainerView": self.textContainerView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tableView(>=0)]-0-[textContainerView(>=44)]-(>=0)-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[tableView]-0-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[textContainerView]-0-|" options:0 metrics:nil views:views]];
    
    [super updateViewConstraints];
}

- (void)updateViewConstraintsAnimated:(BOOL)animated
{
    [self updateViewConstraints];
    
    if (!animated) {
        [self.view layoutIfNeeded];
        return;
    }
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
