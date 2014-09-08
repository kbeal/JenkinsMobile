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

// Job keys
extern NSString * const JobURLKey;
extern NSString * const JobActiveConfigurationsKey;
extern NSString * const JobNameKey;
extern NSString * const JobColorKey;
extern NSString * const JobTestResultsImageKey;
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


@end