//
//  KDBJobTableViewCell.m
//  JenkinsMobile
//
//  Created by Kyle on 8/7/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJobTableViewCell.h"

@implementation KDBJobTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        // THIS IS A LIE AND ISN"T CALLED FOR STORYBOARD PROTOTYPE CELLS
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
