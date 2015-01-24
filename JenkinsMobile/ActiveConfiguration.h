//
//  ActiveConfiguration.h
//  JenkinsMobile
//
//  Created by Kyle on 1/20/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Build, Job;

@interface ActiveConfiguration : NSManagedObject

@property (nonatomic, retain) id actions;
@property (nonatomic, retain) NSString * activeConfiguration_description;
@property (nonatomic, retain) NSNumber * buildable;
@property (nonatomic, retain) NSString * color;
@property (nonatomic, retain) NSNumber * concurrentBuild;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * displayNameOrNull;
@property (nonatomic, retain) id downstreamProjects;
@property (nonatomic, retain) NSNumber * firstBuild;
@property (nonatomic, retain) id healthReport;
@property (nonatomic, retain) NSNumber * inQueue;
@property (nonatomic, retain) NSNumber * keepDependencies;
@property (nonatomic, retain) NSNumber * lastBuild;
@property (nonatomic, retain) NSNumber * lastCompletedBuild;
@property (nonatomic, retain) NSNumber * lastFailedBuild;
@property (nonatomic, retain) NSNumber * lastImportedBuild;
@property (nonatomic, retain) NSNumber * lastStableBuild;
@property (nonatomic, retain) NSNumber * lastSuccessfulBuild;
@property (nonatomic, retain) NSDate * lastSync;
@property (nonatomic, retain) NSNumber * lastUnstableBuild;
@property (nonatomic, retain) NSNumber * lastUnsuccessfulBuild;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nextBuildNumber;
@property (nonatomic, retain) id property;
@property (nonatomic, retain) id queueItem;
@property (nonatomic, retain) id scm;
@property (nonatomic, retain) NSData * testResultsImage;
@property (nonatomic, retain) id upstreamProjects;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *rel_ActiveConfiguration_Builds;
@property (nonatomic, retain) Job *rel_ActiveConfiguration_Job;
@end

@interface ActiveConfiguration (CoreDataGeneratedAccessors)

- (void)addRel_ActiveConfiguration_BuildsObject:(Build *)value;
- (void)removeRel_ActiveConfiguration_BuildsObject:(Build *)value;
- (void)addRel_ActiveConfiguration_Builds:(NSSet *)values;
- (void)removeRel_ActiveConfiguration_Builds:(NSSet *)values;

@end
