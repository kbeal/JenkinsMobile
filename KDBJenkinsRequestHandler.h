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
#import "Build.h"
#import "JenkinsInstance.h"

@interface KDBJenkinsRequestHandler : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) JenkinsInstance *jinstance;
@property (nonatomic) int view_count;
@property (strong, nonatomic) NSMutableArray *viewDetails;

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) instance;

- (void) importAllViews;
- (void) importDetailsForView: (NSString *) viewName atURL: (NSString *) viewURL;
- (void) importDetailsForViews: (NSArray *) views;
- (void) importDetailsForJob:(NSString *)jobURL inView:(View *) view;
- (void) importDetailsForBuild: (int) buildNumber forJob: (Job *) job;
- (void) persistViewsToLocalStorage: (NSArray *) views;
- (void) persistViewDetailsToLocalStorage;
- (void) persistJobToLocalStorage: (NSDictionary *) jobvals inView: (View *) view;
- (void) persistBuildToLocalStorage: (NSDictionary *) buildvals forJob: (Job *) job;
- (void) appendViewDetailsWithValues: (NSDictionary *) viewValues;

@end
