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

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) instance;

- (void) importAllViews;
- (void) importDetailsForView: (NSString *) viewURL;
- (void) importDetailsForJob: (NSString *) jobURL;
- (void) importDetailsForBuild: (NSString *) buildURL forJob: (Job *) job;
- (void) persistViewsToLocalStorage: (NSArray *) views;
- (void) persistViewToLocalStorage: (NSDictionary *) viewvals;
- (void) persistJobToLocalStorage: (NSDictionary *) job;
- (void) persistBuildToLocalStorage: (NSDictionary *) buildvals forJob: (Job *) job;

@end
