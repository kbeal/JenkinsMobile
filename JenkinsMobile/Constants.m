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

#pragma mark - Notifications
NSString * const SelectedJobChangedNotification = @"SelectedJobChanged";
NSString * const JobDetailResponseReceivedNotification = @"JobDetailResponseReceived";
NSString * const JobDetailRequestFailedNotification = @"JobDetailRequestFailed";
NSString * const ViewDetailResponseReceivedNotification = @"ViewDetailResponseReceived";
NSString * const ViewDetailRequestFailedNotification = @"ViewDetailRequestFailed";
NSString * const BuildProgressResponseReceivedNotification = @"BuildProgressResponseReceived";
NSString * const JobTestResultsImageResponseReceivedNotification = @"JobTestResultsImageResponseReceived";
NSString * const JenkinsInstanceDetailResponseReceivedNotification = @"JenkinsInstanceDetailResponseReceived";
NSString * const JenkinsInstanceDetailRequestFailedNotification = @"JenkinsInstanceDetailRequestFailed";
NSString * const BuildDetailResponseReceivedNotification = @"BuildDetailResponseReceived";
NSString * const BuildDetailRequestFailedNotification = @"BuildDetailRequestFailed";
NSString * const ActiveConfigurationDetailResponseReceivedNotification = @"ActiveConfigurationDetailResponseReceived";
NSString * const ActiveConfigurationDetailRequestFailedNotification = @"ActiveConfigurationDetailRequestFailed";

#pragma mark - View Keys
NSString * const ViewURLKey = @"url";
NSString * const ViewNameKey = @"name";
NSString * const ViewDescriptionKey = @"description";
NSString * const ViewPropertyKey = @"property";
NSString * const ViewJobsKey = @"jobs";
NSString * const ViewViewsKey = @"views";
NSString * const ViewJenkinsInstanceKey = @"jenkinsInstance";
NSString * const ViewLastSyncResultKey = @"lastSyncResult";

#pragma mark - Job Keys
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
NSString * const JobLastSyncResultKey = @"lastSyncResult";

#pragma mark - Active Configuration Keys
NSString * const ActiveConfigurationURLKey = @"url";
NSString * const ActiveConfigurationJobKey = @"job";
NSString * const ActiveConfigurationNameKey = @"name";
NSString * const ActiveConfigurationColorKey = @"color";
NSString * const ActiveConfigurationTestResultsImageKey = @"ActiveConfigurationTestResults";
NSString * const ActiveConfigurationBuildableKey = @"buildable";
NSString * const ActiveConfigurationConcurrentBuildKey = @"concurrentBuild";
NSString * const ActiveConfigurationDisplayNameKey = @"displayName";
NSString * const ActiveConfigurationFirstBuildKey = @"firstBuild";
NSString * const ActiveConfigurationLastBuildKey = @"lastBuild";
NSString * const ActiveConfigurationLastCompletedBuildKey = @"lastCompletedBuild";
NSString * const ActiveConfigurationLastFailedBuildKey = @"lastFailedBuild";
NSString * const ActiveConfigurationLastStableBuildKey = @"lastStableBuild";
NSString * const ActiveConfigurationLastSuccessfulBuildKey = @"lastSuccessfulBuild";
NSString * const ActiveConfigurationLastUnstableBuildKey = @"lastUnstableBuild";
NSString * const ActiveConfigurationLastUnsucessfulBuildKey = @"lastUnsuccessfulBuild";
NSString * const ActiveConfigurationNextBuildNumberKey = @"nextBuildNumber";
NSString * const ActiveConfigurationInQueueKey = @"inQueue";
NSString * const ActiveConfigurationDescriptionKey = @"description";
NSString * const ActiveConfigurationKeepDependenciesKey = @"keepDependencies";
NSString * const ActiveConfigurationJenkinsInstanceKey = @"jenkinsInstance";
NSString * const ActiveConfigurationDownstreamProjectsKey = @"downstreamProjects";
NSString * const ActiveConfigurationUpstreamProjectsKey = @"upstreamProjects";
NSString * const ActiveConfigurationHealthReportKey = @"healthReport";
NSString * const ActiveConfigurationLastSyncKey = @"lastSync";
NSString * const ActiveConfigurationRequestErrorKey = @"ActiveConfigurationRequestError";
NSString * const ActiveConfigurationLastSyncResultKey = @"lastSyncResult";

#pragma mark - Build Keys
NSString * const BuildURLKey = @"url";
NSString * const BuildNumberKey = @"number";
NSString * const BuildBuildingKey = @"building";
NSString * const BuildDurationKey = @"duration";
NSString * const BuildEstimatedDurationKey = @"estimatedDuration";
NSString * const BuildTimestampKey = @"timestamp";
NSString * const BuildJobKey = @"job";
NSString * const BuildCausesShortDescriptionKey = @"shortDescription";
NSString * const BuildCausesUserIDKey = @"userId";
NSString * const BuildCausesUserNameKey = @"userName";
NSString * const BuildChangeSetItemsKey = @"items";
NSString * const BuildChangeSetKindKey = @"kind";
NSString * const BuildActionsKey = @"actions";
NSString * const BuildCausesKey = @"causes";
NSString * const BuildChangeSetKey = @"changeSet";
NSString * const BuildResultKey = @"result";
NSString * const BuildDescriptionKey = @"description";
NSString * const BuildKeepLogKey = @"keepLog";
NSString * const BuildIDKey = @"id";
NSString * const BuildFullDisplayNameKey = @"fullDisplayName";
NSString * const BuildLastSyncResultKey = @"lastSyncResult";

#pragma mark - JenkinsInstance Keys
NSString * const JenkinsInstanceNameKey = @"name";
NSString * const JenkinsInstanceURLKey = @"url";
NSString * const JenkinsInstanceCurrentKey = @"current";
NSString * const JenkinsInstanceJobsKey = @"jobs";
NSString * const JenkinsInstanceEnabledKey = @"enabled";
NSString * const JenkinsInstanceUsernameKey = @"username";
NSString * const JenkinsInstanceAuthenticatedKey = @"authenticated";
NSString * const JenkinsInstanceLastSyncResultKey = @"lastSyncResult";
NSString * const JenkinsInstancePrimaryViewKey = @"primaryView";

#pragma mark - AFNetworking Keys
NSString * const StatusCodeKey = @"statusCode";
NSString * const NSErrorFailingURLKey = @"NSErrorFailingURLKey";
NSString * const RequestErrorKey = @"requestError";

@end
