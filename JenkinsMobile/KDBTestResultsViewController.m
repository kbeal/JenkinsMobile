//
//  KDBTestResultsViewController.m
//  JenkinsMobile
//
//  Created by Kyle on 5/14/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBTestResultsViewController.h"

@interface KDBTestResultsViewController ()

@end

@implementation KDBTestResultsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
        self.navigationItem.title = [NSString stringWithFormat:@"%@%@",[self.build.number stringValue],@" Test Results"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
