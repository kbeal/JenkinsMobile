//
//  ActiveConfiguration+More.m
//  JenkinsMobile
//
//  Created by Kyle on 1/20/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "ActiveConfiguration+More.h"
#import "Constants.h"
#import "Job.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation ActiveConfiguration (More)

+ (ActiveConfiguration *)createActiveConfigurationWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context
{
    ActiveConfiguration *ac = [NSEntityDescription insertNewObjectForEntityForName:@"ActiveConfiguration" inManagedObjectContext:context];
    
    [ac setValues:values];
    
    return ac;
}

+ (ActiveConfiguration *)fetchActiveConfigurationWithURL: (NSString *) url inManagedObjectContext: (NSManagedObjectContext *) context
{
    ActiveConfiguration *ac = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"ActiveConfiguration" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@" , url];
    NSError *executeFetchError = nil;
    
    ac = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up ActiveConfiguration with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, [executeFetchError localizedDescription]);
    }
    
    return ac;
}

+ (void)fetchAndDeleteActiveConfigurationWithURL: (NSString *) url inManagedObjectContext: (NSManagedObjectContext *) context
{
    ActiveConfiguration *ac = [ActiveConfiguration fetchActiveConfigurationWithURL:url inManagedObjectContext:context];
    if (ac != nil) {
        [context deleteObject:ac];
    }
}

-(NSURL *) simplifiedURL
{
    NSURL *simplifiedURL;
    NSURL *originalURL = [NSURL URLWithString:self.url];
    NSArray *pathComponents = [originalURL pathComponents];
    NSMutableArray *simpleComponents = [[NSMutableArray alloc] initWithCapacity:pathComponents.count];
    
    bool isView = false;
    
    for (NSString *component in pathComponents) {
        if ([component isEqualToString:@"view"]) {
            isView = true;
        } else if (isView) {
            isView = false;
        } else {
            isView = false;
            [simpleComponents addObject:component];
        }
    }
    
    NSString *newPath = [simpleComponents componentsJoinedByString:@"/"];
    NSArray *hostarry = [NSArray arrayWithObjects:originalURL.host,@"8080", nil];
    simplifiedURL = [[NSURL alloc] initWithScheme:originalURL.scheme host:[hostarry componentsJoinedByString:@":"] path:newPath];
    
    return simplifiedURL;
}

- (void)setValues:(NSDictionary *) values
{
    self.url = NULL_TO_NIL([values objectForKey:ActiveConfigurationURLKey]);
    self.name = NULL_TO_NIL([values objectForKey:ActiveConfigurationNameKey]);
    self.color = NULL_TO_NIL([values objectForKey:ActiveConfigurationColorKey]);
    self.buildable = [values objectForKey:ActiveConfigurationBuildableKey];
    self.concurrentBuild = [values objectForKey:ActiveConfigurationConcurrentBuildKey];
    self.displayName = NULL_TO_NIL([values objectForKey:ActiveConfigurationDisplayNameKey]);
    self.inQueue = [values objectForKey:ActiveConfigurationInQueueKey];
    self.activeConfiguration_description = NULL_TO_NIL([values objectForKey:ActiveConfigurationDescriptionKey]);
    self.keepDependencies = [values objectForKey:ActiveConfigurationKeepDependenciesKey];
    self.firstBuild = [NULL_TO_NIL([values objectForKey:ActiveConfigurationFirstBuildKey]) objectForKey:@"number"];
    self.lastBuild = [NULL_TO_NIL([values objectForKey:ActiveConfigurationLastBuildKey]) objectForKey:@"number"];
    self.lastCompletedBuild = [NULL_TO_NIL([values objectForKey:ActiveConfigurationLastCompletedBuildKey]) objectForKey:@"number"];
    self.lastFailedBuild = [NULL_TO_NIL([values objectForKey:ActiveConfigurationLastFailedBuildKey]) objectForKey:@"number"];
    self.lastStableBuild = [NULL_TO_NIL([values objectForKey:ActiveConfigurationLastStableBuildKey]) objectForKey:@"number"];
    self.lastSuccessfulBuild= [NULL_TO_NIL([values objectForKey:ActiveConfigurationLastSuccessfulBuildKey]) objectForKey:@"number"];
    self.lastUnstableBuild = [NULL_TO_NIL([values objectForKey:ActiveConfigurationLastUnstableBuildKey]) objectForKey:@"number"];
    self.lastUnsuccessfulBuild = [NULL_TO_NIL([values objectForKey:ActiveConfigurationLastUnsucessfulBuildKey]) objectForKey:@"number"];
    self.nextBuildNumber = NULL_TO_NIL([values objectForKey:ActiveConfigurationNextBuildNumberKey]);
    self.upstreamProjects = NULL_TO_NIL([values objectForKey:ActiveConfigurationUpstreamProjectsKey]);
    self.downstreamProjects = NULL_TO_NIL([values objectForKey:ActiveConfigurationDownstreamProjectsKey]);
    self.healthReport = NULL_TO_NIL([values objectForKey:ActiveConfigurationHealthReportKey]);
    self.rel_ActiveConfiguration_Job = NULL_TO_NIL([values objectForKey:ActiveConfigurationJobKey]);
    self.lastSync = NULL_TO_NIL([values objectForKey:ActiveConfigurationLastSyncKey]);
}

@end
