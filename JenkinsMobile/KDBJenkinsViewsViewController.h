//
//  KDBJenkinsViewsViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/30/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KDBJenkinsViewsScrollView.h"

@interface KDBJenkinsViewsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    IBOutlet KDBJenkinsViewsScrollView *jenkinsViewsScrollView;
}

// Dictionary mapping jenkins views to the jobs they contain
@property (strong, nonatomic) NSMutableDictionary *jenkinsViewsJobs;
@property (strong, nonatomic) NSString *currentURL;
@property (strong, nonatomic) UITableView *currentView;

@end
