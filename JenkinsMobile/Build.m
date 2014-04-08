//
//  Build.m
//  JenkinsMobile
//
//  Created by Kyle on 4/7/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "Build.h"
#import "Job.h"


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
    self.actions = [values objectForKey:@"actions"];
    self.artifacts = [values objectForKey:@"artifacts"];
    self.build_description = [values objectForKey:@"description"];
    self.building = [values objectForKey:@"building"];
    self.builtOn = [values objectForKey:@"builtOn"];
    self.changeset = [values objectForKey:@"changeset"];
    self.culprits = [values objectForKey:@"culprits"];
    self.duration = [values objectForKey:@"duration"];
    self.estimatedDuration = [values objectForKey:@"estimatedDuration"];
    self.executor = [values objectForKey:@"executor"];
    self.fullDisplayName = [values objectForKey:@"fullDisplayName"];
    self.build_id = [values objectForKey:@"build_id"];
    self.keepLog = [values objectForKey:@"keepLog"];
    self.number = [values objectForKey:@"number"];
    self.result = [values objectForKey:@"result"];
    self.timestamp = [values objectForKey:@"timestamp"];
    self.url = [values objectForKey:@"url"];
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to set build values" format:@"Error saving context: %@", error];
    }
}

@end
