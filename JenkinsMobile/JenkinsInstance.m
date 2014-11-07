//
//  JenkinsInstance.m
//  JenkinsMobile
//
//  Created by Kyle on 4/6/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "JenkinsInstance.h"
#import "Job.h"
#import "View.h"
#import "Constants.h"

@implementation JenkinsInstance

@dynamic name;
@dynamic url;
@dynamic current;
@dynamic rel_Jobs;
@dynamic rel_Views;

+ (JenkinsInstance *)createJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context
{
    __block JenkinsInstance *instance = nil;
    
    [context performBlockAndWait:^{
        instance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:context];
        [instance setValues:values];
    }];
    
    return instance;
}

+ (JenkinsInstance *)fetchJenkinsInstanceWithURL: (NSString *) url fromManagedObjectContext: (NSManagedObjectContext *) context
{
    __block JenkinsInstance *instance = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [context performBlockAndWait:^{
        request.entity = [NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"url = %@", url];
        NSError *executeFetchError = nil;
        instance = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
        
        if (executeFetchError) {
            NSLog(@"[%@, %@] error looking up JenkinsInstance with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, [executeFetchError localizedDescription]);
        }
    }];
    
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

- (void)setValues:(NSDictionary *) values
{
    self.name = [values objectForKey:JenkinsInstanceNameKey];
    self.url = [values objectForKey:JenkinsInstanceURLKey];
    self.current = [values objectForKey:JenkinsInstanceCurrentKey];
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
