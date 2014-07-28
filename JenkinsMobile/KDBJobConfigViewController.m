//
//  KDBJobConfigViewController.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 7/23/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJobConfigViewController.h"
#import "Constants.h"

@interface KDBJobConfigViewController ()

@end

@implementation KDBJobConfigViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)willAppear
{
    [self.navigationController setNavigationBarHidden:NO];
    return [super viewWillAppear:willAppear];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.jobViewSwitcher setSelectedSegmentIndex:JobConfigIndex];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)jobViewSwitcherUnwind:(UIStoryboardSegue *)segue {}

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
