//
//  KDBJenkinsRequestHandler.h
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "View.h"
#import "Job.h"

@interface KDBJenkinsRequestHandler : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context;
- (void) importAllViews;
- (void) importDetailsForView: (View *) view;
- (void) importDetailsForJob: (Job *) job;
- (NSSet *) createJobsFromArray: (NSArray *) jobsArray forJenkinsInstance: (JenkinsInstance *) jinstance;
- (View *) createViewWithValues: (NSDictionary *) values;
- (void) persistViewsToLocalStorage: (NSArray *) views;
- (void) persistJobsToLocalStorage: (NSArray *) jobs forJenkinsInstance: (JenkinsInstance *) jinstance;

@end
