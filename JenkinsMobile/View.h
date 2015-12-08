//
//  View.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 12/8/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class JenkinsInstance, Job;

NS_ASSUME_NONNULL_BEGIN

@interface View : NSManagedObject

- (void)setValues:(NSDictionary *) values;
- (void)updateValues:(NSDictionary *) values;
- (NSSet *)findJobsInResponseToRelate:(NSSet *) responseJobs;

+ (View *)createViewWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (View *)fetchViewWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context;
+ (NSString *) removeApiFromURL:(NSURL *) url;

@end

NS_ASSUME_NONNULL_END

#import "View+CoreDataProperties.h"
