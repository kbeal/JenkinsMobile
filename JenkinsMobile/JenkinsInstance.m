//
//  JenkinsInstance.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 12/8/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//

#import "JenkinsInstance.h"
#import "Constants.h"
#import "Job+More.h"
#import "UICKeyChainStore.h"
#import "View.h"
#import "JenkinsMobile-Swift.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation JenkinsInstance

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

- (void) setUrl:(NSString *)url
{
    [self willChangeValueForKey:@"url"];
    if (![self.url isEqualToString:url]) {
        [self deleteAllJobs];
        [self deleteAllViews];
    }
    [self setPrimitiveValue:url forKey:@"url"];
    [self didChangeValueForKey:@"url"];
}

- (void)setValues:(NSDictionary *) values
{
    self.name = [values objectForKey:JenkinsInstanceNameKey];
    self.url = [values objectForKey:JenkinsInstanceURLKey];
    [self correctURL];
    //self.current = [values objectForKey:JenkinsInstanceCurrentKey];
    //self.enabled = [values objectForKey:JenkinsInstanceEnabledKey];
    self.username = [values objectForKey:JenkinsInstanceUsernameKey];
    self.authenticated = [values objectForKey:JenkinsInstanceAuthenticatedKey];
    self.primaryView = [values objectForKeyedSubscript:JenkinsInstancePrimaryViewKey];
    self.lastSyncResult = [values objectForKey:JenkinsInstanceLastSyncResultKey];
    //self.shouldAuthenticate = [values objectForKey:JenkinsInstanceShouldAuthenticateKey];
    
    [self createViews:[values objectForKey:JenkinsInstanceViewsKey]];
    
    //[self createJobs:[values objectForKey:JenkinsInstanceJobsKey]];
}

- (void)updateValues:(NSDictionary *) values
{
    if ([values objectForKey:JenkinsInstanceViewsKey]) {
        [self createViews:[values objectForKey:JenkinsInstanceViewsKey]];
    }
}

- (BOOL)validateInstanceWithMessage:(NSString **) message
{
    NSString *urlMessage;
    NSString *nameMessage;
    NSString *usernameMessage;
    NSString *passwordMessage;
    BOOL validated = false;
    
    validated = [self validateURL:self.url withMessage:&urlMessage];
    validated = validated && [self validateName:self.name withMessage:&nameMessage];
    
    if ([self.shouldAuthenticate boolValue]) {
        validated = validated && [self validateUsername:self.username withMessage:&usernameMessage];
        validated = validated && [self validatePassword:self.password withMessage:&passwordMessage];
    }
    
    if (!validated) {
        *message = [NSString stringWithFormat:@"%@%@%@%@%@%@%@",urlMessage,@" ",nameMessage,@" ",usernameMessage,@" ",passwordMessage];
    }
    
    return validated;
}

- (BOOL)validateURL:(NSString *) newURL withMessage:(NSString **) message {
    NSError *error = nil;
    BOOL validated = [self validateValue:&newURL forKey:JenkinsInstanceURLKey error:&error];
    
    if (!validated) {
        *message = @"URL cannot be empty";
    }
    
    return validated;
}

- (BOOL)validateName:(NSString *) newName withMessage:(NSString **) message {
    NSError *error = nil;
    BOOL validated = [self validateValue:&newName forKey:JenkinsInstanceNameKey error:&error];
    
    if (!validated) {
        *message = @"Name cannot be empty";
    }
    
    return validated;
}

- (BOOL)validateUsername:(NSString *) newUsername withMessage:(NSString **) message {
    NSError *error = nil;
    
    BOOL validated = true;
    if (self.shouldAuthenticate) {
        validated = [self validateValue:&newUsername forKey:JenkinsInstanceUsernameKey error:&error];
        NSString *notBlank = @"^(?!\\s*$).+";
        NSPredicate *regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", notBlank];
        validated = [regexTest evaluateWithObject:newUsername];
    }
    
    if (!validated) {
        *message = @"Username cannot be empty";
    }
    
    return validated;
}

- (BOOL)validatePassword:(NSString *) newPassword withMessage:(NSString **) message {
    BOOL validated = true;
    if (self.shouldAuthenticate) {
        NSString *notBlank = @"^(?!\\s*$).+";
        NSPredicate *regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", notBlank];
        validated = [regexTest evaluateWithObject:newPassword];
    }
    
    if (!validated) {
        *message = @"Password cannot be empty";
    }
    
    return validated;
}

// ensures that this instance's URL ends with a '/'
- (void)correctURL
{
    if ( (self.url != nil) && (![self.url isEqualToString:@""]) && (![self.url hasSuffix:@"/"]) ) {
        self.url = [NSString stringWithFormat:@"%@%@",self.url,@"/"];
    }
}

// finds JobDictionaries in responseJobs not already related to this JenkinsInstance
- (NSSet *)findJobsToCreate:(NSSet *) responseJobs
{
    // get names of Jobs already related to this JenkinsInstance
    NSSet *relatedJobs = (NSSet *)self.jobs;
    NSSet *relatedJobNames = [relatedJobs valueForKey:JobNameKey];
    // find jobs (not managed objects) needing to be created
    return [responseJobs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT name IN %@",relatedJobNames]];
}

// finds JobDictionaries in responseJobs that are already related to this JenkinsInstance
- (NSSet *)findExistingJobs:(NSSet *) responseJobs
{
    // get names of Jobs already related to this JenkinsInstance
    NSSet *relatedJobs = (NSSet *)self.jobs;
    NSSet *relatedJobNames = [relatedJobs valueForKey:JobNameKey];
    // find jobs (not managed objects) needing to be created
    return [responseJobs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name IN %@",relatedJobNames]];
}

// your local delegate's favorite method!
// takes an NSSet of JobDictionaries and returns and NSSet of Job managed objects
// jobs - NSSet of JobDictionaries
// view - View to relate to Jobs needing created
- (NSSet *)findOrCreateJobs:(NSSet *)jobs inView:(View *) view;
{
    NSMutableSet *managedJobs = [NSMutableSet setWithCapacity:jobs.count];
    DataManager *datamgr = [DataManager sharedInstance];
    if (jobs.count > 0 && (self.managedObjectContext == datamgr.masterMOC)) {
        DataManager *datamgr = [DataManager sharedInstance];
        // try to fetch the JenkinsInstance on a backgrond context.
        JenkinsInstance *bgji = (JenkinsInstance *)[datamgr ensureObjectOnBackgroundThread:self];
        // only create jobs if instance exists on master context.
        // Will only exist if it has been persisted to disk.
        if (bgji != nil) {
            NSSet *jobsToCreate = [self findJobsToCreate:jobs];
            NSSet *existingJobs = [self findExistingJobs:jobs];
            // fetch the managed objects for the existing Jobs
            NSArray *existingManagedJobs = [Job fetchJobsWithNames:[[existingJobs valueForKey:JobNameKey] allObjects] inManagedObjectContext:self.managedObjectContext andJenkinsInstance:self];
            // add the existing managed Jobs to the return set
            for (Job *existingJob in existingManagedJobs) {
                [existingJob addRel_Job_ViewsObject:view];
                [managedJobs addObject:existingJob];
            }
            
            for (JobDictionary *job in jobsToCreate) {
                NSMutableDictionary *jobToCreate = [NSMutableDictionary dictionaryWithDictionary:job.dictionary];
                [jobToCreate setObject:self forKey:JobJenkinsInstanceKey];
                Job *newJob = [Job createJobWithValues:jobToCreate inManagedObjectContext:self.managedObjectContext];
                [newJob addRel_Job_ViewsObject:view];
                [managedJobs addObject:newJob];
            }
            self.jobs = jobs;
            [self addRel_Jobs:managedJobs];
            [datamgr saveContext:datamgr.masterMOC];
        }
    }
    return managedJobs;
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
        
        if ([[mutview objectForKey:ViewNameKey] isEqualToString:[self.primaryView objectForKey:ViewNameKey]] && [[mutview objectForKey:ViewURLKey] isEqualToString:[self.primaryView objectForKey:ViewURLKey]]) {
            NSString *encodedName = [[mutview objectForKey:ViewNameKey] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
            NSString *canonicalURL = [NSString stringWithFormat:@"%@%@%@%@",self.url,@"view/",encodedName,@"/"];
            [mutview setObject:canonicalURL forKey:ViewURLKey];
        }
        if (![currentViewURLs containsObject:[mutview objectForKey:ViewURLKey]]) {
            View *newView = [View createViewWithValues:mutview inManagedObjectContext:self.managedObjectContext];
            [currentViews addObject:newView];
        }
    }
}

- (void) deleteAllJobs
{
    for (Job *job in self.rel_Jobs) {
        [self.managedObjectContext deleteObject:job];
    }
    /* TODO: implement batch delete
     NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Job"];
     request.predicate = [NSPredicate predicateWithFormat:@"rel_Job_JenkinsInstance == %@", self];
     NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
     
     NSError *deleteError = nil;
     [self.managedObjectContext.persistentStoreCoordinator executeRequest:delete withContext:self.managedObjectContext error:&deleteError];
     */
    
}

- (void) deleteAllViews
{
    for (View *view in self.rel_Views) {
        [self.managedObjectContext deleteObject:view];
    }
    // TODO: implement batch delete
}

@end
