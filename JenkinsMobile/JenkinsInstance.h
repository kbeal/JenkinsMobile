//
//  JenkinsInstance.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 12/8/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Job, View;

NS_ASSUME_NONNULL_BEGIN

@interface JenkinsInstance : NSManagedObject

@property (nonatomic, copy) NSString *password;

- (void)setValues:(NSDictionary *) values;
- (void)updateValues:(NSDictionary *) values;
- (BOOL)validateInstanceWithMessage:(NSString * _Nullable * _Nullable) message;
- (BOOL)validateURL:(NSString *) newURL withMessage:(NSString * _Nullable * _Nullable) message;
- (BOOL)validateName:(NSString *) newName withMessage:(NSString * _Nullable * _Nullable) message;
- (BOOL)validateUsername:(NSString *) newUsername withMessage:(NSString * _Nullable * _Nullable) message;
- (BOOL)validatePassword:(NSString *) newPassword withMessage:(NSString * _Nullable * _Nullable) message;
- (void)correctURL;
- (void)setJobs:(NSSet *) jobsSet;
- (NSSet *)getJobs;
- (NSSet *)findJobsToCreate:(NSSet *) responseJobs;
- (NSSet *)findExistingJobs:(NSSet *) responseJobs;
- (NSSet *)findOrCreateJobs:(NSSet *)jobs inView:(View *) view;

+ (JenkinsInstance *)createJenkinsInstanceWithValues:(NSDictionary * _Nullable)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (JenkinsInstance *)fetchJenkinsInstanceWithURL: (NSString *) url fromManagedObjectContext: (NSManagedObjectContext *) context;
+ (JenkinsInstance *)findOrCreateJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSString *) removeApiFromURL:(NSURL *) url;

@end

NS_ASSUME_NONNULL_END

#import "JenkinsInstance+CoreDataProperties.h"
