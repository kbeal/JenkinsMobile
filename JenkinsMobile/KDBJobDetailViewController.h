//
//  KDBDetailViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Job.h"

@interface KDBJobDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) Job *job;

@end
