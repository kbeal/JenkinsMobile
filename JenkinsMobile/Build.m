//
//  Build.m
//  JenkinsMobile
//
//  Created by Kyle on 4/7/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "Build.h"
#import "Job.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation Build

@dynamic actions;
@dynamic artifacts;
@dynamic build_description;
@dynamic building;
@dynamic builtOn;
@dynamic changeset;
@dynamic culprits;
@dynamic duration;
@dynamic estimatedDuration;
@dynamic executor;
@dynamic fullDisplayName;
@dynamic build_id;
@dynamic keepLog;
@dynamic number;
@dynamic result;
@dynamic timestamp;
@dynamic url;
@dynamic rel_Build_Job;

+ (Build *) createBuildWithValues:(NSDictionary *) values inManagedObjectContext:(NSManagedObjectContext *)context forJob: (Job *) job;
{
    Build *build = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = [NSEntityDescription entityForName:@"Build" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@", [values objectForKey:@"url"]];
    NSError *executeFetchError = nil;
    build = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up build with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [values objectForKey:@"url"], [executeFetchError localizedDescription]);
    } else if (!build) {
        build = [NSEntityDescription insertNewObjectForEntityForName:@"Build"
                                             inManagedObjectContext:context];
    }
    
    build.rel_Build_Job = job;
    
    [build setValues:values];
    
    return build;
}

- (void)setValues:(NSDictionary *) values
{
    self.actions = NULL_TO_NIL([values objectForKey:@"actions"]);
    self.artifacts = NULL_TO_NIL([values objectForKey:@"artifacts"]);
    self.build_description = NULL_TO_NIL([values objectForKey:@"description"]);
    self.building = NULL_TO_NIL([values objectForKey:@"building"]);
    self.builtOn = NULL_TO_NIL([values objectForKey:@"builtOn"]);
    self.changeset = NULL_TO_NIL([values objectForKey:@"changeset"]);
    self.culprits = NULL_TO_NIL([values objectForKey:@"culprits"]);
    self.duration = NULL_TO_NIL([values objectForKey:@"duration"]);
    self.estimatedDuration = NULL_TO_NIL([values objectForKey:@"estimatedDuration"]);
    self.executor = NULL_TO_NIL([values objectForKey:@"executor"]);
    self.fullDisplayName = NULL_TO_NIL([values objectForKey:@"fullDisplayName"]);
    self.build_id = NULL_TO_NIL([values objectForKey:@"build_id"]);
    self.keepLog = NULL_TO_NIL([values objectForKey:@"keepLog"]);
    self.number = NULL_TO_NIL([values objectForKey:@"number"]);
    self.result = NULL_TO_NIL([values objectForKey:@"result"]);
    NSNumber *timestamp = NULL_TO_NIL([values objectForKey:@"timestamp"]);
    self.timestamp = [NSDate dateWithTimeIntervalSince1970:[timestamp intValue]];
    self.url = NULL_TO_NIL([values objectForKey:@"url"]);
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to set build values" format:@"Error saving context: %@", error];
    }
}

@end
