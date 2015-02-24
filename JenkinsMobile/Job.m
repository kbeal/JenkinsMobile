//
//  Job.m
//  JenkinsMobile
//
//  Created by Kyle on 2/24/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "Job.h"
#import "Build.h"
#import "JenkinsInstance.h"
#import "View.h"


@implementation Job

@dynamic actions;
@dynamic activeConfigurations;
@dynamic buildable;
@dynamic color;
@dynamic concurrentBuild;
@dynamic displayName;
@dynamic displayNameOrNull;
@dynamic downstreamProjects;
@dynamic firstBuild;
@dynamic healthReport;
@dynamic inQueue;
@dynamic job_description;
@dynamic keepDependencies;
@dynamic lastBuild;
@dynamic lastCompletedBuild;
@dynamic lastFailedBuild;
@dynamic lastImportedBuild;
@dynamic lastStableBuild;
@dynamic lastSuccessfulBuild;
@dynamic lastSync;
@dynamic lastUnstableBuild;
@dynamic lastUnsuccessfulBuild;
@dynamic name;
@dynamic nextBuildNumber;
@dynamic property;
@dynamic queueItem;
@dynamic scm;
@dynamic testResultsImage;
@dynamic upstreamProjects;
@dynamic url;
@dynamic lastSyncResult;
@dynamic rel_Job_Builds;
@dynamic rel_Job_JenkinsInstance;
@dynamic rel_Job_Views;

@end
