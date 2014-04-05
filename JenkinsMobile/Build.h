//
//  Build.h
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Job;

@interface Build : NSManagedObject

@property (nonatomic, retain) id actions;
@property (nonatomic, retain) id artifacts;
@property (nonatomic, retain) NSString * build_description;
@property (nonatomic, retain) NSNumber * building;
@property (nonatomic, retain) NSString * builtOn;
@property (nonatomic, retain) id changeset;
@property (nonatomic, retain) id culprits;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * estimatedDuration;
@property (nonatomic, retain) NSString * executor;
@property (nonatomic, retain) NSString * fullDisplayName;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSNumber * keepLog;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSString * result;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Job *rel_Build_Job;

@end
