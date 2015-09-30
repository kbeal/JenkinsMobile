//
//  Constants.h
//  JenkinsMobile
//
//  Created by Kyle on 8/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

extern double MaxJobSyncAge;

#pragma mark - Notifications
extern NSString * const SelectedJobChangedNotification;
extern NSString * const JenkinsInstanceDetailResponseReceivedNotification;
extern NSString * const JenkinsInstanceDetailRequestFailedNotification;
extern NSString * const JenkinsInstanceViewsResponseReceivedNotification;
extern NSString * const JenkinsInstanceViewsRequestFailedNotification;
extern NSString * const JobDetailResponseReceivedNotification;
extern NSString * const JobDetailRequestFailedNotification;
extern NSString * const ViewDetailResponseReceivedNotification;
extern NSString * const ViewDetailRequestFailedNotification;
extern NSString * const ViewChildViewsResponseReceivedNotification;
extern NSString * const ViewChildViewsRequestFailedNotification;
extern NSString * const BuildDetailResponseReceivedNotification;
extern NSString * const BuildDetailRequestFailedNotification;
extern NSString * const BuildProgressResponseReceivedNotification;
extern NSString * const ActiveConfigurationDetailResponseReceivedNotification;
extern NSString * const ActiveConfigurationDetailRequestFailedNotification;
extern NSString * const JobTestResultsImageResponseReceivedNotification;
extern NSString * const JenkinsInstancePingResponseReceivedNotification;
extern NSString * const JenkinsInstancePingRequestFailedNotification;
extern NSString * const JenkinsInstanceAuthenticationResponseReceivedNotification;
extern NSString * const JenkinsInstanceAuthenticationRequestFailedNotification;
extern NSString * const SyncManagerCurrentJenkinsInstanceChangedNotification;

#pragma mark - View keys
extern NSString * const ViewURLKey;
extern NSString * const ViewNameKey;
extern NSString * const ViewDescriptionKey;
extern NSString * const ViewPropertyKey;
extern NSString * const ViewJobsKey;
extern NSString * const ViewViewsKey;
extern NSString * const ViewJenkinsInstanceKey;
extern NSString * const ViewLastSyncResultKey;
extern NSString * const ViewParentViewKey;

#pragma mark - Job keys
extern NSString * const JobURLKey;
extern NSString * const JobActiveConfigurationsKey;
extern NSString * const JobNameKey;
extern NSString * const JobColorKey;
extern NSString * const JobTestResultsImageKey;
extern NSString * const JobBuildableKey;
extern NSString * const JobConcurrentBuildKey;
extern NSString * const JobDisplayNameKey;
extern NSString * const JobFirstBuildKey;
extern NSString * const JobLastBuildKey;
extern NSString * const JobLastCompletedBuildKey;
extern NSString * const JobLastFailedBuildKey;
extern NSString * const JobLastStableBuildKey;
extern NSString * const JobLastSuccessfulBuildKey;
extern NSString * const JobLastUnstableBuildKey;
extern NSString * const JobLastUnsucessfulBuildKey;
extern NSString * const JobNextBuildNumberKey;
extern NSString * const JobInQueueKey;
extern NSString * const JobDescriptionKey;
extern NSString * const JobKeepDependenciesKey;
extern NSString * const JobJenkinsInstanceKey;
extern NSString * const JobDownstreamProjectsKey;
extern NSString * const JobUpstreamProjectsKey;
extern NSString * const JobHealthReportKey;
extern NSString * const JobLastSyncKey;
extern NSString * const JobRequestErrorKey;
extern NSString * const JobLastSyncResultKey;

#pragma mark - ActiveConfiguration keys
extern NSString * const ActiveConfigurationURLKey;
extern NSString * const ActiveConfigurationNameKey;
extern NSString * const ActiveConfigurationColorKey;
extern NSString * const ActiveConfigurationTestResultsImageKey;
extern NSString * const ActiveConfigurationBuildableKey;
extern NSString * const ActiveConfigurationConcurrentBuildKey;
extern NSString * const ActiveConfigurationDisplayNameKey;
extern NSString * const ActiveConfigurationFirstBuildKey;
extern NSString * const ActiveConfigurationLastBuildKey;
extern NSString * const ActiveConfigurationLastCompletedBuildKey;
extern NSString * const ActiveConfigurationLastFailedBuildKey;
extern NSString * const ActiveConfigurationLastStableBuildKey;
extern NSString * const ActiveConfigurationLastSuccessfulBuildKey;
extern NSString * const ActiveConfigurationLastUnstableBuildKey;
extern NSString * const ActiveConfigurationLastUnsucessfulBuildKey;
extern NSString * const ActiveConfigurationNextBuildNumberKey;
extern NSString * const ActiveConfigurationInQueueKey;
extern NSString * const ActiveConfigurationDescriptionKey;
extern NSString * const ActiveConfigurationKeepDependenciesKey;
extern NSString * const ActiveConfigurationJobKey;
extern NSString * const ActiveConfigurationDownstreamProjectsKey;
extern NSString * const ActiveConfigurationUpstreamProjectsKey;
extern NSString * const ActiveConfigurationHealthReportKey;
extern NSString * const ActiveConfigurationLastSyncKey;
extern NSString * const ActiveConfigurationRequestErrorKey;
extern NSString * const ActiveConfigurationLastSyncResultKey;

#pragma mark - Build keys
extern NSString * const BuildURLKey;
extern NSString * const BuildNumberKey;
extern NSString * const BuildBuildingKey;
extern NSString * const BuildDurationKey;
extern NSString * const BuildEstimatedDurationKey;
extern NSString * const BuildTimestampKey;
extern NSString * const BuildJobKey;
extern NSString * const BuildActionsKey;
extern NSString * const BuildCausesKey;
extern NSString * const BuildChangeSetKey;
extern NSString * const BuildCausesShortDescriptionKey;
extern NSString * const BuildCausesUserIDKey;
extern NSString * const BuildCausesUserNameKey;
extern NSString * const BuildChangeSetItemsKey;
extern NSString * const BuildChangeSetKindKey;
extern NSString * const BuildResultKey;
extern NSString * const BuildDescriptionKey;
extern NSString * const BuildKeepLogKey;
extern NSString * const BuildIDKey;
extern NSString * const BuildFullDisplayNameKey;
extern NSString * const BuildLastSyncResultKey;

#pragma mark - JenkinsInstance Keys
extern NSString * const JenkinsInstanceNameKey;
extern NSString * const JenkinsInstanceURLKey;
extern NSString * const JenkinsInstanceJobsKey;
extern NSString * const JenkinsInstanceEnabledKey;
extern NSString * const JenkinsInstanceUsernameKey;
extern NSString * const JenkinsInstanceAuthenticatedKey;
extern NSString * const JenkinsInstanceLastSyncResultKey;
extern NSString * const JenkinsInstanceViewsKey;
extern NSString * const JenkinsInstancePrimaryViewKey;
extern NSString * const JenkinsInstanceShouldAuthenticateKey;

#pragma mark - AFNetworking Keys
extern NSString * const StatusCodeKey;
extern NSString * const NSErrorFailingURLKey;
extern NSString * const RequestErrorKey;

#pragma mark - RequestHandler Keys
extern NSString * const RequestedObjectKey;

#pragma mark - SyncManager Keys
extern NSString * const SyncManagerCurrentJenkinsInstance;

@end