//
//  Constants.h
//  JenkinsMobile
//
//  Created by Kyle on 8/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

extern NSString * const SelectedJobChangedNotification;
extern NSString * const JobDetailResponseReceivedNotification;
extern NSString * const BuildProgressResponseReceivedNotification;
extern NSString * const JobTestResultsImageResponseReceivedNotification;

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

// Build keys
extern NSString * const BuildURLKey;
extern NSString * const BuildNumberKey;
extern NSString * const BuildBuildingKey;
extern NSString * const BuildDurationKey;
extern NSString * const BuildEstimatedDurationKey;
extern NSString * const BuildTimestampKey;

// Active Configuration Keys
extern NSString * const ActiveConfigurationNameKey;
extern NSString * const ActiveConfigurationColorKey;
extern NSString * const ActiveConfigurationURLKey;

// JenkinsInstance Keys
extern NSString * const JenkinsInstanceNameKey;
extern NSString * const JenkinsInstanceURLKey;
extern NSString * const JenkinsInstanceCurrentKey;


@end