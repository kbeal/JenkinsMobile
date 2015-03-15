//
//  KDBMasterViewController.m
//  JenkinsMobile
//
//  Created by Kyle on 3/14/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "KDBMasterViewController.h"
#import "KDBViewsTableViewController.h"

@interface KDBMasterViewController ()

@end

@implementation KDBMasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UINavigationController *viewsNavController = (UINavigationController *)[self.viewControllers objectAtIndex:0];
    KDBViewsTableViewController *viewsTableController = (KDBViewsTableViewController *)viewsNavController.topViewController;
    viewsTableController.managedObjectContext = self.managedObjectContext;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
