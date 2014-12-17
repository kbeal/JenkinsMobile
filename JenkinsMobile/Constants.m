//
//  Constants2.m
//  JenkinsMobile
//
//  Created by Kyle on 8/13/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "Constants.h"

@implementation Constants

double MaxJobSyncAge = 300; // 5 minutes in seconds

// Notifications
NSString * const SelectedJobChangedNotification = @"SelectedJobChanged";
NSString * const JobDetailResponseReceivedNotification = @"JobDetailResponseReceived";
NSString * const JobDetailRequestFailedNotification = @"JobDetailRequestFailed";
NSString * const BuildProgressResponseReceivedNotification = @"BuildProgressResponseReceived";
NSString * const JobTestResultsImageResponseReceivedNotification = @"JobTestResultsImageResponseReceived";
NSString * const JenkinsInstanceDetailResponseReceivedNotification = @"JenkinsInstanceDetailResponseReceived";
NSString * const JenkinsInstanceDetailRequestFailedNotification = @"JenkinsInstanceDetailRequestFailed";

// View Keys
NSString * const ViewURLKey = @"url";
NSString * const ViewNameKey = @"name";
NSString * const ViewDescriptionKey = @"description";
NSString * const ViewPropertyKey = @"property";
NSString * const ViewJobsKey = @"jobs";
NSString * const ViewViewsKey = @"views";
NSString * const ViewJenkinsInstanceKey = @"jenkinsInstance";

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
NSString * const JobDownstreamProjectsKey = @"downstreamProjects";
NSString * const JobUpstreamProjectsKey = @"upstreamProjects";
NSString * const JobHealthReportKey = @"healthReport";
NSString * const JobLastSyncKey = @"lastSync";
NSString * const JobRequestErrorKey = @"jobRequestError";
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
NSString * const JenkinsInstanceJobsKey = @"jobs";
// AFNetworking Keys
NSString * const StatusCodeKey = @"statusCode";
NSString * const NSErrorFailingURLKey = @"NSErrorFailingURLKey";

@end
