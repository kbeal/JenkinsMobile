//
//  Build.h
//  JenkinsMobile
//
//  Created by Kyle on 2/25/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ActiveConfiguration, Job;

NS_ASSUME_NONNULL_BEGIN

@interface Build : NSManagedObject

- (void)setValues:(NSDictionary * _Nonnull) values;
- (BOOL) shouldSync;
- (void)setProgressUpdateValues:(NSDictionary * _Nonnull) values;
- (void) updateConsoleText:(NSString * _Nonnull) consoleText;

+ (Build * _Nullable) createBuildWithValues:(NSDictionary * _Nonnull) values inManagedObjectContext:(NSManagedObjectContext * _Nonnull)context;
+ (Build * _Nullable) fetchBuildWithURL:(NSString * _Nonnull)url inContext:(NSManagedObjectContext * _Nonnull) context;
+ (NSArray * _Nullable)fetchBuildsWithNumbers: (NSArray * _Nonnull) numbers forJob: (Job * _Nonnull) job;
+ (NSString * _Nullable) getColorForResult:(NSString * _Nullable) result;
+ (NSString * _Nonnull) removeApiFromURL:(NSURL * _Nonnull) url;
+ (BOOL) colorIsBuilding:(NSString * _Nonnull) color;

@end

NS_ASSUME_NONNULL_END

#import "Build+CoreDataProperties.h"
