//
//  Job.m
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "Job.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation Job

@dynamic actions;
@dynamic buildable;
@dynamic color;
@dynamic concurrentBuild;
@dynamic displayName;
@dynamic displayNameOrNull;
@dynamic downstreamProjects;
@dynamic firstBuild;
@dynamic healthReport;
@dynamic inQueue;
@dynamic job_description;
@dynamic keepDependencies;
@dynamic lastBuild;
@dynamic lastCompletedBuild;
@dynamic lastFailedBuild;
@dynamic lastStableBuild;
@dynamic lastSuccessfulBuild;
@dynamic lastUnstableBuild;
@dynamic lastUnsuccessfulBuild;
@dynamic name;
@dynamic nextBuildNumber;
@dynamic property;
@dynamic queueItem;
@dynamic scm;
@dynamic upstreamProjects;
@dynamic url;
@dynamic rel_Job_Builds;
@dynamic rel_Job_JenkinsInstance;
@dynamic rel_Job_View;


+ (Job *)createJobWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context forView:(View *) view byCaller:(NSString *) caller;
{
    Job *job = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = [NSEntityDescription entityForName:@"Job" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@", [values objectForKey:@"url"]];
    NSError *executeFetchError = nil;
    job = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up job with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [values objectForKey:@"url"], [executeFetchError localizedDescription]);
    } else if (!job) {
        job = [NSEntityDescription insertNewObjectForEntityForName:@"Job"
                                             inManagedObjectContext:context];
    }
    
    [job addRel_Job_ViewObject:view];
    
    job.rel_Job_JenkinsInstance = view.rel_View_JenkinsInstance;
    [job setValues:values byCaller:caller];
    
    return job;
}

- (void)setValues:(NSDictionary *) values byCaller:(NSString *) caller;
{
    self.url = NULL_TO_NIL([values objectForKey:@"url"]);
    self.name = NULL_TO_NIL([values objectForKey:@"name"]);
    self.color = NULL_TO_NIL([values objectForKey:@"color"]);
    self.buildable = [values objectForKey:@"buildable"];
    self.concurrentBuild = [values objectForKey:@"concurrentBuild"];
    self.displayName = NULL_TO_NIL([values objectForKey:@"displayName"]);
    self.queueItem = NULL_TO_NIL([values objectForKey:@"queueItem"]);
    self.inQueue = [values objectForKey:@"inQueue"];
    self.job_description = NULL_TO_NIL([values objectForKey:@"description"]);
    self.keepDependencies = [values objectForKey:@"keepDependencies"];
    self.firstBuild = [NULL_TO_NIL([values objectForKey:@"firstBuild"]) objectForKey:@"number"];
    self.lastBuild = [NULL_TO_NIL([values objectForKey:@"lastBuild"]) objectForKey:@"number"];
    self.lastCompletedBuild = [NULL_TO_NIL([values objectForKey:@"lastCompletedBuild"]) objectForKey:@"number"];
    self.lastFailedBuild = [NULL_TO_NIL([values objectForKey:@"lastFailedBuild"]) objectForKey:@"number"];
    self.lastStableBuild = [NULL_TO_NIL([values objectForKey:@"lastStableBuild"]) objectForKey:@"number"];
    self.lastSuccessfulBuild= [NULL_TO_NIL([values objectForKey:@"lastSuccessfulBuild"]) objectForKey:@"number"];
    self.lastUnstableBuild = [NULL_TO_NIL([values objectForKey:@"lastUnstableBuild"]) objectForKey:@"number"];
    self.lastUnsuccessfulBuild = [NULL_TO_NIL([values objectForKey:@"lastUnsuccessfulBuild"]) objectForKey:@"number"];
    self.nextBuildNumber = NULL_TO_NIL([values objectForKey:@"nextBuildNumber"]);
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to set job values" format:@"Error saving context: %@", error];
    }
    
    [self setRel_Job_Builds:[self createBuildsFromJobValues:[values objectForKey:@"builds"]]];
    
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to set job values after creating job's builds" format:@"%@ ************Error saving context: %@", caller, error];
    }
}

- (NSSet *) createBuildsFromJobValues: (NSArray *) buildsArray
{
    NSMutableSet *builds = [[NSMutableSet alloc] initWithCapacity:buildsArray.count];
    for (int i=0; i<buildsArray.count; i++) {
        [builds addObject:[Build createBuildWithValues:[buildsArray objectAtIndex:i] inManagedObjectContext:self.managedObjectContext forJob:self]];
    }
    return builds;
}

@end
