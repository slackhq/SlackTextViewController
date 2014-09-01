//
//  ChatViewCell.m
//  ChatRoom
//
//  Created by Ignacio Romero Z. on 9/1/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "ChatViewCell.h"

@implementation ChatViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
