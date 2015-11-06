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
#import "JenkinsMobile-Swift.h"

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
    //self.shouldAuthenticate = [values objectForKey:JenkinsInstanceShouldAuthenticateKey];
    
    [self createViews:[values objectForKey:JenkinsInstanceViewsKey]];
    self.lastSyncResult = [values objectForKey:JenkinsInstanceLastSyncResultKey];
    
    DataManager *datamgr = [DataManager sharedInstance];
    [datamgr.masterMOC performBlock:^{
        [self createJobs:[values objectForKey:JenkinsInstanceJobsKey]];
    }];
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

// your local delegate's favorite method!
- (void)createJobs:(NSArray *) jobValues
{
    if (jobValues.count > 0) {
        DataManager *datamgr = [DataManager sharedInstance];
        // try to fetch the JenkinsInstance on a backgrond context.
        JenkinsInstance *bgji = (JenkinsInstance *)[datamgr ensureObjectOnBackgroundThread:self];
        // only create jobs if instance exists on master context.
        // Will only exist if it has been persisted to disk.
        if (bgji != nil) {
            NSMutableSet *currentJobs = (NSMutableSet*)bgji.rel_Jobs;
            NSMutableArray *currentJobNames = [[NSMutableArray alloc] init];
            for (Job *job in currentJobs) {
                [currentJobNames addObject:job.name];
            }
            
            for (NSDictionary *job in jobValues) {
                if (![currentJobNames containsObject:[job objectForKey:JobNameKey]]) {
                    NSMutableDictionary *mutjob = [NSMutableDictionary dictionaryWithDictionary:job];
                    [mutjob setObject:bgji forKey:JobJenkinsInstanceKey];
                    //NSAssert(bgji.managedObjectContext==datamgr.masterMOC, @"wrong moc!!");
                    Job *newJob = [Job createJobWithValues:mutjob inManagedObjectContext:datamgr.masterMOC];
                    [currentJobs addObject:newJob];
                    [bgji addRel_JobsObject:newJob];
                }
            }
            //NSLog(@"%@%lu%@",@"saving after adding ", (unsigned long)jobValues.count,@" jobs!!");
            [datamgr saveContext:datamgr.masterMOC];
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
