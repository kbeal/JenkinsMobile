//
//  Job+More.m
//  JenkinsMobile
//
//  Created by Kyle on 2/24/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "Job+More.h"
#import "Constants.h"
#import "View.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation Job (More)

+ (Job *)createJobWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context
{
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:context];
    
    [job setValues:values];
    
    return job;
}

+ (Job *)fetchJobWithName: (NSString *) name inManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) jinstance
{
    Job *job = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Job" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"name = %@ && rel_Job_JenkinsInstance.url = %@", name, jinstance.url];
    NSError *executeFetchError = nil;
    
    job = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up job with name: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), name, [executeFetchError localizedDescription]);
    }
    
    return job;
}

// Returns array of jobs that exist related to given JenkinsInstance that have name present in given names Array.
// Return value contains NSManagedObjects
+ (NSArray *)fetchJobsWithNames: (NSArray *) names inManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) jinstance
{
    NSArray *jobs = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Job" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"name IN %@ && rel_Job_JenkinsInstance.url = %@", names, jinstance.url];
    [request setPropertiesToFetch:[NSArray arrayWithObjects:JobNameKey, nil]];
    NSError *executeFetchError = nil;
    
    jobs = [context executeFetchRequest:request error:&executeFetchError];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up jobs with names for JenkinsInstance: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), jinstance.name, [executeFetchError localizedDescription]);
    }
    
    return jobs;
}

// returns the absolute color of this job
// strips the "anime" part of color is job is building
// ex: if job.color==blue_anime, this method returns just "blue"
- (NSString *)absoluteColor
{
    NSString *color = @"";
    if ([[self.color componentsSeparatedByString:@"_"] count] > 0) {
        color = [self.color componentsSeparatedByString:@"_"][0];
    } else {
        color = self.color;
    }
    return color;
}

- (NSArray *) getActiveConfigurations
{
    // TODO: make work with new ActiveConfigurations.
    NSMutableArray *aconfigs = [[NSMutableArray alloc] initWithCapacity:[self.activeConfigurations count]];
    /*
     for (NSDictionary *config in self.activeConfigurations) {
     ActiveConfiguration *aconfig = [[ActiveConfiguration alloc] initWithName:[config objectForKey:ActiveConfigurationNameKey] Color:[config objectForKey:ActiveConfigurationColorKey] andURL:[config objectForKey:ActiveConfigurationURLKey]];
     [aconfigs addObject:aconfig];
     }*/
    return aconfigs;
}

// returns TRUE if the job's current color is animated
- (BOOL)colorIsAnimated { return [self.color rangeOfString:@"anime"].length > 0 ? true : false; }

- (void) setTestResultsImageWithImage:(UIImage *) image { self.testResultsImage = UIImagePNGRepresentation(image); }

- (UIImage *) getTestResultsImage { return [UIImage imageWithData:self.testResultsImage]; }

// returns true if sufficient time has passed since this job's lastSync to perform a new sync
- (BOOL)shouldSync
{
    NSDate *now = [NSDate date];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSSecondCalendarUnit
                                               fromDate:self.lastSync
                                                 toDate:now
                                                options:0];
    
    if (components.second >= MaxJobSyncAge) {
        return true;
    } else {
        return false;
    }
}

+ (NSString *)jobNameFromURL: (NSURL *) jobURL
{
    NSArray *pathComponents = [jobURL pathComponents];
    bool isJobName = false;
    NSString *jobName = nil;
    for (NSString *component in pathComponents) {
        if (isJobName) {
            jobName = component;
            break;
        }
        if ([component isEqualToString:@"job"]) {
            isJobName = true;
        } else {
            isJobName = false;
        }
    }
    return jobName;
}

- (void)setValues:(NSDictionary *) values
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
    self.upstreamProjects = NULL_TO_NIL([values objectForKey:@"upstreamProjects"]);
    self.downstreamProjects = NULL_TO_NIL([values objectForKey:@"downstreamProjects"]);
    self.healthReport = NULL_TO_NIL([values objectForKey:@"healthReport"]);
    self.activeConfigurations = NULL_TO_NIL([values objectForKey:JobActiveConfigurationsKey]);
    self.rel_Job_JenkinsInstance = NULL_TO_NIL([values objectForKey:JobJenkinsInstanceKey]);
    self.lastSync = NULL_TO_NIL([values objectForKey:JobLastSyncKey]);
    self.lastSyncResult = NULL_TO_NIL([values objectForKey:JobLastSyncResultKey]);
}


@end
