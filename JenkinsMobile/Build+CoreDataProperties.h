//
//  Build+CoreDataProperties.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/31/17.
//  Copyright © 2017 Kyle Beal. All rights reserved.
//

#import "Build.h"


NS_ASSUME_NONNULL_BEGIN

@interface Build (CoreDataProperties)

+ (NSFetchRequest<Build *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *actions;
@property (nullable, nonatomic, retain) NSObject *artifacts;
@property (nullable, nonatomic, copy) NSString *build_description;
@property (nullable, nonatomic, copy) NSString *build_id;
@property (nullable, nonatomic, copy) NSNumber *building;
@property (nullable, nonatomic, copy) NSString *builtOn;
@property (nullable, nonatomic, retain) NSObject *changeset;
@property (nullable, nonatomic, copy) NSDate *completedTime;
@property (nullable, nonatomic, copy) NSString *consoleText;
@property (nullable, nonatomic, retain) NSObject *culprits;
@property (nullable, nonatomic, copy) NSNumber *duration;
@property (nullable, nonatomic, copy) NSNumber *estimatedDuration;
@property (nullable, nonatomic, retain) NSObject *executor;
@property (nullable, nonatomic, copy) NSString *fullDisplayName;
@property (nullable, nonatomic, copy) NSNumber *keepLog;
@property (nullable, nonatomic, copy) NSString *lastSyncResult;
@property (nullable, nonatomic, copy) NSNumber *number;
@property (nullable, nonatomic, copy) NSString *result;
@property (nullable, nonatomic, copy) NSDate *timestamp;
@property (nullable, nonatomic, copy) NSString *url;
@property (nullable, nonatomic, retain) ActiveConfiguration *rel_Build_ActiveConfiguration;
@property (nullable, nonatomic, retain) Job *rel_Build_Job;

@end

NS_ASSUME_NONNULL_END
