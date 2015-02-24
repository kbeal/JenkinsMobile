//
//  Job.h
//  JenkinsMobile
//
//  Created by Kyle on 2/24/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Build, JenkinsInstance, View;

@interface Job : NSManagedObject

@property (nonatomic, retain) id actions;
@property (nonatomic, retain) id activeConfigurations;
@property (nonatomic, retain) NSNumber * buildable;
@property (nonatomic, retain) NSString * color;
@property (nonatomic, retain) NSNumber * concurrentBuild;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * displayNameOrNull;
@property (nonatomic, retain) id downstreamProjects;
@property (nonatomic, retain) NSNumber * firstBuild;
@property (nonatomic, retain) id healthReport;
@property (nonatomic, retain) NSNumber * inQueue;
@property (nonatomic, retain) NSString * job_description;
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
@property (nonatomic, retain) NSString * lastSyncResult;
@property (nonatomic, retain) NSSet *rel_Job_Builds;
@property (nonatomic, retain) JenkinsInstance *rel_Job_JenkinsInstance;
@property (nonatomic, retain) NSSet *rel_Job_Views;
@end

@interface Job (CoreDataGeneratedAccessors)

- (void)addRel_Job_BuildsObject:(Build *)value;
- (void)removeRel_Job_BuildsObject:(Build *)value;
- (void)addRel_Job_Builds:(NSSet *)values;
- (void)removeRel_Job_Builds:(NSSet *)values;

- (void)addRel_Job_ViewsObject:(View *)value;
- (void)removeRel_Job_ViewsObject:(View *)value;
- (void)addRel_Job_Views:(NSSet *)values;
- (void)removeRel_Job_Views:(NSSet *)values;

@end
