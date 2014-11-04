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

#import "SLKTypingIndicatorView.h"
#import "SLKUIConstants.h"

NSString * const SLKTypingIndicatorViewWillShowNotification =   @"SLKTypingIndicatorViewWillShowNotification";
NSString * const SLKTypingIndicatorViewWillHideNotification =   @"SLKTypingIndicatorViewWillHideNotification";

#define SLKTypingIndicatorViewIdentifier    [NSString stringWithFormat:@"%@.%@", SLKTextViewControllerDomain, NSStringFromClass([self class])]

@interface SLKTypingIndicatorView ()

@property (nonatomic, strong) NSMutableArray *usernames;
@property (nonatomic, strong) NSMutableArray *timers;
@property (nonatomic, strong) UILabel *indicatorLabel;

@end

@implementation SLKTypingIndicatorView

#pragma mark - Initializer

- (id)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.height = 30.0;
    self.interval = 6.0;
    self.canResignByTouch = YES;
    self.usernames = [NSMutableArray new];
    self.timers = [NSMutableArray new];
    
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.indicatorLabel];
    
    [self setupConstraints];
}


#pragma mark - UIView Overrides

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
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
        _indicatorLabel.backgroundColor = [UIColor clearColor];
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
    
    if (_usernames.count == 1) {
        text = [NSString stringWithFormat:NSLocalizedString(@"%@ is typing", nil), [_usernames firstObject]];
    }
    else if (_usernames.count == 2) {
        text = [NSString stringWithFormat:NSLocalizedString(@"%@ & %@ are typing", nil), [_usernames firstObject], [_usernames lastObject]];
    }
    else if (_usernames.count > 2) {
        text = NSLocalizedString(@"Several people are typing", nil);
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentLeft;
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.minimumLineHeight = 10.0;
    
    [attributedString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0.0, text.length)];
    
    if (_usernames.count <= 2) {
        [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0] range:[text rangeOfString:[_usernames firstObject]]];
        [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0] range:[text rangeOfString:[_usernames lastObject]]];
    }
    
    return attributedString;
}

- (NSTimer *)timerWithIdentifier:(NSString *)identifier
{
    for (NSTimer *timer in _timers) {
        if ([identifier isEqualToString:[timer.userInfo objectForKey:SLKTypingIndicatorViewIdentifier]]) {
            return timer;
        }
    }
    
    return nil;
}


#pragma mark - Setters

- (void)setVisible:(BOOL)visible
{
    if (visible == _visible) {
        return;
    }
    
    NSString *notificationName = visible ? SLKTypingIndicatorViewWillShowNotification : SLKTypingIndicatorViewWillHideNotification;
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    
    _visible = visible;
    
    if (!visible) {
        [self clean];
    }
}

#pragma mark - Public Methods

- (void)insertUsername:(NSString *)username;
{
    if (!username) {
        return;
    }
    
    BOOL isShowing = [_usernames containsObject:username];
    
    if (_interval > 0.0) {
        
        if (isShowing) {
            NSTimer *timer = [self timerWithIdentifier:username];
            [self invalidateTimer:timer];
        }
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:_interval target:self selector:@selector(shouldRemoveUsername:) userInfo:@{SLKTypingIndicatorViewIdentifier: username} repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [_timers addObject:timer];
    }
    
    if (isShowing) {
        return;
    }
    
    [_usernames addObject:username];
    
    NSAttributedString *text = [self attributedString];
    
    _indicatorLabel.attributedText = text;
    
    if (!self.isVisible) {
        [self setVisible:YES];
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
        [self setVisible:NO];
    }
}

- (void)dismissIndicator
{
    if (self.isVisible) {
        [self setVisible:NO];
    }
}


#pragma mark - Dimissing Methods

- (void)shouldRemoveUsername:(NSTimer *)timer
{
    NSString *identifier = [timer.userInfo objectForKey:SLKTypingIndicatorViewIdentifier];
    
    [self removeUsername:identifier];
    [self invalidateTimer:timer];
}


#pragma mark - Cleaning Methods

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


#pragma mark - View Auto-Layout

- (void)setupConstraints
{
    NSNumber *lineHeight = @(roundf(self.indicatorLabel.font.lineHeight));
    NSNumber *padding = @(roundf((self.height-[lineHeight floatValue]) / 2.0));
    
    NSDictionary *views = @{@"label": self.indicatorLabel};
    NSDictionary *metrics = @{@"lineHeight": lineHeight, @"padding": padding};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=padding)-[label(lineHeight)]-(<=padding)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(40)-[label]-(<=20)-|" options:0 metrics:metrics views:views]];
    
    [self layoutIfNeeded];
}


#pragma mark - Hit Testing

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    
    if ([view isEqual:self]) {
        if (self.isVisible && self.canResignByTouch) {
            [self setVisible:NO];
        }
        return view;
    }
    return view;
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [self clean];
    
    _indicatorLabel = nil;
    _usernames = nil;
    _timers = nil;
}

@end