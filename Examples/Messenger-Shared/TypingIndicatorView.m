//
//  TypingIndicatorView.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 6/27/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "TypingIndicatorView.h"

@interface TypingIndicatorView ()
@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@end

@implementation TypingIndicatorView
@synthesize visible = _visible;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self configureSubviews];
    }
    return self;
}

- (void)configureSubviews
{
    [self addSubview:self.thumbnailView];
    [self addSubview:self.titleLabel];
    [self.layer insertSublayer:self.backgroundGradient atIndex:0];

    NSDictionary *views = @{@"thumbnailView": self.thumbnailView,
                            @"titleLabel": self.titleLabel
                            };
    
    NSDictionary *metrics = @{@"invertedThumbSize": @(-kTypingIndicatorViewAvatarHeight/2.0),
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[thumbnailView]-10-[titleLabel]-(>=0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[thumbnailView]-(invertedThumbSize)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[titleLabel]-(3@750)-|" options:0 metrics:metrics views:views]];
}


#pragma mark - SLKTypingIndicatorProtocol

- (void)dismissIndicator
{
    if (self.isVisible) {
        self.visible = NO;
    }
}


#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundGradient.frame = self.bounds;
}


#pragma mark - Getters

- (UIImageView *)thumbnailView
{
    if (!_thumbnailView) {
        _thumbnailView = [UIImageView new];
        _thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
        _thumbnailView.userInteractionEnabled = NO;
        _thumbnailView.backgroundColor = [UIColor grayColor];
        _thumbnailView.contentMode = UIViewContentModeTopLeft;

        _thumbnailView.layer.cornerRadius = kTypingIndicatorViewAvatarHeight/2.0;
        _thumbnailView.layer.masksToBounds = YES;
    }
    return _thumbnailView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.userInteractionEnabled = NO;
        _titleLabel.numberOfLines = 1;
        _titleLabel.contentMode = UIViewContentModeTopLeft;
        
        _titleLabel.font = [UIFont systemFontOfSize:12.0];
        _titleLabel.textColor = [UIColor lightGrayColor];
    }
    return _titleLabel;
}

- (CAGradientLayer *)backgroundGradient
{
    if (!_backgroundGradient) {
        _backgroundGradient = [CAGradientLayer layer];
        _backgroundGradient.frame = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [self height]);
        
        _backgroundGradient.colors = @[(id)[UIColor colorWithWhite:1.0 alpha:0].CGColor,
                                       (id)[UIColor colorWithWhite:1.0 alpha:0.9].CGColor,
                                       (id)[UIColor colorWithWhite:1.0 alpha:1.0].CGColor];
        
        _backgroundGradient.locations = @[@0, @0.5, @1];
        _backgroundGradient.rasterizationScale = [UIScreen mainScreen].scale;
        _backgroundGradient.shouldRasterize = YES;
    }
    return _backgroundGradient;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, [self height]);
}

- (CGFloat)height
{
    CGFloat height = 13.0;
    height += self.titleLabel.font.lineHeight;
    return height;
}


#pragma mark - TypingIndicatorView

- (void)presentIndicatorWithName:(NSString *)name image:(UIImage *)image
{
    if (self.isVisible || name.length == 0 || !image) {
        return;
    }
    
    NSString *text = [NSString stringWithFormat:@"%@ is typing...", name];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedString addAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:12.0]} range:[text rangeOfString:name]];
    
    self.titleLabel.attributedText = attributedString;
    self.thumbnailView.image = image;

    self.visible = YES;
}


#pragma mark - Hit Testing

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    [self dismissIndicator];
}


#pragma mark - Lifeterm

- (void)dealloc
{
    _titleLabel = nil;
    _thumbnailView = nil;
    _backgroundGradient = nil;
}

@end
