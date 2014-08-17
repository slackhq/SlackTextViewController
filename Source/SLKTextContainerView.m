//
//  SLKTextContainerView.m
//  ChatRoom
//
//  Created by Ignacio Romero Z. on 8/16/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SLKTextContainerView.h"

#define kTextViewVerticalPadding 5
#define kTextViewHorizontalPadding 8

NSString * const SLKInputAccessoryViewKeyboardFrameDidChangeNotification = @"com.slack.chatkit.keyboard.frameDidChange";

@interface SLKInputAccessoryView : UIView
@end

@interface SLKTextContainerView ()
@property (nonatomic, copy) NSString *rightButtonTitle;
@end

@implementation SLKTextContainerView
@synthesize translucent = _translucent;

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure
{
    _translucent = NO;
    
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self addSubview:self.textView];
    
    [self updateConstraints];
    
    // textView notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)dealloc
{
    _leftButton = nil;
    _rightButton = nil;
    _textView = nil;
    
    // textView notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
}

#pragma mark - Setters

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(CGRectGetHeight(self.superview.frame), 44.0);
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
        _textView.keyboardType = UIKeyboardTypeTwitter;
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
        
        _rightButtonTitle = NSLocalizedString(@"Send", nil);
        
        [_rightButton setTitle:_rightButtonTitle forState:UIControlStateNormal];
        [_rightButton sizeToFit];
        [_rightButton setTitle:@"" forState:UIControlStateNormal];
    }
    return _rightButton;
}


#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;
    self.textView.inputAccessoryView.backgroundColor = color;
}


#pragma mark - Notifications

- (void)didChangeTextView:(NSNotification *)notification
{
    NSString *title = (self.textView.text.length > 0) ? self.rightButtonTitle : @"";
    NSString *rightTitle = [self.rightButton titleForState:UIControlStateNormal];
    
    if (![title isEqualToString:rightTitle]) {
        [self.rightButton setTitle:title forState:UIControlStateNormal];
        [self updateConstraintsAnimated:YES];
    }
}


#pragma mark - View Auto-Layout

- (void)updateConstraints
{
    // Removes all constraints
    [self removeConstraints:self.constraints];

    CGFloat minHeight = self.intrinsicContentSize.height;

    CGFloat leftButtonMargin = roundf((minHeight - self.leftButton.frame.size.height) / 2.0f);
    CGFloat rightButtonMargin = roundf((minHeight - self.rightButton.frame.size.height) / 2.0f);
    
    NSString *rightTitle = [self.rightButton titleForState:UIControlStateNormal];
    CGSize rigthButtonSize = [rightTitle sizeWithAttributes:@{NSFontAttributeName: self.rightButton.titleLabel.font}];
    CGFloat rightButtonWidth = rigthButtonSize.width+kTextViewHorizontalPadding/2.0f;
    
    NSDictionary *views = @{@"textView": self.textView, @"leftButton": self.leftButton, @"rightButton": self.rightButton};
    NSDictionary *metrics = @{@"hor" : @(kTextViewHorizontalPadding), @"ver" : @(kTextViewVerticalPadding), @"leftButtonMargin" : @(leftButtonMargin), @"rightButtonMargin" : @(rightButtonMargin), @"rightButtonWidth": @(rightButtonWidth)};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[leftButton]-(==hor)-[textView]-(==hor)-[rightButton(rightButtonWidth)]-(==hor)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=leftButtonMargin)-[leftButton]-(==leftButtonMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=rightButtonMargin)-[rightButton]-(==rightButtonMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==ver)-[textView]-(==ver)-|" options:0 metrics:metrics views:views]];
    
    [super updateConstraints];
}

- (void)updateConstraintsAnimated:(BOOL)animated
{
    [self updateConstraints];
    
    if (!animated) {
        [self layoutIfNeeded];
        return;
    }
    
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [_rightButton sizeToFit];
                         [self layoutIfNeeded];
                     }
                     completion:NULL];
}

@end

@implementation SLKInputAccessoryView

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

- (void)dealloc
{
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
    }
}

@end
