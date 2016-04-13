//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTypingIndicatorView.h"
#import "UIView+SLKAdditions.h"
#import "SLKUIConstants.h"

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
@synthesize visible = _visible;

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
    self.backgroundColor = [UIColor whiteColor];
    
    self.interval = 6.0;
    self.canResignByTouch = NO;
    self.usernames = [NSMutableArray new];
    self.timers = [NSMutableArray new];
    
    self.textColor = [UIColor grayColor];
    self.textFont = [UIFont systemFontOfSize:12.0];
    self.highlightFont = [UIFont boldSystemFontOfSize:12.0];
    self.contentInset = UIEdgeInsetsMake(10.0, 40.0, 10.0, 10.0);
    
    [self addSubview:self.textLabel];
    
    [self slk_setupConstraints];
}


#pragma mark - SLKTypingIndicatorProtocol

- (void)setVisible:(BOOL)visible
{
    // Skip when updating the same value, specially to avoid inovking KVO unnecessary
    if (self.isVisible == visible) {
        return;
    }
    
    // Required implementation for key-value observer compliance
    [self willChangeValueForKey:NSStringFromSelector(@selector(isVisible))];
    
    _visible = visible;
    
    if (!visible) {
        [self slk_invalidateTimers];
    }
    
    // Required implementation for key-value observer compliance
    [self didChangeValueForKey:NSStringFromSelector(@selector(isVisible))];
}

- (void)dismissIndicator
{
    if (self.isVisible) {
        self.visible = NO;
    }
}


#pragma mark - Getters

- (UILabel *)textLabel
{
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.contentMode = UIViewContentModeTopLeft;
        _textLabel.userInteractionEnabled = NO;
    }
    return _textLabel;
}

- (NSAttributedString *)attributedString
{
    if (self.usernames.count == 0) {
        return nil;
    }
    
    NSString *text = @"";
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

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, [self height]);
}

- (CGFloat)height
{
    CGFloat height = self.textFont.lineHeight;
    height += self.contentInset.top;
    height += self.contentInset.bottom;
    return height;
}


#pragma mark - Setters

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

- (void)setHidden:(BOOL)hidden
{
    if (self.isHidden == hidden) {
        return;
    }
    
    if (hidden) {
        [self slk_prepareForReuse];
    }
    
    [super setHidden:hidden];
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
    
    NSAttributedString *attributedString = [self attributedString];
    
    self.textLabel.attributedText = attributedString;
    
    self.visible = YES;
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
    else {
        self.visible = NO;
    }
}


#pragma mark - Private Methods

- (void)slk_shouldRemoveUsername:(NSTimer *)timer
{
    NSString *identifier = [timer.userInfo objectForKey:SLKTypingIndicatorViewIdentifier];
    
    [self removeUsername:identifier];
    [self slk_invalidateTimer:timer];
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

- (void)slk_prepareForReuse
{
    [self slk_invalidateTimers];
    
    self.textLabel.text = nil;
    
    [self.usernames removeAllObjects];
}

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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if (self.canResignByTouch) {
        [self dismissIndicator];
    }
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [self slk_prepareForReuse];
    
    _textLabel = nil;
    _usernames = nil;
    _timers = nil;
}

@end
