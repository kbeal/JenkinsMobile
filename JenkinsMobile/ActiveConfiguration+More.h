//
//  ActiveConfiguration+More.h
//  JenkinsMobile
//
//  Created by Kyle on 1/20/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "ActiveConfiguration.h"

@interface ActiveConfiguration (More)

-(NSURL *) simplifiedURL;

+ (ActiveConfiguration *)createActiveConfigurationWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;

@end
