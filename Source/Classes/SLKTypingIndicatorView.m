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
#import "UIView+SLKAdditions.h"
#import "SLKUIConstants.h"

NSString * const SLKTypingIndicatorViewWillShowNotification =   @"SLKTypingIndicatorViewWillShowNotification";
NSString * const SLKTypingIndicatorViewWillHideNotification =   @"SLKTypingIndicatorViewWillHideNotification";

#define SLKTypingIndicatorViewIdentifier    [NSString stringWithFormat:@"%@.%@", SLKTextViewControllerDomain, NSStringFromClass([self class])]

@interface SLKTypingIndicatorView ()

// The text label used to display the typing indicator content.
@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) NSMutableArray *usernames;
@property (nonatomic, strong) NSMutableArray *timers;

// Auto-Layout margin constraints used for updating their constants
@property (nonatomic, strong) NSLayoutConstraint *leftContraint;
@property (nonatomic, strong) NSLayoutConstraint *rightContraint;

@end

@implementation SLKTypingIndicatorView

#pragma mark - Initializer

- (id)init
{
    if (self = [super init]) {
        [self slk_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self slk_commonInit];
    }
    return self;
}

- (void)slk_commonInit
{
    self.interval = 6.0;
    self.canResignByTouch = YES;
    self.usernames = [NSMutableArray new];
    self.timers = [NSMutableArray new];
    
    self.textColor = [UIColor grayColor];
    self.textFont = [UIFont systemFontOfSize:12.0];
    self.highlightFont = [UIFont boldSystemFontOfSize:12.0];
    self.contentInset = UIEdgeInsetsMake(10.0, 40.0, 10.0, 10.0);
    
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.textLabel];
    
    [self slk_setupConstraints];
}


#pragma mark - UIView Overrides

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, [self height]);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}


#pragma mark - Getters

- (UILabel *)textLabel
{
    if (!_textLabel)
    {
        _textLabel = [UILabel new];
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.userInteractionEnabled = NO;
        _textLabel.hidden = YES;
    }
    return _textLabel;
}

- (NSAttributedString *)attributedString
{
    if (self.usernames.count == 0) {
        return nil;
    }
    
    NSString *text = nil;
    NSString *firstObject = [self.usernames firstObject];
    NSString *lastObject = [self.usernames lastObject];
    
    if (self.usernames.count == 1) {
        text = [NSString stringWithFormat:NSLocalizedString(@"%@ is typing", nil), firstObject];
    }
    else if (self.usernames.count == 2) {
        text = [NSString stringWithFormat:NSLocalizedString(@"%@ & %@ are typing", nil), firstObject, lastObject];
    }
    else if (self.usernames.count > 2) {
        text = NSLocalizedString(@"Several people are typing", nil);
    }
    
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentLeft;
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.minimumLineHeight = 10.0;
    
    NSDictionary *attributes = @{NSFontAttributeName: self.textFont,
                                 NSForegroundColorAttributeName: self.textColor,
                                 NSParagraphStyleAttributeName: style,
                                 };
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    
    if (self.usernames.count <= 2) {
        [attributedString addAttribute:NSFontAttributeName value:self.highlightFont range:[text rangeOfString:firstObject]];
        [attributedString addAttribute:NSFontAttributeName value:self.highlightFont range:[text rangeOfString:lastObject]];
    }
    
    return attributedString;
}

- (CGFloat)height
{
    CGFloat height = self.textFont.lineHeight;
    height += self.contentInset.top;
    height += self.contentInset.bottom;
    return height;
}


- (NSTimer *)slk_timerWithIdentifier:(NSString *)identifier
{
    for (NSTimer *timer in self.timers) {
        if ([identifier isEqualToString:[timer.userInfo objectForKey:SLKTypingIndicatorViewIdentifier]]) {
            return timer;
        }
    }
    return nil;
}


#pragma mark - Setters

- (void)setVisible:(BOOL)visible
{
    if (visible == self.visible) {
        return;
    }
    
    NSString *notificationName = visible ? SLKTypingIndicatorViewWillShowNotification : SLKTypingIndicatorViewWillHideNotification;
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    
    if (visible) {
        self.textLabel.hidden = NO;
    }
    else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.textLabel.hidden = YES;
        });
    }
    
    _visible = visible;
    
    if (!visible) {
        [self slk_cleanAll];
    }
}

- (void)setContentInset:(UIEdgeInsets)insets
{
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, insets)) {
        return;
    }
    
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, UIEdgeInsetsZero)) {
        _contentInset = insets;
        return;
    }
    
    _contentInset = insets;
    
    [self slk_updateConstraintConstants];
}


#pragma mark - Public Methods

- (void)insertUsername:(NSString *)username;
{
    if (!username) {
        return;
    }
    
    BOOL isShowing = [self.usernames containsObject:username];
    
    if (_interval > 0.0) {
        
        if (isShowing) {
            NSTimer *timer = [self slk_timerWithIdentifier:username];
            [self slk_invalidateTimer:timer];
        }
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:_interval target:self selector:@selector(slk_shouldRemoveUsername:) userInfo:@{SLKTypingIndicatorViewIdentifier: username} repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [self.timers addObject:timer];
    }
    
    if (isShowing) {
        return;
    }
    
    [self.usernames addObject:username];
    
    self.textLabel.attributedText = [self attributedString];
    
    if (!self.isVisible) {
        [self setVisible:YES];
    }
}

- (void)removeUsername:(NSString *)username
{
    if (!username || ![self.usernames containsObject:username]) {
        return;
    }

    [self.usernames removeObject:username];
    
    if (self.usernames.count > 0) {
        self.textLabel.attributedText = [self attributedString];
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


#pragma mark - Private Methods

- (void)slk_shouldRemoveUsername:(NSTimer *)timer
{
    NSString *identifier = [timer.userInfo objectForKey:SLKTypingIndicatorViewIdentifier];
    
    [self removeUsername:identifier];
    [self slk_invalidateTimer:timer];
}

- (void)slk_invalidateTimer:(NSTimer *)timer
{
    if (timer) {
        [timer invalidate];
        [self.timers removeObject:timer];
        timer = nil;
    }
}

- (void)slk_invalidateTimers
{
    for (NSTimer *timer in self.timers) {
        [timer invalidate];
    }
    
    [self.timers removeAllObjects];
}

- (void)slk_cleanAll
{
    [self slk_invalidateTimers];
    
    self.textLabel.text = nil;
    
    [self.usernames removeAllObjects];
}


#pragma mark - View Auto-Layout

- (void)slk_setupConstraints
{
    NSDictionary *views = @{@"textLabel": self.textLabel};

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textLabel]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[textLabel]-(0@750)-|" options:0 metrics:nil views:views]];
    
    self.leftContraint = [[self slk_constraintsForAttribute:NSLayoutAttributeLeading] firstObject];
    self.rightContraint = [[self slk_constraintsForAttribute:NSLayoutAttributeTrailing] firstObject];
    
    [self slk_updateConstraintConstants];
}

- (void)slk_updateConstraintConstants
{
    self.leftContraint.constant = self.contentInset.left;
    self.rightContraint.constant = self.contentInset.right;
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
    [self slk_cleanAll];
    
    _textLabel = nil;
    _usernames = nil;
    _timers = nil;
}

@end