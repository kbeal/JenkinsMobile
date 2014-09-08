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
NSString * const JobURLKey = @"jobURL";
NSString * const JobActiveConfigurationsKey = @"activeConfigurations";
NSString * const JobNameKey = @"jobName";
NSString * const JobColorKey = @"color";
NSString * const JobTestResultsImageKey = @"jobTestResults";
// Build Keys
NSString * const BuildURLKey = @"buildURL";
NSString * const BuildNumberKey = @"number";
NSString * const BuildBuildingKey = @"building";
NSString * const BuildDurationKey = @"duration";
NSString * const BuildEstimatedDurationKey = @"estimatedDuration";
NSString * const BuildTimestampKey = @"timestamp";
// Active Configuration Keys
NSString * const ActiveConfigurationNameKey = @"name";
NSString * const ActiveConfigurationColorKey = @"color";
NSString * const ActiveConfigurationURLKey = @"url";

@end
