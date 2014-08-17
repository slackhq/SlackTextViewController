//
//  SLKChatTableViewController.m
//  SLKChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SLKChatTableViewController.h"

@interface SLKChatTableViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
{
    CGFloat _minYOffset;
    UIGestureRecognizer *_dismissingGesture;
    
    CGFloat _tableViewHeight;
    CGFloat _containerViewHeight;
    CGFloat _containerViewBottomMargin;
    
    CGFloat _textContentHeight;
}

@property (nonatomic) BOOL didDrag;

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
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}


#pragma mark - Notification Events

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    endFrame = adjustEndFrame(endFrame, self.interfaceOrientation);
    
    if (!isKeyboardFrameValid(endFrame)) return;

    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect inputFrame = self.textContainerView.frame;
    inputFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(inputFrame);
    
    _tableViewHeight = show ? CGRectGetMinY(inputFrame) : 0.0;
    _containerViewBottomMargin = show ? endFrame.size.height : 0.0;
    
    CGFloat scrollingGap = CGRectGetHeight(endFrame);
    CGFloat targetOffset = self.tableView.contentOffset.y+(show ? scrollingGap : -scrollingGap);
    
    CGFloat currentYOffset = self.tableView.contentOffset.y;
    CGFloat maxYOffset = self.tableView.contentSize.height-(CGRectGetHeight(self.view.frame)-CGRectGetHeight(inputFrame));
    
    BOOL scroll = (((!show && targetOffset != currentYOffset && targetOffset > (_minYOffset-scrollingGap) && targetOffset < (maxYOffset-scrollingGap+_minYOffset)) || show) && !self.didDrag);
    
    [self updateViewConstraints];

    [UIView animateWithDuration:duration*3
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.7
                        options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionCurveEaseInOut
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
    
    endFrame = adjustEndFrame(endFrame, self.interfaceOrientation);
    
    if (!isKeyboardFrameValid(endFrame)) return;
    
    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardDidShowNotification];
    
    CGRect inputFrame = self.textContainerView.frame;
    inputFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(inputFrame);
    
    NSLayoutConstraint *tableViewConstaint = self.view.constraints[1];
    tableViewConstaint.constant = show ? CGRectGetMinY(inputFrame) : 0.0;
    
    [self updateViewConstraints];

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         if (self.didDrag) {
                             self.didDrag = NO;
                         }
                     }];
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
    if (self.tableView.isDragging) {
        self.didDrag = YES;
    }

    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect inputFrame = self.textContainerView.frame;
    
    inputFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(inputFrame);

    _tableViewHeight = CGRectGetMinY(inputFrame);
    _containerViewBottomMargin = CGRectGetHeight(self.view.frame)-endFrame.origin.y;
    
    [self updateViewConstraintsAnimated:!self.tableView.isDragging];
}

- (void)didChangeTextView:(NSNotification *)notification
{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    CGSize textContentSize = textView.contentSize;
    
    if (_textContentHeight == 0) {
        _textContentHeight = textContentSize.height;
    }
    
    if (textContentSize.height != _textContentHeight) {
        
        _textContentHeight = textContentSize.height;
        
        CGFloat delta = textContentSize.height-_textContentHeight;
        NSLog(@"delta : %f", delta);
        
        _containerViewHeight = _textContentHeight+delta+(kTextViewVerticalPadding*2);
        
        CGRect inputFrame = self.textContainerView.frame;
        inputFrame.size.height = _containerViewHeight;
        inputFrame.origin.y  = _containerViewBottomMargin-CGRectGetHeight(inputFrame);
        
        _tableViewHeight = CGRectGetMinY(inputFrame);
        
        NSLog(@"_containerViewHeight : %f", _containerViewHeight);
        NSLog(@"_tableViewHeight : %f", _tableViewHeight);

        [self updateViewConstraintsAnimated:YES];
    }
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


#pragma mark - NSNotificationCenter register/unregister

- (void)registerNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeyboardFrame:) name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
    
    // textView notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)unregisterNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
    // textView notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
}


#pragma mark - View Auto-Layout

- (void)updateViewConstraints
{
    // Removes all constraints
    [self.view removeConstraints:self.view.constraints];
    
    NSDictionary *views = @{@"tableView": self.tableView, @"textContainerView": self.textContainerView};
    NSDictionary *metrics = @{@"tableHeight": @(_tableViewHeight), @"containerHeight": @(_containerViewHeight), @"bottomMargin": @(_containerViewBottomMargin)};

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tableView(>=tableHeight)]-(==0)-[textContainerView(>=containerHeight)]-(bottomMargin)-|" options:0 metrics:metrics views:views]];
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
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:NULL];
}


#pragma mark - Convenience Methods

CGRect adjustEndFrame(CGRect endFrame, UIInterfaceOrientation orientation) {
    
    // Inverts the end rect for landscape orientation
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        endFrame = CGRectMake(0.0, endFrame.origin.x, endFrame.size.height, endFrame.size.width);
    }
    
    return endFrame;
}

BOOL isKeyboardFrameValid(CGRect frame) {
    if ((frame.origin.y > CGRectGetHeight([UIScreen mainScreen].bounds)) ||
        (frame.size.height < 1) || (frame.size.width < 1) || (frame.origin.y < 0)) {
        return NO;
    }
    return YES;
}


#pragma mark - View Auto-Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods
{
    return YES;
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
