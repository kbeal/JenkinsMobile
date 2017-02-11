//
//  Job.m
//  JenkinsMobile
//
//  Created by Kyle on 2/24/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "Job.h"
#import "Build.h"
#import "JenkinsInstance.h"
#import "View.h"
#import "Constants.h"
#import "JenkinsMobile-Swift.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation Job

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

// Returns latest N builds for this Job, ordered by Build# where
// N = numberOfBuilds
- (NSArray *)fetchLatestBuilds:(int) numberOfBuilds
{
    NSArray *builds;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Build" inManagedObjectContext:self.managedObjectContext];
    request.predicate = [NSPredicate predicateWithFormat:@"rel_Build_Job = %@", self];
    NSSortDescriptor *bynumber = [[NSSortDescriptor alloc] initWithKey:BuildNumberKey ascending:NO];
    request.sortDescriptors = [[NSArray alloc] initWithObjects:bynumber, nil];
    [request setFetchLimit:numberOfBuilds];
    NSError *fetchErr = nil;
    
    builds = [self.managedObjectContext executeFetchRequest:request error:&fetchErr];
    
    if (fetchErr) {
        NSLog(@"[%@, %@] error looking up latest builds for job: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.name, [fetchErr localizedDescription]);
    }
    
    return builds;
}

// changes non-color values like 'notbuilt' to the appropriate color and
// strips _anime from color when job is building
+ (NSString *) getNormalizedColor: (NSString *) responseColor
{
    NSString *normalizedColor = responseColor;
    
    if ([[normalizedColor componentsSeparatedByString:@"_"] count] > 0) {
        normalizedColor = [normalizedColor componentsSeparatedByString:@"_"][0];
    }
    
    if ([normalizedColor isEqualToString:@"notbuilt"]) {
        normalizedColor = @"grey";
    }
    
    return normalizedColor;
}

// overrides the getter for the color property
- (NSString *)color
{
    [self willAccessValueForKey:@"color"];
    NSString *truecolor = [Job getNormalizedColor:[self primitiveValueForKey:@"color"]];
    [self didAccessValueForKey:@"color"];
    return truecolor;
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

/*
- (NSSet *)getBuilds
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:self.builds];
}

- (void)setBuilds:(NSSet *) buildsSet
{
    self.builds = [NSKeyedArchiver archivedDataWithRootObject:buildsSet];
}*/

// returns TRUE if the job's current color is animated
- (BOOL)colorIsAnimated { return [[self primitiveValueForKey:@"color"] rangeOfString:@"anime"].length > 0 ? true : false; }

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

    self.firstBuild = NULL_TO_NIL([values objectForKey:@"firstBuild"]);
    self.lastBuild = NULL_TO_NIL([values objectForKey:@"lastBuild"]);
    self.lastCompletedBuild = NULL_TO_NIL([values objectForKey:@"lastCompletedBuild"]);
    self.lastFailedBuild = NULL_TO_NIL([values objectForKey:@"lastFailedBuild"]);
    self.lastStableBuild = NULL_TO_NIL([values objectForKey:@"lastStableBuild"]);
    self.lastSuccessfulBuild= NULL_TO_NIL([values objectForKey:@"lastSuccessfulBuild"]);
    self.lastUnstableBuild = NULL_TO_NIL([values objectForKey:@"lastUnstableBuild"]);
    self.lastUnsuccessfulBuild = NULL_TO_NIL([values objectForKey:@"lastUnsuccessfulBuild"]);
    
    self.nextBuildNumber = NULL_TO_NIL([values objectForKey:@"nextBuildNumber"]);
    self.upstreamProjects = NULL_TO_NIL([values objectForKey:@"upstreamProjects"]);
    self.downstreamProjects = NULL_TO_NIL([values objectForKey:@"downstreamProjects"]);
    self.healthReport = NULL_TO_NIL([values objectForKey:@"healthReport"]);
    self.activeConfigurations = NULL_TO_NIL([values objectForKey:JobActiveConfigurationsKey]);
    self.rel_Job_JenkinsInstance = NULL_TO_NIL([values objectForKey:JobJenkinsInstanceKey]);
    self.lastSync = NULL_TO_NIL([values objectForKey:JobLastSyncKey]);
    self.lastSyncResult = NULL_TO_NIL([values objectForKey:JobLastSyncResultKey]);
    [self createBuildsFromJobValues:NULL_TO_NIL([values objectForKey:JobBuildsKey])];
}

- (NSSet *)findBuildsInResponseToRelate:(NSSet *) responseJobs
{
    // get numbers of builds already related to Job
    NSSet *relatedBuilds = (NSSet *)self.builds;
    NSSet *relatedBuildNumbers = [relatedBuilds valueForKey:BuildNumberKey];
    // find builds (not managed objects) needing to be related job
    return [responseJobs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT number IN %@",relatedBuildNumbers]];
}

// finds BuildDictionaries in responseBuilds not already related to this Job
- (NSSet *)findBuildsToCreate:(NSSet *) responseBuilds
{
    // get numbers of Buildss already related to this Job
    NSSet *relatedBuilds = (NSSet *)self.builds;
    NSSet *relatedBuildNumbers = [relatedBuilds valueForKey:BuildNumberKey];
    // find builds (not managed objects) needing to be created
    return [responseBuilds filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT number IN %@",relatedBuildNumbers]];
}

// finds BuildDictionaries in responseBuilds that are already related to this Job
- (NSSet *)findExistingBuilds:(NSSet *) responseBuilds
{
    // get numbers of Builds already related to this Job
    NSSet *relatedBuilds = (NSSet *)self.builds;
    NSSet *relatedBuildNumbers = [relatedBuilds valueForKey:BuildNumberKey];
    // find builds (not managed objects) already created
    return [responseBuilds filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name IN %@",relatedBuildNumbers]];
}

// takes an NSSet of BuildDictionaries and returns a NSSet of Build managed objects
// builds - NSSet of BuildDictionaries
- (NSSet *)findOrCreateBuilds:(NSSet *)builds
{
    NSMutableSet *managedBuilds = [NSMutableSet setWithCapacity:builds.count];
    DataManager *datamgr = [DataManager sharedInstance];
    if (builds.count > 0 && (self.managedObjectContext == datamgr.masterMOC)) {
        DataManager *datamgr = [DataManager sharedInstance];
        // try to fetch the JenkinsInstance on a backgrond context.
        JenkinsInstance *bgji = (JenkinsInstance *)[datamgr ensureObjectOnBackgroundThread:self];
        // only create builds if instance exists on master context.
        // Will only exist if it has been persisted to disk.
        if (bgji != nil) {
            NSSet *buildsToCreate = [self findBuildsToCreate:builds];
            NSSet *existingBuilds = [self findExistingBuilds:builds];
            // fetch the managed objects for the existing Builds
            NSArray *existingManagedBuilds = [Build fetchBuildsWithNumbers:[[existingBuilds valueForKey:BuildNumberKey] allObjects] forJob:self];
            // add the existing managed Builds to the return set
            for (Build *existingBuild in existingManagedBuilds) {
                [existingBuild setRel_Build_Job:self];
                [managedBuilds addObject:existingBuild];
            }
            
            for (BuildDictionary *build in buildsToCreate) {
                NSMutableDictionary *buildToCreate = [NSMutableDictionary dictionaryWithDictionary:build.dictionary];
                [buildToCreate setObject:self forKey:BuildJobKey];
                Build *newBuild = [Build createBuildWithValues:buildToCreate inManagedObjectContext:self.managedObjectContext];
                [managedBuilds addObject:newBuild];
            }
            
            if (self.builds == nil) {
                self.builds = buildsToCreate;
            } else {
                self.builds = [self.builds setByAddingObjectsFromSet:buildsToCreate];
            }
            
            [self addRel_Job_Builds:managedBuilds];
            [datamgr saveContext:datamgr.masterMOC];
        }
    }
    return managedBuilds;
}

- (void) createBuildsFromJobValues: (NSArray *) buildsArray
{
    DataManager *datamgr = [DataManager sharedInstance];
    if (buildsArray.count > 0 && (self.managedObjectContext == datamgr.masterMOC)) {
        // try to fetch the JenkinsInstance on a backgrond context.
        JenkinsInstance *bgji = (JenkinsInstance *)[datamgr ensureObjectOnBackgroundThread:self.rel_Job_JenkinsInstance];
        // only create builds if instance exists on master context.
        // Will only exist if it has been persisted to disk.
        if (bgji != nil) {
            // copy response object builds into Set of BuildDictionaries
            // BuildDictionary is specialized NSDictionary using name Key for comparison
            NSMutableSet *responseBuildDicts = [NSMutableSet setWithCapacity:buildsArray.count];
            for (NSDictionary *build in buildsArray) {
                [responseBuildDicts addObject:[[BuildDictionary alloc] initWithDictionary:build]];
            }
            
            // find the builds needing created in CoreData and related to this Job
            NSSet *buildsToRelate = [self findBuildsInResponseToRelate:responseBuildDicts];
            NSSet *managedBuilds = [self findOrCreateBuilds:buildsToRelate];
            [self addRel_Job_Builds:managedBuilds];
            self.builds = responseBuildDicts;
            
            // save our work
            [self.managedObjectContext performBlockAndWait:^{
                [datamgr saveContext:self.managedObjectContext];
            }];
        }
    }
}

@end
