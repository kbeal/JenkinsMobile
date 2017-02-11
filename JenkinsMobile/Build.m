//
//  Build.m
//  JenkinsMobile
//
//  Created by Kyle on 2/25/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "Build.h"
#import "ActiveConfiguration.h"
#import "Job.h"
#import "Constants.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation Build

// Creates a build that does not yet have a job relation.
+ (Build *) createBuildWithValues:(NSDictionary *) values inManagedObjectContext:(NSManagedObjectContext *)context;
{
    Build *build = [NSEntityDescription insertNewObjectForEntityForName:@"Build" inManagedObjectContext:context];
    
    [build setValues:values];
    
    return build;
}

+ (Build *)fetchBuildWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context
{
    Build *build = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = [NSEntityDescription entityForName:@"Build" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@", url];
    NSError *executeFetchError = nil;
    build = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up build with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, [executeFetchError localizedDescription]);
    }
    
    return build;
}

// Returns array of buildss that exist related to given Job that have number present in given numbers Array.
// Return value contains NSManagedObjects
+ (NSArray *)fetchBuildsWithNumbers: (NSArray *) numbers forJob: (Job *) job
{
    NSArray *builds = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Build" inManagedObjectContext:job.managedObjectContext];
    request.predicate = [NSPredicate predicateWithFormat:@"number IN %@ && rel_Build_Job = %@", numbers, job];
    [request setPropertiesToFetch:[NSArray arrayWithObjects:BuildNumberKey, nil]];
    NSError *executeFetchError = nil;
    
    builds = [job.managedObjectContext executeFetchRequest:request error:&executeFetchError];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up builds with numbers for Job: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), job.name, [executeFetchError localizedDescription]);
    }
    
    return builds;
}

// Removes /api/json and /api/json/ from the end of URL's
+ (NSString *) removeApiFromURL:(NSURL *) url
{
    NSString *missingApi = [url absoluteString];
    if ([[url absoluteString] hasSuffix:@"/api/json"]) {
        missingApi = [[url absoluteString] substringToIndex:[[url absoluteString] length]-9];
    } else if ([[url absoluteString] hasSuffix:@"/api/json/"]) {
        missingApi = [[url absoluteString] substringToIndex:[[url absoluteString] length]-10];
    }
    return missingApi;
}

+ (NSString *) getColorForResult:(NSString *) result
{
    NSArray *colors = [NSArray arrayWithObjects:@"red",@"blue", nil];
    NSArray *results = [NSArray arrayWithObjects:@"FAILURE",@"SUCCESS", nil];
    NSDictionary *colorResultMap = [NSDictionary dictionaryWithObjects:colors forKeys:results];
    return [colorResultMap objectForKey:result];
}

+ (BOOL) colorIsBuilding:(NSString * _Nonnull) color { return [color rangeOfString:@"anime"].length > 0 ? true : false; }

- (BOOL) shouldSync
{
    bool shouldSync = false;
    if ([self.building boolValue]) {
        double now = [[NSDate date] timeIntervalSince1970];
        double currentBuildDuration = now - self.timestamp.timeIntervalSince1970;
        if (self.estimatedDuration != 0) {
            double progress = fabs(currentBuildDuration / [self.estimatedDuration doubleValue]);
            if (progress >= 0.8) {
                shouldSync = true;
            }
        }
    }
    
    if (self.building == nil) {
        shouldSync = true;
    }
    
    return shouldSync;
}

// only sets values returned by a build progress query
- (void)setProgressUpdateValues:(NSDictionary *) values
{
    self.result = NULL_TO_NIL([values objectForKey:@"result"]);
    self.executor = NULL_TO_NIL([values objectForKey:@"executor"]);
    self.building = NULL_TO_NIL([values objectForKey:@"building"]);
}

- (void) updateConsoleText:(NSString * _Nonnull) consoleText
{
    self.consoleText = consoleText;
}

- (void)setValues:(NSDictionary *) values
{
    self.actions = NULL_TO_NIL([values objectForKey:@"actions"]);
    self.artifacts = NULL_TO_NIL([values objectForKey:@"artifacts"]);
    self.build_description = NULL_TO_NIL([values objectForKey:@"description"]);
    self.building = NULL_TO_NIL([values objectForKey:@"building"]);
    self.builtOn = NULL_TO_NIL([values objectForKey:@"builtOn"]);
    self.changeset = NULL_TO_NIL([values objectForKey:BuildChangeSetKey]);
    self.culprits = NULL_TO_NIL([values objectForKey:@"culprits"]);
    self.duration = NULL_TO_NIL([values objectForKey:@"duration"]);
    self.estimatedDuration = NULL_TO_NIL([values objectForKey:@"estimatedDuration"]);
    self.executor = NULL_TO_NIL([values objectForKey:@"executor"]);
    self.fullDisplayName = NULL_TO_NIL([values objectForKey:@"fullDisplayName"]);
    self.build_id = NULL_TO_NIL([values objectForKey:BuildIDKey]);
    self.keepLog = NULL_TO_NIL([values objectForKey:@"keepLog"]);
    self.number = NULL_TO_NIL([values objectForKey:@"number"]);
    self.result = NULL_TO_NIL([values objectForKey:@"result"]);
    NSNumber *timestamp = NULL_TO_NIL([values objectForKey:@"timestamp"]);
    self.timestamp = [NSDate dateWithTimeIntervalSince1970:([timestamp doubleValue] / 1000)];
    self.url = NULL_TO_NIL([values objectForKey:@"url"]);
    self.rel_Build_Job = NULL_TO_NIL([values objectForKey:BuildJobKey]);
    self.lastSyncResult = NULL_TO_NIL([values objectForKey:BuildLastSyncResultKey]);
}

@end
