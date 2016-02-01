//
//  Job.h
//  JenkinsMobile
//
//  Created by Kyle on 2/24/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Build, JenkinsInstance, View;

NS_ASSUME_NONNULL_BEGIN

@interface Job : NSManagedObject

- (BOOL)colorIsAnimated;
- (void)setValues:(NSDictionary *) values;
- (NSArray *) getActiveConfigurations;
- (void) setTestResultsImageWithImage:(UIImage *) image;
- (UIImage *) getTestResultsImage;
- (BOOL)shouldSync;
- (NSSet *)findBuildsInResponseToRelate:(NSSet *) responseJobs;
- (NSArray *)fetchLatestBuilds:(int) numberOfBuilds;

+ (Job *)createJobWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Job *)fetchJobWithName: (NSString *) name inManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) jinstance;
+ (NSArray *)fetchJobsWithNames: (NSArray *) names inManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) jinstance;
+ (NSString *)jobNameFromURL: (NSURL *) jobURL;
+ (NSString *) getNormalizedColor: (NSString *) responseColor;

@end

NS_ASSUME_NONNULL_END

#import "Job+CoreDataProperties.h"