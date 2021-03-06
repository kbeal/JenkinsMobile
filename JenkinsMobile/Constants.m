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
NSString * const ViewChildViewsResponseReceivedNotification = @"ViewChildViewsResponseReceived";
NSString * const ViewChildViewsRequestFailedNotification = @"ViewChildViewsRequestFailed";
NSString * const BuildProgressResponseReceivedNotification = @"BuildProgressResponseReceived";
NSString * const BuildProgressRequestFailedNotification = @"BuildProgressRequestFailed";
NSString * const BuildConsoleTextResponseReceivedNotification = @"BuldConsoleTextResponseReceived";
NSString * const BuildConsoleTextRequestFailedNotification = @"BuildConsoleTextRequestFailed";
NSString * const JobTestResultsImageResponseReceivedNotification = @"JobTestResultsImageResponseReceived";
NSString * const JenkinsInstanceDetailResponseReceivedNotification = @"JenkinsInstanceDetailResponseReceived";
NSString * const NewLargeJenkinsInstanceDetailResponseReceivedNotification = @"NewLargeJenkinsInstanceDetailResponseReceived";
NSString * const JenkinsInstanceDetailRequestFailedNotification = @"JenkinsInstanceDetailRequestFailed";
NSString * const JenkinsInstanceViewsResponseReceivedNotification = @"JenkinsInstanceViewsResponseReceived";
NSString * const JenkinsInstanceViewsRequestFailedNotification = @"JenkinsInstanceViewsRequestFailed";
NSString * const JenkinsInstancePingResponseReceivedNotification = @"JenkinsInstancePingResponseReceived";
NSString * const JenkinsInstancePingRequestFailedNotification = @"JenkinsInstancePingRequestFailed";
NSString * const JenkinsInstanceDidSaveNotification = @"JenkinsInstanceDidSave";
NSString * const JenkinsInstanceAuthenticationResponseReceivedNotification = @"JenkinsInstanceAuthenticationResponseReceived";
NSString * const JenkinsInstanceAuthenticationRequestFailedNotification = @"JenkinsInstanceAuthenticationRequestFailed";
NSString * const BuildDetailResponseReceivedNotification = @"BuildDetailResponseReceived";
NSString * const BuildDetailRequestFailedNotification = @"BuildDetailRequestFailed";
NSString * const ActiveConfigurationDetailResponseReceivedNotification = @"ActiveConfigurationDetailResponseReceived";
NSString * const ActiveConfigurationDetailRequestFailedNotification = @"ActiveConfigurationDetailRequestFailed";
NSString * const SyncManagerCurrentJenkinsInstanceChangedNotification = @"SyncManagerCurrentJenkinsChanged";

#pragma mark - View Keys
NSString * const ViewURLKey = @"url";
NSString * const ViewNameKey = @"name";
NSString * const ViewDescriptionKey = @"description";
NSString * const ViewPropertyKey = @"property";
NSString * const ViewJobsKey = @"jobs";
NSString * const ViewViewsKey = @"views";
NSString * const ViewJenkinsInstanceKey = @"jenkinsInstance";
NSString * const ViewLastSyncResultKey = @"lastSyncResult";
NSString * const ViewParentViewKey = @"parentView";

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
NSString * const JobHealthReportIconKey = @"iconUrl";
NSString * const JobHealthReportIconClassNameKey = @"iconClassName";
NSString * const JobPermalinkNameKey = @"permalinkName";
NSString * const JobPermalinkKey = @"permalink";
NSString * const JobBuildsKey = @"builds";

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
NSString * const BuildExecutorProgressKey = @"progress";
NSString * const BuildConsoleTextKey = @"consoleText";

#pragma mark - JenkinsInstance Keys
NSString * const JenkinsInstanceNameKey = @"name";
NSString * const JenkinsInstanceURLKey = @"url";
NSString * const JenkinsInstanceJobsKey = @"jobs";
NSString * const JenkinsInstanceEnabledKey = @"enabled";
NSString * const JenkinsInstanceUsernameKey = @"username";
NSString * const JenkinsInstanceAuthenticatedKey = @"authenticated";
NSString * const JenkinsInstanceLastSyncResultKey = @"lastSyncResult";
NSString * const JenkinsInstanceViewsKey = @"views";
NSString * const JenkinsInstancePrimaryViewKey = @"primaryView";
NSString * const JenkinsInstanceShouldAuthenticateKey = @"shouldAuthenticate";

#pragma mark - AFNetworking Keys
NSString * const StatusCodeKey = @"statusCode";
NSString * const NSErrorFailingURLKey = @"NSErrorFailingURLKey";
NSString * const RequestErrorKey = @"requestError";

#pragma mark - RequestHandler Keys
NSString * const RequestedObjectKey = @"requestedObject";

#pragma mark - SyncManager Keys
NSString * const SyncManagerCurrentJenkinsInstance = @"currentJenkinsInstance";

#pragma makr - JobDictionaryKeys
NSString * const JobDictionaryDictionaryKey = @"dictionary";

#pragma mark - BuildDictionary Keys
NSString * const BuildDictionaryDictionaryKey = @"dictionary";

#pragma mark - ViewController Keys
double const StatusBallAnimationDuration = 1.5;

@end
