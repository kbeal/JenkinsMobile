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

extern NSString * const SelectedJobChangedNotification;
extern NSString * const JenkinsInstanceDetailResponseReceivedNotification;
extern NSString * const JenkinsInstanceDetailRequestFailedNotification;
extern NSString * const JobDetailResponseReceivedNotification;
extern NSString * const JobDetailRequestFailedNotification;
extern NSString * const ViewDetailResponseReceivedNotification;
extern NSString * const ViewDetailRequestFailedNotification;
extern NSString * const BuildDetailResponseReceivedNotification;
extern NSString * const BuildDetailRequestFailedNotification;
extern NSString * const BuildProgressResponseReceivedNotification;
extern NSString * const JobTestResultsImageResponseReceivedNotification;

// View keys
extern NSString * const ViewURLKey;
extern NSString * const ViewNameKey;
extern NSString * const ViewDescriptionKey;
extern NSString * const ViewPropertyKey;
extern NSString * const ViewJobsKey;
extern NSString * const ViewViewsKey;
extern NSString * const ViewJenkinsInstanceKey;

// Job keys
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

// Build keys
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

// Active Configuration Keys
extern NSString * const ActiveConfigurationNameKey;
extern NSString * const ActiveConfigurationColorKey;
extern NSString * const ActiveConfigurationURLKey;

// JenkinsInstance Keys
extern NSString * const JenkinsInstanceNameKey;
extern NSString * const JenkinsInstanceURLKey;
extern NSString * const JenkinsInstanceCurrentKey;
extern NSString * const JenkinsInstanceJobsKey;
extern NSString * const JenkinsInstanceEnabledKey;

// AFNetworking Keys
extern NSString * const StatusCodeKey;
extern NSString * const NSErrorFailingURLKey;
extern NSString * const RequestErrorKey;

@end