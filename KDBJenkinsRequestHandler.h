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

- (void) importDetailsForJobWithURL:(NSURL *) jobURL andJenkinsInstance:(JenkinsInstance *) jinstance;
- (void) importDetailsForViewWithURL: (NSURL *) viewURL;
- (void) importDetailsForActiveConfigurationWithURL: (NSURL *) acURL andJob:(Job *) job;
- (void) importDetailsForBuildWithURL: (NSURL *) buildURL;
//- (void) importProgressForBuild:(NSNumber *) buildNumber ofJobAtURL:(NSString *) jobURL;
- (void) importDetailsForJenkinsAtURL:(NSString *) url withName:(NSString *) name;

@end
