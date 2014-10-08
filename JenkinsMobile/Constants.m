//
//  Constants2.m
//  JenkinsMobile
//
//  Created by Kyle on 8/13/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "Constants.h"

@implementation Constants

// Notifications
NSString * const SelectedJobChangedNotification = @"SelectedJobChanged";
NSString * const JobDetailResponseReceivedNotification = @"JobDetailResponseReceived";
NSString * const BuildProgressResponseReceivedNotification = @"BuildProgressResponseReceived";
NSString * const JobTestResultsImageResponseReceivedNotification = @"JobTestResultsImageResponseReceived";

// Job Keys
NSString * const JobURLKey = @"url";
NSString * const JobActiveConfigurationsKey = @"activeConfigurations";
NSString * const JobNameKey = @"name";
NSString * const JobColorKey = @"color";
NSString * const JobTestResultsImageKey = @"jobTestResults";
NSString * const JobBuildableKey = @"buildable";
NSString * const JobConcurrentBuildKey = @"concurrentBuild";
NSString * const JobDisplayNameKey = @"displayName";
NSString * const JobFirstBuildKey = @"firstBuild";
NSString * const JobLastBuildKey = @"lastBuild";
NSString * const JobLastCompletedBuildKey = @"lastCompletedBuild";
NSString * const JobLastFailedBuildKey = @"lastFailedBuild";
NSString * const JobLastStableBuildKey = @"lastStableBuild";
NSString * const JobLastSuccessfulBuildKey = @"lastSuccessfulBuild";
NSString * const JobLastUnstableBuildKey = @"lastUnstableBuild";
NSString * const JobLastUnsucessfulBuildKey = @"lastUnsuccessfulBuild";
NSString * const JobNextBuildNumberKey = @"nextBuildNumber";
NSString * const JobInQueueKey = @"inQueue";
NSString * const JobDescriptionKey = @"description";
NSString * const JobKeepDependenciesKey = @"keepDependencies";
NSString * const JobJenkinsInstanceKey = @"jenkinsInstance";
// Build Keys
NSString * const BuildURLKey = @"url";
NSString * const BuildNumberKey = @"number";
NSString * const BuildBuildingKey = @"building";
NSString * const BuildDurationKey = @"duration";
NSString * const BuildEstimatedDurationKey = @"estimatedDuration";
NSString * const BuildTimestampKey = @"timestamp";
// Active Configuration Keys
NSString * const ActiveConfigurationNameKey = @"name";
NSString * const ActiveConfigurationColorKey = @"color";
NSString * const ActiveConfigurationURLKey = @"url";
// JenkinsInstance Keys
NSString * const JenkinsInstanceNameKey = @"name";
NSString * const JenkinsInstanceURLKey = @"url";
NSString * const JenkinsInstanceCurrentKey = @"current";

@end
