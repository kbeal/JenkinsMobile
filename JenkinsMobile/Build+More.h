//
//  Build+More.h
//  JenkinsMobile
//
//  Created by Kyle on 2/25/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "Build.h"

@interface Build (More)

- (void)setValues:(NSDictionary *) values;
- (BOOL) shouldSync;

+ (Build *) createBuildWithValues:(NSDictionary *) values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Build *) fetchBuildWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context;
+ (NSString *) removeApiFromURL:(NSURL *) url;

@end
