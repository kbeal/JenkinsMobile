//
//  KDBBuildDetailViewController.m
//  JenkinsMobile
//
//  Created by Kyle on 5/14/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBBuildDetailViewController.h"

@interface KDBBuildDetailViewController ()

@end

@implementation KDBBuildDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setBuild:(Build *)newBuild
{
    if (_build != newBuild) {
        _build = newBuild;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.build) {
        self.navigationItem.title = [self.build.number stringValue];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.masterVCDelegate = (id<KDBMasterViewControllerDelegate>)[[[self.splitViewController viewControllers] firstObject] topViewController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // back button was pressed
    if (self.isMovingFromParentViewController) {
        // move back on master nav controller as well
        [self.masterVCDelegate popNavigationController];
    }
}


#pragma mark - DetailViewControllerDelegate
- (void)popNavigationController
{
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
