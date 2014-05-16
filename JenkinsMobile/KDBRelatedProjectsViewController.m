//
//  KDBRelatedProjectsViewController.m
//  JenkinsMobile
//
//  Created by Kyle on 5/15/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBRelatedProjectsViewController.h"

@interface KDBRelatedProjectsViewController ()

@end

@implementation KDBRelatedProjectsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setRelatedProjects:(NSArray *)newRelatedProjects forType:(RelatedProjectType)newRelatedProjectsType
{
    _relatedProjects = newRelatedProjects;
    _relatedProjectsType = newRelatedProjectsType;
    [self configureView];
}

- (void)configureView
{
    if (self.relatedProjectsType==UPSTREAM) {
        self.navigationItem.title = @"Upstream Projects";
    } else if (self.relatedProjectsType==DOWNSTREAM) {
        self.navigationItem.title = @"Downstream Projects";        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
