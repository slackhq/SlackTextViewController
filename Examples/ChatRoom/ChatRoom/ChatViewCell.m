//
//  ChatViewCell.m
//  ChatRoom
//
//  Created by Ignacio Romero Zurbuchen on 9/1/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "ChatViewCell.h"

@implementation ChatViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

        self.textLabel.font = [UIFont systemFontOfSize:16.0];
        self.textLabel.numberOfLines = 0;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.imageView.image = [self blankImageForSize:CGSizeMake(kAvatarSize, kAvatarSize)];
        self.imageView.layer.cornerRadius = roundf(kAvatarSize/2.0);
        self.imageView.layer.masksToBounds = YES;
        self.imageView.layer.shouldRasterize = YES;
        self.imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        self.needsPlaceholder = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect avatarFrame = self.imageView.frame;
    avatarFrame.origin = CGPointMake(kAvatarSize/2.0, kAvatarSize/3.0);
    self.imageView.frame = avatarFrame;
}

#pragma mark - Helpers

- (UIImage *)blankImageForSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:1.0].CGColor);
    CGContextFillRect(context, CGRectMake(0.0, 0.0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
