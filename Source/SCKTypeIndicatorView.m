//
//  SCKTypeIndicatorView.m
//  Slack
//
//  Created by Ignacio on 5/13/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SCKTypeIndicatorView.h"

#define kIndentifierKey @"identifier"

@interface SCKTypeIndicatorView ()

@property (nonatomic, strong) NSMutableArray *usernames;
@property (nonatomic, strong) NSMutableArray *timers;

@property (nonatomic, strong) UILabel *indicatorLabel;

@end

@implementation SCKTypeIndicatorView

- (id)init
{
    self = [super init];
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        _interval = 6.0;
        _height = 24.0;
        _canResignByTouch = NO;
        
        _usernames = [NSMutableArray new];
        _timers = [NSMutableArray new];
        
        [self addSubview:self.indicatorLabel];
    }
    return self;
}

- (void)sizeToFit
{
    [super sizeToFit];
    
    if (self.didChangeSize)
    {
        CGSize size = [self sizeThatFits:self.frame.size];
        self.didChangeSize(size);
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.superview.frame.size.width, size.height);
        self.indicatorLabel.frame = CGRectMake(56.0, 2.0, self.frame.size.width-(56.0+10.0), 16.0);
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size.height = self.isVisible ? _height : 0.0;
    return size;
}


#pragma mark - Getter methods

- (UILabel *)indicatorLabel
{
    if (!_indicatorLabel)
    {
        _indicatorLabel = [UILabel new];
        _indicatorLabel.backgroundColor = [UIColor clearColor];
        _indicatorLabel.font = [UIFont systemFontOfSize:12.0];
        _indicatorLabel.textColor =[UIColor grayColor];
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
        if ([identifier isEqualToString:[timer.userInfo objectForKey:kIndentifierKey]]) {
            return timer;
        }
    }
    
    return nil;
}


#pragma mark - Setter methods

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
    
    [self sizeToFit];
}


#pragma mark - SCKTypeIndicatorView methods

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
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:_interval target:self selector:@selector(shouldRemoveUsername:) userInfo:@{kIndentifierKey: username} repeats:NO];
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

- (void)shouldRemoveUsername:(NSTimer *)timer
{
    NSString *identifier = [timer.userInfo objectForKey:kIndentifierKey];
    
    [self removeUsername:identifier];
    [self invalidateTimer:timer];
}


#pragma mark - Dimissing methods

- (void)dismissIndicator
{
    if (self.isVisible) {
        [self setVisible:NO animated:YES];
    }
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

- (void)dealloc
{
    [self clean];
    
    _didChangeSize = nil;
    _usernames = nil;
    _timers = nil;
    
    _indicatorLabel = nil;
}


#pragma mark - Hit Testing methods

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