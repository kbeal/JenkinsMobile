//
//  ActiveConfiguration.m
//  JenkinsMobile
//
//  Created by Kyle on 1/20/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "ActiveConfiguration.h"
#import "Build.h"
#import "Job.h"


@implementation ActiveConfiguration

@dynamic actions;
@dynamic activeConfiguration_description;
@dynamic buildable;
@dynamic color;
@dynamic concurrentBuild;
@dynamic displayName;
@dynamic displayNameOrNull;
@dynamic downstreamProjects;
@dynamic firstBuild;
@dynamic healthReport;
@dynamic inQueue;
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
@dynamic rel_ActiveConfiguration_Builds;
@dynamic rel_ActiveConfiguration_Job;

@end
