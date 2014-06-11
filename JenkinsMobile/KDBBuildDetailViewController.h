//
//  KDBBuildDetailViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 5/14/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Build.h"
#import "KDBMasterViewControllerDelegate.h"
#import "KDBDetailViewControllerDelegate.h"

@interface KDBBuildDetailViewController : UIViewController <KDBDetailViewControllerDelegate>

- (void)configureView;

@property (strong, nonatomic) Build *build;
@property (nonatomic, weak) id<KDBMasterViewControllerDelegate> masterVCDelegate;

@end
