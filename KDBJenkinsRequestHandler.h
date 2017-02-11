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
#import "ActiveConfiguration+More.h"

@interface KDBJenkinsRequestHandler : NSObject

- (void) importDetailsForJob:(Job *) job;
- (void) importDetailsForView: (View *) view;
- (void) importChildViewsForView: (View *) view;
- (void) importDetailsForActiveConfiguration: (ActiveConfiguration *) ac;
- (void) importDetailsForBuild: (Build *) build;
- (void) importProgressForBuild:(Build *) build onJenkinsInstance:(JenkinsInstance *) jinstance;
- (void) importConsoleTextForBuild: (Build *) build onJenkinsInstance:(JenkinsInstance *) jinstance;
- (void) importDetailsForJenkinsInstance: (JenkinsInstance *) jinstance;
- (void) importViewsForJenkinsInstance: (JenkinsInstance *) jinstance;
- (void) pingJenkinsInstance: (JenkinsInstance *) jinstance;
- (void) authenticateJenkinsInstance: (JenkinsInstance *) jinstance;
- (void) kickOffBuildWithURL: (NSString *) url andUsername: (NSString *) username andPassword: (NSString *) password;

@end
