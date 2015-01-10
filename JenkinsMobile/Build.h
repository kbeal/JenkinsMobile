//
//  Build.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 4/25/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "JenkinsInstance.h"
#import "Constants.h"

@class Job;

@interface Build : NSManagedObject

@property (nonatomic, retain) id actions;
@property (nonatomic, retain) id artifacts;
@property (nonatomic, retain) NSString * build_description;
@property (nonatomic, retain) NSString * build_id;
@property (nonatomic, retain) NSNumber * building;
@property (nonatomic, retain) NSString * builtOn;
@property (nonatomic, retain) id changeset;
@property (nonatomic, retain) id culprits;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * estimatedDuration;
@property (nonatomic, retain) id executor;
@property (nonatomic, retain) NSString * fullDisplayName;
@property (nonatomic, retain) NSNumber * keepLog;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSString * result;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Job *rel_Build_Job;

- (void)setValues:(NSDictionary *) values;

+ (Build *) createBuildWithValues:(NSDictionary *) values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Build *) fetchBuildWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context;

- (BOOL) shouldSync;

@end
