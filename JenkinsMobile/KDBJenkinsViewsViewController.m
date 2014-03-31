//
//  KDBJenkinsViewsViewController.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/30/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJenkinsViewsViewController.h"

@interface KDBJenkinsViewsViewController ()

@end

@implementation KDBJenkinsViewsViewController

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
    NSArray *colors = [NSArray arrayWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor blueColor], nil];
    for (int i = 0; i < colors.count; i++) {
        CGRect frame;
        frame.origin.x = self->jenkinsViewsScrollView.frame.size.width * i;
        frame.origin.y = 0;
        frame.size = self->jenkinsViewsScrollView.frame.size;

        UIView *subview = [[UIView alloc] initWithFrame:frame];
        subview.backgroundColor = [colors objectAtIndex:i];
        [self->jenkinsViewsScrollView addSubview:subview];
    }

    self->jenkinsViewsScrollView.contentSize = CGSizeMake(self->jenkinsViewsScrollView.frame.size.width * colors.count, self->jenkinsViewsScrollView.frame.size.height);
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
