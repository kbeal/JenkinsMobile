//
//  Job+More.h
//  JenkinsMobile
//
//  Created by Kyle on 2/24/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "Job.h"
#import "JenkinsInstance+More.h"

@interface Job (More)

- (BOOL)colorIsAnimated;
- (NSString *)absoluteColor;
- (void)setValues:(NSDictionary *) values;
- (NSArray *) getActiveConfigurations;
- (void) setTestResultsImageWithImage:(UIImage *) image;
- (UIImage *) getTestResultsImage;
- (BOOL)shouldSync;

+ (Job *)createJobWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Job *)fetchJobWithName: (NSString *) name inManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) jinstance;
+ (NSArray *)fetchJobsWithNames: (NSArray *) names inManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) jinstance;
+ (NSString *)jobNameFromURL: (NSURL *) jobURL;
+ (NSSet *) removeJobs: (NSArray *) jobNames fromBatch: (NSSet *)batchSet;

@end
