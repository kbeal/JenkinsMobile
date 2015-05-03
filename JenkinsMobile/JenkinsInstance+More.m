//
//  JenkinsInstance+More.m
//  JenkinsMobile
//
//  Created by Kyle on 2/19/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "JenkinsInstance+More.h"
#import "Constants.h"
#import "Job+More.h"
#import "UICKeyChainStore.h"
#import "View+More.h"

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

- (NSString *) password
{
    if (self.username) {
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithServer:[NSURL URLWithString:self.url]
                                                                  protocolType:UICKeyChainStoreProtocolTypeHTTPS];
        return keychain[self.username];
    }

    return nil;
}

- (void)setPassword:(NSString *) newPassword
{
    if (self.username) {
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithServer:[NSURL URLWithString:self.url]
                                                                  protocolType:UICKeyChainStoreProtocolTypeHTTPS];
        keychain[self.username] = newPassword;
    }
}

- (void)setValues:(NSDictionary *) values
{
    self.name = [values objectForKey:JenkinsInstanceNameKey];
    self.url = [values objectForKey:JenkinsInstanceURLKey];
    self.current = [values objectForKey:JenkinsInstanceCurrentKey];
    self.enabled = [values objectForKey:JenkinsInstanceEnabledKey];
    self.username = [values objectForKey:JenkinsInstanceUsernameKey];
    self.authenticated = [values objectForKey:JenkinsInstanceAuthenticatedKey];
    self.primaryView = [values objectForKeyedSubscript:JenkinsInstancePrimaryViewKey];
    self.shouldAuthenticate = [values objectForKey:JenkinsInstanceShouldAuthenticateKey];
    [self createJobs:[values objectForKey:JenkinsInstanceJobsKey]];
    [self createViews:[values objectForKey:JenkinsInstanceViewsKey]];
    self.lastSyncResult = [values objectForKey:JenkinsInstanceLastSyncResultKey];
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

- (void)createViews:(NSArray *) viewValues
{
    NSMutableSet *currentViews = (NSMutableSet *)self.rel_Views;
    NSMutableArray *currentViewURLs = [[NSMutableArray alloc] init];
    for (View *view in currentViews) {
        [currentViewURLs addObject:view.url];
    }
    
    for (NSDictionary *view in viewValues) {
        NSMutableDictionary *mutview = [NSMutableDictionary dictionaryWithDictionary:view];
        [mutview setObject:self forKey:ViewJenkinsInstanceKey];
        
        if ([mutview objectForKey:ViewNameKey] == [self.primaryView objectForKey:ViewNameKey]) {
            NSString *fullViewURL = [NSString stringWithFormat:@"%@%@%@%@",[mutview objectForKey:ViewURLKey],@"view/",[mutview objectForKey:ViewNameKey],@"/"];
            [mutview setObject:fullViewURL forKey:ViewURLKey];
        }
        if (![currentViewURLs containsObject:[mutview objectForKey:ViewURLKey]]) {
            View *newView = [View createViewWithValues:mutview inManagedObjectContext:self.managedObjectContext];
            [currentViews addObject:newView];
        }
    }
}

@end
