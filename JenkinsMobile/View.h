//
//  View.h
//  JenkinsMobile
//
//  Created by Kyle on 5/31/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class JenkinsInstance, Job, View;

@interface View : NSManagedObject

@property (nonatomic, retain) NSString * lastSyncResult;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id property;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * view_description;
@property (nonatomic, retain) JenkinsInstance *rel_View_JenkinsInstance;
@property (nonatomic, retain) NSSet *rel_View_Jobs;
@property (nonatomic, retain) NSSet *rel_View_Views;
@property (nonatomic, retain) View *rel_ParentView;
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

@end
