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
@property (strong, nonatomic) NSNumber *view_count;
@property (strong, nonatomic) NSMutableArray *viewDetails;
@property (strong, nonatomic) NSMutableDictionary *viewsJobsCounts;
@property (strong, nonatomic) NSMutableDictionary *viewsJobsDetails;
@property (strong, nonatomic) NSMutableDictionary *jobsBuildsCounts;
@property (strong, nonatomic) NSMutableDictionary *jobsBuildsDetails;

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) instance;

- (void) importAllViews;
- (void) importDetailsForView: (NSString *) viewName atURL: (NSString *) viewURL;
- (void) importDetailsForViews: (NSArray *) views;
- (void) importDetailsForJobAtURL:(NSString *)jobURL inViewAtURL:(NSString *) viewURL;
- (void) importDetailsForJobs;
- (void) importDetailsForBuild: (NSNumber *) buildNumber forJobURL: (NSString *) jobURL;
- (void) importDetailsForBuildsForJobs: (NSArray *) jobs;
- (void) persistViewsToLocalStorage: (NSArray *) views;
- (void) persistViewDetailsToLocalStorage;
- (void) persistJobDetailsToLocalStorageForView: (NSString *) viewURL;
- (void) persistBuildDetailsToLocalStorageForJobAtURL: (NSString *) jobURL;
- (void) appendViewDetailsWithValues: (NSDictionary *) viewValues;
- (void) appendJobDetailsWithValues: (NSDictionary *) jobValues forViewAtURL: (NSString *) viewURL;
- (void) appendBuildDetailsWithValues: (NSDictionary *) buildValues forJobAtURL: (NSString *) jobURL;

@end
