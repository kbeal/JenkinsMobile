//
//  JenkinsInstance.h
//  JenkinsMobile
//
//  Created by Kyle on 4/6/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Job, View;

@interface JenkinsInstance : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * current;
@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSSet *rel_Jobs;
@property (nonatomic, retain) NSSet *rel_Views;
@end

@interface JenkinsInstance (CoreDataGeneratedAccessors)

- (void)addRel_JobsObject:(Job *)value;
- (void)removeRel_JobsObject:(Job *)value;
- (void)addRel_Jobs:(NSSet *)values;
- (void)removeRel_Jobs:(NSSet *)values;

- (void)addRel_ViewsObject:(View *)value;
- (void)removeRel_ViewsObject:(View *)value;
- (void)addRel_Views:(NSSet *)values;
- (void)removeRel_Views:(NSSet *)values;

- (void)setValues:(NSDictionary *) values;

+ (JenkinsInstance *)createJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (JenkinsInstance *)getCurrentJenkinsInstanceFromManagedObjectContext:(NSManagedObjectContext *) context;
+ (JenkinsInstance *)fetchJenkinsInstanceWithURL: (NSString *) url fromManagedObjectContext: (NSManagedObjectContext *) context;
+ (JenkinsInstance *)findOrCreateJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSString *) removeApiFromURL:(NSURL *) url;

@end
