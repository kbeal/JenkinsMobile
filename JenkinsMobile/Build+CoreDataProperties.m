//
//  Build+CoreDataProperties.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/31/17.
//  Copyright © 2017 Kyle Beal. All rights reserved.
//

#import "Build+CoreDataProperties.h"

@implementation Build (CoreDataProperties)

+ (NSFetchRequest<Build *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Build"];
}

@dynamic actions;
@dynamic artifacts;
@dynamic build_description;
@dynamic build_id;
@dynamic building;
@dynamic builtOn;
@dynamic changeset;
@dynamic completedTime;
@dynamic consoleText;
@dynamic culprits;
@dynamic duration;
@dynamic estimatedDuration;
@dynamic executor;
@dynamic fullDisplayName;
@dynamic keepLog;
@dynamic lastSyncResult;
@dynamic number;
@dynamic result;
@dynamic timestamp;
@dynamic url;
@dynamic rel_Build_ActiveConfiguration;
@dynamic rel_Build_Job;

@end
