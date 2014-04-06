//
//  Job.m
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "Job.h"

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


+ (Job *)createJobWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context forJenkinsInstance:(JenkinsInstance *) jinstance
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
    
    NSMutableDictionary *valuesWithJenkinsInstance = [NSMutableDictionary dictionaryWithDictionary:values];
    [valuesWithJenkinsInstance setObject:jinstance forKey:@"jenkinsInstance"];
    [job setValues:valuesWithJenkinsInstance];
    
    return job;
}

- (void)setValues:(NSDictionary *) values
{
    self.rel_Job_JenkinsInstance = [values objectForKey:@"jenkinsInstance"];
    self.url = [values objectForKey:@"url"];
    self.name = [values objectForKey:@"name"];
    self.color = [values objectForKey:@"color"];
    self.buildable = [[values objectForKey:@"buildable"] isEqualToString:@"true"] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    self.concurrentBuild = [[values objectForKey:@"concurrentBuild"] isEqualToString:@"true"] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    self.displayName = [values objectForKey:@"displayName"];
    self.queueItem = [values objectForKey:@"queueItem"];
    self.inQueue = [[values objectForKey:@"inQueue"] isEqualToString:@"true"] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    self.job_description = [values objectForKey:@"description"];
    self.keepDependencies = [[values objectForKey:@"keepDependencies"] isEqualToString:@"true"] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    self.firstBuild = [values objectForKey:@"firstBuild"];
    self.lastBuild = [values objectForKey:@"lastBuild"];
    self.lastCompletedBuild = [values objectForKey:@"lastCompletedBuild"];
    self.lastFailedBuild = [values objectForKey:@"lastFailedBuild"];
    self.lastStableBuild = [values objectForKey:@"lastStableBuild"];
    self.lastSuccessfulBuild= [values objectForKey:@"lastSuccessfulBuild"];
    self.lastUnstableBuild = [values objectForKey:@"lastUnstableBuild"];
    self.lastUnsuccessfulBuild = [values objectForKey:@"lastUnsuccessfulBuild"];
    self.nextBuildNumber = [values objectForKey:@"nextBuildNumber"];
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to set job values" format:@"Error saving context: %@", error];
    }
}

@end
