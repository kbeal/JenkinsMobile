//
//  KDBRelatedProjectsViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 5/15/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum relatedProjectsTypes
{
    DOWNSTREAM, UPSTREAM
} RelatedProjectType;

@interface KDBRelatedProjectsViewController : UIViewController

- (void)configureView;
- (void)setRelatedProjects:(NSArray *)newRelatedProjects forType:(RelatedProjectType)newRelatedProjectsType;

@property (nonatomic) RelatedProjectType relatedProjectsType;
@property (strong, nonatomic) NSArray *relatedProjects;

@end
