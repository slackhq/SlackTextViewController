//
//  SCKTypeIndicatorView.m
//  Slack
//
//  Created by Ignacio on 5/13/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SCKTypeIndicatorView.h"

NSString * const SCKTypeIndicatorViewWillShowOrHideNotification = @"com.slack.chatkit.SCKTypeIndicatorView.willShowOrHide";
NSString * const SCKTypeIndicatorViewIdentifier = @"identifier";

@interface SCKTypeIndicatorView ()

@property (nonatomic, strong) NSMutableArray *usernames;
@property (nonatomic, strong) NSMutableArray *timers;

@property (nonatomic, strong) UILabel *indicatorLabel;

@end

@implementation SCKTypeIndicatorView

#pragma mark - Initializer

- (id)init
{
    self = [super init];
    if (self) {
        self.height = 30.0;
        self.interval = 6.0;
        self.canResignByTouch = YES;
        self.usernames = [NSMutableArray new];
        self.timers = [NSMutableArray new];
        
        self.backgroundColor = [UIColor redColor];
        
        [self addSubview:self.indicatorLabel];
        
        [self updateConstraints];
    }
    return self;
}

- (void)dealloc
{
    [self clean];
    
    _indicatorLabel = nil;
    _usernames = nil;
    _timers = nil;
}


#pragma mark - Getters

- (UILabel *)indicatorLabel
{
    if (!_indicatorLabel)
    {
        _indicatorLabel = [UILabel new];
        _indicatorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _indicatorLabel.font = [UIFont systemFontOfSize:12.0];
        _indicatorLabel.textColor =[UIColor grayColor];
        _indicatorLabel.backgroundColor = [UIColor blueColor];
        _indicatorLabel.userInteractionEnabled = NO;
    }
    return _indicatorLabel;
}

- (NSAttributedString *)attributedString
{
    if (_usernames.count == 0) {
        return nil;
    }
    
    NSString *text = nil;
    
    if (_usernames.count == 1) text = [NSString stringWithFormat:@"%@ is typing", [_usernames firstObject]];
    else if (_usernames.count == 2) text = [NSString stringWithFormat:@"%@ & %@ are typing", [_usernames firstObject], [_usernames lastObject]];
    else if (_usernames.count > 2) text = @"several people are typing";
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentLeft;
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.minimumLineHeight = 10.0;
    
    [attributedString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, text.length)];
    
    if (_usernames.count <= 2) {
        [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0] range:[text rangeOfString:[_usernames firstObject]]];
        [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0] range:[text rangeOfString:[_usernames lastObject]]];
    }
    
    return attributedString;
}

- (NSTimer *)timerWithIdentifier:(NSString *)identifier
{
    for (NSTimer *timer in _timers) {
        if ([identifier isEqualToString:[timer.userInfo objectForKey:SCKTypeIndicatorViewIdentifier]]) {
            return timer;
        }
    }
    
    return nil;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(CGRectGetWidth(self.superview.frame), self.height);
}


#pragma mark - Setters

- (void)setVisible:(BOOL)visible
{
    [self setVisible:visible animated:NO];
}

- (void)setVisible:(BOOL)visible animated:(BOOL)animated
{
    if (visible == _visible) {
        return;
    }
    
    _visible = visible;
    
    if (!visible) {
        [self clean];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SCKTypeIndicatorViewWillShowOrHideNotification object:self];
}


#pragma mark - Public Methods

- (void)insertUsername:(NSString *)username;
{
    if (!username) {
        return;
    }
    
    BOOL isShowing = [_usernames containsObject:username];
    
    if (_interval > 0) {
        
        if (isShowing) {
            NSTimer *timer = [self timerWithIdentifier:username];
            [self invalidateTimer:timer];
        }
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:_interval target:self selector:@selector(shouldRemoveUsername:) userInfo:@{SCKTypeIndicatorViewIdentifier: username} repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [_timers addObject:timer];
    }
    
    if (isShowing) {
        return;
    }
    
    [_usernames addObject:username];
    
    _indicatorLabel.attributedText = [self attributedString];
    
    if (!self.isVisible) {
        [self setVisible:YES animated:YES];
    }
}

- (void)removeUsername:(NSString *)username
{
    if (!username || ![_usernames containsObject:username]) {
        return;
    }
    
    [_usernames removeObject:username];
    
    if (_usernames.count > 0) {
        _indicatorLabel.attributedText = [self attributedString];
    }
    else if (self.isVisible) {
        [self setVisible:NO animated:YES];
    }
}

- (void)dismissIndicator
{
    if (self.isVisible) {
        [self setVisible:NO animated:YES];
    }
}


#pragma mark - Dimissing methods

- (void)shouldRemoveUsername:(NSTimer *)timer
{
    NSString *identifier = [timer.userInfo objectForKey:SCKTypeIndicatorViewIdentifier];
    
    [self removeUsername:identifier];
    [self invalidateTimer:timer];
}


#pragma mark - Cleaning methods

- (void)invalidateTimer:(NSTimer *)timer
{
    if (timer) {
        [timer invalidate];
        [_timers removeObject:timer];
        timer = nil;
    }
}

- (void)invalidateTimers
{
    for (NSTimer *timer in _timers) {
        [timer invalidate];
    }
    
    [_timers removeAllObjects];
}

- (void)clean
{
    [self invalidateTimers];
    
    _indicatorLabel.text = nil;
    
    [_usernames removeAllObjects];
}


#pragma mark - Auto-Layout

- (void)updateConstraints
{
    [super updateConstraints];
    
    NSNumber *lineHeight = @(roundf(self.indicatorLabel.font.lineHeight));
    NSNumber *padding = @((self.height-[lineHeight floatValue])/2.0);
    
    NSDictionary *views = @{@"label": self.indicatorLabel};
    NSDictionary *metrics = @{@"lineHeight": lineHeight, @"padding": padding};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=padding)-[label(==lineHeight)]-(<=padding)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==40)-[label]-(==20)-|" options:0 metrics:metrics views:views]];
}


#pragma mark - Hit Testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    
    if ([view isEqual:self]) {
        if (self.isVisible && self.canResignByTouch) {
            [self setVisible:NO animated:YES];
        }
        return view;
    }
    return view;
}

@end