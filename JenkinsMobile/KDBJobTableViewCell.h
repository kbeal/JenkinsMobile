//
//  KDBJobTableViewCell.h
//  JenkinsMobile
//
//  Created by Kyle on 8/7/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>

@interface KDBJobTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet SKView *statusBallContainerView;
@property (weak, nonatomic) IBOutlet UILabel *projectNamelabel;

@end
