//
//  Build+CoreDataProperties.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 2/11/17.
//  Copyright © 2017 Kyle Beal. All rights reserved.
//  This file was automatically generated and should not be edited.
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
@dynamic consoleText;
@dynamic rel_Build_ActiveConfiguration;
@dynamic rel_Build_Job;

@end
