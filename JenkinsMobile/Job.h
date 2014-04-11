//
//  Job.h
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "JenkinsInstance.h"
#import "Build.h"
#import "View.h"


@interface Job : NSManagedObject

@property (nonatomic, retain) id actions;
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
@property (nonatomic, retain) NSNumber * lastStableBuild;
@property (nonatomic, retain) NSNumber * lastSuccessfulBuild;
@property (nonatomic, retain) NSNumber * lastUnstableBuild;
@property (nonatomic, retain) NSNumber * lastUnsuccessfulBuild;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * nextBuildNumber;
@property (nonatomic, retain) id property;
@property (nonatomic, retain) NSString * queueItem;
@property (nonatomic, retain) id scm;
@property (nonatomic, retain) id upstreamProjects;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *rel_Job_Builds;
@property (nonatomic, retain) NSManagedObject *rel_Job_JenkinsInstance;
@property (nonatomic, retain) NSSet *rel_Job_View;
@end

@interface Job (CoreDataGeneratedAccessors)

- (void)addRel_Job_BuildsObject:(NSManagedObject *)value;
- (void)removeRel_Job_BuildsObject:(NSManagedObject *)value;
- (void)addRel_Job_Builds:(NSSet *)values;
- (void)removeRel_Job_Builds:(NSSet *)values;

- (void)addRel_Job_ViewObject:(NSManagedObject *)value;
- (void)removeRel_Job_ViewObject:(NSManagedObject *)value;
- (void)addRel_Job_View:(NSSet *)values;
- (void)removeRel_Job_View:(NSSet *)values;

- (void)setValues:(NSDictionary *) values byCaller:(NSString *) caller;

+ (Job *)createJobWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context forView:(View *) view byCaller:(NSString *) caller;


@end
