//
//  JenkinsInstance+CoreDataProperties.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 12/18/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "JenkinsInstance.h"

NS_ASSUME_NONNULL_BEGIN

@interface JenkinsInstance (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *allowInvalidSSLCertificate;
@property (nullable, nonatomic, retain) NSNumber *authenticated;
@property (nullable, nonatomic, retain) NSNumber *enabled;
@property (nullable, nonatomic, retain) NSData *jobsflat;
@property (nullable, nonatomic, retain) NSString *lastSyncResult;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) id primaryView;
@property (nullable, nonatomic, retain) NSNumber *shouldAuthenticate;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSString *username;
@property (nullable, nonatomic, retain) NSSet<Job *> *rel_Jobs;
@property (nullable, nonatomic, retain) NSSet<View *> *rel_Views;

@end

@interface JenkinsInstance (CoreDataGeneratedAccessors)

- (void)addRel_JobsObject:(Job *)value;
- (void)removeRel_JobsObject:(Job *)value;
- (void)addRel_Jobs:(NSSet<Job *> *)values;
- (void)removeRel_Jobs:(NSSet<Job *> *)values;

- (void)addRel_ViewsObject:(View *)value;
- (void)removeRel_ViewsObject:(View *)value;
- (void)addRel_Views:(NSSet<View *> *)values;
- (void)removeRel_Views:(NSSet<View *> *)values;

@end

NS_ASSUME_NONNULL_END
