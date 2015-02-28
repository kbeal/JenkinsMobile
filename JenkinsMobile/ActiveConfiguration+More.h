//
//  ActiveConfiguration+More.h
//  JenkinsMobile
//
//  Created by Kyle on 1/20/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "ActiveConfiguration.h"

@class Job;

@interface ActiveConfiguration (More)

-(NSURL *) simplifiedURL;
-(void)setValues:(NSDictionary *) values;

+ (ActiveConfiguration *)createActiveConfigurationWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (ActiveConfiguration *)fetchActiveConfigurationWithURL: (NSString *) url inManagedObjectContext: (NSManagedObjectContext *) context;
+ (void)fetchAndDeleteActiveConfigurationWithURL: (NSString *) url inManagedObjectContext: (NSManagedObjectContext *) context;
+ (NSString *) removeApiFromURL:(NSURL *) url;

@end
