//
//  View+CoreDataProperties.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 12/8/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "View.h"

NS_ASSUME_NONNULL_BEGIN

@interface View (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *lastSyncResult;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) id property;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSString *view_description;
@property (nullable, nonatomic, retain) id jobs;
@property (nullable, nonatomic, retain) View *rel_ParentView;
@property (nullable, nonatomic, retain) JenkinsInstance *rel_View_JenkinsInstance;
@property (nullable, nonatomic, retain) NSSet<Job *> *rel_View_Jobs;
@property (nullable, nonatomic, retain) NSSet<View *> *rel_View_Views;

@end

@interface View (CoreDataGeneratedAccessors)

- (void)addRel_View_JobsObject:(Job *)value;
- (void)removeRel_View_JobsObject:(Job *)value;
- (void)addRel_View_Jobs:(NSSet<Job *> *)values;
- (void)removeRel_View_Jobs:(NSSet<Job *> *)values;

- (void)addRel_View_ViewsObject:(View *)value;
- (void)removeRel_View_ViewsObject:(View *)value;
- (void)addRel_View_Views:(NSSet<View *> *)values;
- (void)removeRel_View_Views:(NSSet<View *> *)values;

@end

NS_ASSUME_NONNULL_END
