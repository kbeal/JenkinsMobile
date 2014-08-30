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
// Build keys
extern NSString * const BuildURLKey;
extern NSString * const BuildNumberKey;
extern NSString * const BuildBuildingKey;
extern NSString * const BuildDurationKey;
extern NSString * const BuildEstimatedDurationKey;
extern NSString * const BuildTimestampKey;

@end