//
//  JenkinsInstance+More.m
//  JenkinsMobile
//
//  Created by Kyle on 2/19/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "JenkinsInstance+More.h"
#import "Constants.h"
#import "Job.h"

@implementation JenkinsInstance (More)

+ (JenkinsInstance *)findOrCreateJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context
{
    JenkinsInstance *instance = [JenkinsInstance fetchJenkinsInstanceWithURL:[values objectForKey:JenkinsInstanceURLKey] fromManagedObjectContext:context];
    if (instance==nil) {
        instance = [JenkinsInstance createJenkinsInstanceWithValues:values inManagedObjectContext:context];
    } else {
        [instance setValues:values];
    }
    
    return instance;
}

+ (JenkinsInstance *)createJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context
{
    JenkinsInstance *instance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:context];
    
    [instance setValues:values];
    
    return instance;
}

+ (JenkinsInstance *)fetchJenkinsInstanceWithURL: (NSString *) url fromManagedObjectContext: (NSManagedObjectContext *) context
{
    JenkinsInstance *instance = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@", url];
    NSError *executeFetchError = nil;
    instance = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up JenkinsInstance with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, [executeFetchError localizedDescription]);
    }
    
    return instance;
}

+ (JenkinsInstance *)getCurrentJenkinsInstanceFromManagedObjectContext:(NSManagedObjectContext *) context
{
    __block JenkinsInstance *instance = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [context performBlockAndWait:^{
        request.entity = [NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"current = %d", 1];
        NSError *executeFetchError = nil;
        instance = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    }];
    
    return instance;
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

- (NSString *)password {}

- (void)setPassword:(NSString*) newPassword
{
    
}

- (void)setValues:(NSDictionary *) values
{
    self.name = [values objectForKey:JenkinsInstanceNameKey];
    self.url = [values objectForKey:JenkinsInstanceURLKey];
    self.current = [values objectForKey:JenkinsInstanceCurrentKey];
    self.enabled = [values objectForKey:JenkinsInstanceEnabledKey];
    [self createJobs:[values objectForKey:JenkinsInstanceJobsKey]];
}

// your local delegate's favorite method!
- (void)createJobs:(NSArray *) jobValues
{
    NSMutableSet *currentJobs = (NSMutableSet*)self.rel_Jobs;
    NSMutableArray *currentJobNames = [[NSMutableArray alloc] init];
    for (Job *job in currentJobs) {
        [currentJobNames addObject:job.name];
    }
    
    for (NSDictionary *job in jobValues) {
        if (![currentJobNames containsObject:[job objectForKey:JobNameKey]]) {
            NSMutableDictionary *mutjob = [NSMutableDictionary dictionaryWithDictionary:job];
            [mutjob setObject:self forKey:JobJenkinsInstanceKey];
            Job *newJob = [Job createJobWithValues:mutjob inManagedObjectContext:self.managedObjectContext];
            [currentJobs addObject:newJob];
        }
    }
}

@end
