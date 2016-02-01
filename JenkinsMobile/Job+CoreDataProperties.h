//
//  Job+CoreDataProperties.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/2/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Job.h"

NS_ASSUME_NONNULL_BEGIN

@interface Job (CoreDataProperties)

@property (nullable, nonatomic, retain) id actions;
@property (nullable, nonatomic, retain) id activeConfigurations;
@property (nullable, nonatomic, retain) NSNumber *buildable;
@property (nullable, nonatomic, retain) NSString *color;
@property (nullable, nonatomic, retain) NSNumber *concurrentBuild;
@property (nullable, nonatomic, retain) NSString *displayName;
@property (nullable, nonatomic, retain) NSString *displayNameOrNull;
@property (nullable, nonatomic, retain) id downstreamProjects;
@property (nullable, nonatomic, retain) id firstBuild;
@property (nullable, nonatomic, retain) id healthReport;
@property (nullable, nonatomic, retain) NSNumber *inQueue;
@property (nullable, nonatomic, retain) NSString *job_description;
@property (nullable, nonatomic, retain) NSNumber *keepDependencies;
@property (nullable, nonatomic, retain) id lastBuild;
@property (nullable, nonatomic, retain) id lastCompletedBuild;
@property (nullable, nonatomic, retain) id lastFailedBuild;
@property (nullable, nonatomic, retain) id lastImportedBuild;
@property (nullable, nonatomic, retain) id lastStableBuild;
@property (nullable, nonatomic, retain) id lastSuccessfulBuild;
@property (nullable, nonatomic, retain) NSDate *lastSync;
@property (nullable, nonatomic, retain) NSString *lastSyncResult;
@property (nullable, nonatomic, retain) id lastUnstableBuild;
@property (nullable, nonatomic, retain) id lastUnsuccessfulBuild;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *nextBuildNumber;
@property (nullable, nonatomic, retain) id property;
@property (nullable, nonatomic, retain) id queueItem;
@property (nullable, nonatomic, retain) id scm;
@property (nullable, nonatomic, retain) NSData *testResultsImage;
@property (nullable, nonatomic, retain) id upstreamProjects;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) id builds;
@property (nullable, nonatomic, retain) NSSet<Build *> *rel_Job_Builds;
@property (nullable, nonatomic, retain) JenkinsInstance *rel_Job_JenkinsInstance;
@property (nullable, nonatomic, retain) NSSet<View *> *rel_Job_Views;

@end

@interface Job (CoreDataGeneratedAccessors)

- (void)addRel_Job_BuildsObject:(Build *)value;
- (void)removeRel_Job_BuildsObject:(Build *)value;
- (void)addRel_Job_Builds:(NSSet<Build *> *)values;
- (void)removeRel_Job_Builds:(NSSet<Build *> *)values;

- (void)addRel_Job_ViewsObject:(View *)value;
- (void)removeRel_Job_ViewsObject:(View *)value;
- (void)addRel_Job_Views:(NSSet<View *> *)values;
- (void)removeRel_Job_Views:(NSSet<View *> *)values;

@end

NS_ASSUME_NONNULL_END
