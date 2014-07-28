//
//  KDBJobConfigViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 7/23/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KDBJobConfigViewController : UIViewController

@property (nonatomic, weak) IBOutlet UISegmentedControl *jobViewSwitcher;
- (IBAction)jobViewSwitcherUnwind:(UIStoryboardSegue *)segue;

@end
