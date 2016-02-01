//
//  Job+CoreDataProperties.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/2/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Job+CoreDataProperties.h"

@implementation Job (CoreDataProperties)

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
@dynamic lastSyncResult;
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
@dynamic builds;
@dynamic rel_Job_Builds;
@dynamic rel_Job_JenkinsInstance;
@dynamic rel_Job_Views;

@end
