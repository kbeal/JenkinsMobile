//
//  Build.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 4/25/14.
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
@dynamic number;
@dynamic result;
@dynamic timestamp;
@dynamic url;
@dynamic jobURL;

// Creates a build that does not yet have a job relation.
+ (Build *) createBuildWithValues:(NSDictionary *) values inManagedObjectContext:(NSManagedObjectContext *)context forJobAtURL:(NSString *)jobURL
{
    NSMutableDictionary *newVals = [NSMutableDictionary dictionaryWithDictionary:values];
    [newVals setObject:jobURL forKey:@"jobURL"];
    
    __block Build *build = [Build fetchBuildWithURL:[values objectForKey:@"url"] inContext:context];
    
    if (!build) {
        [context performBlockAndWait:^{
            build = [NSEntityDescription insertNewObjectForEntityForName:@"Build" inManagedObjectContext:context];
        }];
    }
    
    [build setValues:newVals];
    
    return build;
}

+ (Build *)fetchBuildWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context
{
    __block Build *build = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [context performBlockAndWait:^{
        request.entity = [NSEntityDescription entityForName:@"Build" inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"url = %@", url];
        NSError *executeFetchError = nil;
        build = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
        if (executeFetchError) {
            NSLog(@"[%@, %@] error looking up build with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, [executeFetchError localizedDescription]);
        }
    }];
    
    return build;
}

+ (NSArray *) fetchAllBuildsWithJobURL: (NSString *) jobURL inContext: (NSManagedObjectContext *) context
{
    __block NSArray *builds = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [context performBlockAndWait:^{
        request.entity = [NSEntityDescription entityForName:@"Build" inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"jobURL = %@", jobURL];
        NSError *fetchError = nil;
        builds = [context executeFetchRequest:request error:&fetchError];
        if (fetchError) {
            NSLog(@"[%@, %@] error looking up build with joburl: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), jobURL, [fetchError localizedDescription]);
        }
    }];
    
    return builds;
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
    self.timestamp = [NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]];
    self.url = NULL_TO_NIL([values objectForKey:@"url"]);
    self.jobURL = NULL_TO_NIL([values objectForKey:@"jobURL"]);
    //self.rel_Build_Job.lastImportedBuild = self.number;
}

@end
