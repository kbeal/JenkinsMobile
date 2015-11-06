//
//  View+More.h
//  JenkinsMobile
//
//  Created by Kyle on 2/25/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "View.h"

@interface View (More)

- (void)setValues:(NSDictionary *) values;
- (void)updateValues:(NSDictionary *) values;
- (NSArray *)splitJobsArrayIntoBatches:(NSArray *) jobs;
- (NSArray *) fetchRelatedJobsWithNames:(NSArray *) names;
- (NSArray *) findJobsToRelateFromBatch: (NSArray *) jobBatch;
- (void) insertJobBatch:(NSArray *) jobBatch;

+ (View *)createViewWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (View *)fetchViewWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context;
+ (NSString *) removeApiFromURL:(NSURL *) url;

@end
