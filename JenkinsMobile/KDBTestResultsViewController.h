//
//  KDBTestResultsViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 5/14/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Build.h"

@interface KDBTestResultsViewController : UIViewController

- (void)configureView;

@property (strong, nonatomic) Build *build;

@end
