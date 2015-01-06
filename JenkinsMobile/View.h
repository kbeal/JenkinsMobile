//
//  View.h
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "JenkinsInstance.h"

@class Job;

@interface View : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id property;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * view_description;
@property (nonatomic, retain) NSManagedObject *rel_View_JenkinsInstance;
@property (nonatomic, retain) NSSet *rel_View_Jobs;
@property (nonatomic, retain) NSSet *rel_View_Views;
@end

@interface View (CoreDataGeneratedAccessors)

- (void)addRel_View_JobsObject:(Job *)value;
- (void)removeRel_View_JobsObject:(Job *)value;
- (void)addRel_View_Jobs:(NSSet *)values;
- (void)removeRel_View_Jobs:(NSSet *)values;

- (void)addRel_View_ViewsObject:(View *)value;
- (void)removeRel_View_ViewsObject:(View *)value;
- (void)addRel_View_Views:(NSSet *)values;
- (void)removeRel_View_Views:(NSSet *)values;

- (void)setValues:(NSDictionary *) values;

+ (View *)createViewWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (View *)fetchViewWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context;
+ (void)fetchAndDeleteViewWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context;

@end
