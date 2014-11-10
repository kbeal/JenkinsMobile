//
//  KDBJenkinsRequestHandler.m
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJenkinsRequestHandler.h"
#import "AFNetworking.h"
#import "Constants.h"

@implementation KDBJenkinsRequestHandler

@synthesize importJobsMOC = _importJobsMOC;
@synthesize importBuildsMOC = _importBuildsMOC;

- (id) initWithJenkinsInstance: (JenkinsInstance *) instance
{
    //self.jinstance = instance;
    self.view_count = 0;
    self.viewDetails = [[NSMutableArray alloc] init];
    self.viewsJobsCounts = [[NSMutableDictionary alloc] init];
    self.viewsJobsDetails = [[NSMutableDictionary alloc] init];
    self.jobsBuildsCounts = [[NSMutableDictionary alloc] init];
    self.jobsBuildsDetails = [[NSMutableDictionary alloc] init];
    
    return self;
}

/*
- (void) importAllViews
{
    //NSLog(@"Starting view import...");
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",self.jinstance.url,@"api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self persistViewsToLocalStorage:[responseObject objectForKey:@"views"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}*/

/*
- (void) importDetailsForView: (NSString *) viewName atURL: (NSString *) viewURL
{
    //NSLog([NSString stringWithFormat:@"%@%@",@"import details for view: ",viewName]);
    //NSLog([NSString stringWithFormat:@"%@%@",@"importing details for view: ",view.url]);
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",viewURL,@"api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // The default Jenkin's 'All' view has the same URL as the node.
        // Which means when we query it, the response doesn't look like a typical view.
        // We have to get the views array out of reponse in that case.
        NSDictionary *viewValues = responseObject;
        if ([viewURL isEqual:self.jinstance.url])
        {
            NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"jobs",@"description", nil];
            NSArray *values = [NSArray arrayWithObjects:viewName,viewURL,[responseObject objectForKey:@"jobs"],[responseObject objectForKey:@"description"], nil];
            viewValues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        }
        [self appendViewDetailsWithValues:viewValues];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}*/

/*
- (void) importDetailsForJobWithName:(NSString*) jobName
{
    //NSLog([NSString stringWithFormat:@"%@%@",@"importing details for job at url: ",jobURL]);
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@",self.jinstance.url,@"/job/",jobName,@"api/json"]];
    
    [self importTestResultsImageForJobWithName:jobName];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%@%@",@"response received for job at url: ",jobURL);
        [[NSNotificationCenter defaultCenter] postNotificationName:JobDetailResponseReceivedNotification object:self userInfo:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        //NSDictionary *info = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:jobName,self.jinstance.url,error, nil] forKeys:[NSArray arrayWithObjects:JobNameKey, JenkinsInstanceURLKey, JobRequestErrorKey, nil]];
        
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
        [[NSNotificationCenter defaultCenter] postNotificationName:JobDetailRequestFailedNotification object:self userInfo:error.userInfo];
    }];
    
    [operation start];
}*/

- (void) importDetailsForJobWithURL:(NSURL *) jobURL
{
    // TODO: fix and uncomment importTestResultsImage
    //[self importTestResultsImageForJobWithName:[Job jobNameFromURL:jobURL]];
    NSURL *requestURL = [jobURL URLByAppendingPathComponent:@"/api/json"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%@%@",@"response received for job at url: ",jobURL);
        [[NSNotificationCenter defaultCenter] postNotificationName:JobDetailResponseReceivedNotification object:self userInfo:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        //NSDictionary *info = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:jobName,self.jinstance.url,error, nil] forKeys:[NSArray arrayWithObjects:JobNameKey, JenkinsInstanceURLKey, JobRequestErrorKey, nil]];
        
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
        [[NSNotificationCenter defaultCenter] postNotificationName:JobDetailRequestFailedNotification object:self userInfo:error.userInfo];
    }];
    
    [operation start];
}

- (void) importDetailsForJenkinsAtURL:(NSString *) url withName:(NSString *) name
{
    //NSLog([NSString stringWithFormat:@"%@%@",@"importing details for job at url: ",jobURL]);
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",url,@"/api/json"]];
    NSLog(@"%@%@",@"Requesting details for Jenkins at URL: ",[requestURL absoluteString]);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // jenkinsRoot/api/json doesn't have url, so add it
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [userInfo setObject:url forKey:JenkinsInstanceURLKey];
        [userInfo setObject:name forKey:JenkinsInstanceNameKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceDetailResponseReceivedNotification object:self userInfo:userInfo];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"failed to receive response for jenkins at url: ",url);
        if (operation.response) {
            NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
            [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceDetailRequestFailedNotification object:self userInfo:info];
        }
    }];
    
    [operation start];
}

/*
- (void) importTestResultsImageForJobAtURL:(NSURL *) jobURL
{
    NSURL *requestURL = [jobURL URLByAppendingPathComponent:@"test/trend"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"response received for test results image at url: ", requestURL);
        [[NSNotificationCenter defaultCenter] postNotificationName:JobTestResultsImageResponseReceivedNotification object:self userInfo:[NSDictionary dictionaryWithObject:jobURL forKey:JobURLKey]];
        [self persistTestResultsImage:responseObject forJobWithName:jobName];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}*/

- (void) importProgressForBuild:(NSNumber *) buildNumber ofJobAtURL:(NSString *) jobURL
{
    NSString *buildURL = [NSString stringWithFormat:@"%@%d",jobURL,[buildNumber intValue]];
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@%@%@",buildURL,@"/api/json?tree=",BuildBuildingKey,@",",BuildTimestampKey,@",",BuildEstimatedDurationKey]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"response received for build progress at url: ",buildURL);
        
        NSNumber *building = [NSNumber numberWithBool:[[responseObject objectForKey:BuildBuildingKey] boolValue]];
        NSNumber *timestamp = [NSNumber numberWithDouble:[[responseObject objectForKey:BuildTimestampKey] doubleValue]];
        NSNumber *estimatedDuration = [NSNumber numberWithDouble:[[responseObject objectForKey:BuildEstimatedDurationKey] doubleValue]];

        NSArray *keys = [NSArray arrayWithObjects:JobURLKey,BuildNumberKey,BuildBuildingKey,BuildTimestampKey,BuildEstimatedDurationKey, nil];
        NSArray *objs = [NSArray arrayWithObjects:jobURL,buildNumber,building,timestamp,estimatedDuration,nil];

        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
        [[NSNotificationCenter defaultCenter] postNotificationName:BuildProgressResponseReceivedNotification object:self userInfo:userInfoDict];

//        [self persistJobAtURL:jobURL withValues:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) importDetailsForBuild: (NSNumber *) buildNumber forJobURL: (NSString *) jobURL
{
//    NSLog([NSString stringWithFormat:@"%@%@",@"importing details for build: ",buildNumber]);
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",jobURL,[buildNumber stringValue],@"/api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self appendBuildDetailsWithValues:responseObject forJobAtURL:jobURL];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

/*
- (void) persistViewsToLocalStorage: (NSArray *) views
{
    @autoreleasepool {
        [self.managedObjectContext performBlock:^{
            for (NSDictionary *view in views) {
                [View createViewWithValues:view inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance.url];
            }
            NSLog(@"saving views...");
            NSError *masterError;
            if (![self.managedObjectContext save:&masterError]) {
                NSLog(@"Error saving master context %@, %@", masterError, [masterError userInfo]);
                abort();
            }
        }];
        self.view_count = [NSNumber numberWithLong:views.count];
    }
    [self importDetailsForViews:views];
}

- (void) persistViewDetailsToLocalStorage
{
    @autoreleasepool {
        [self.managedObjectContext performBlock:^{
            for (NSDictionary *view in self.viewDetails) {
                [View createViewWithValues:view inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance.url];
            }
            NSLog(@"Saving view details...");
            NSError *masterError;
            if (![self.managedObjectContext save:&masterError]) {
                NSLog(@"Error saving master context %@, %@", masterError, [masterError userInfo]);
                abort();
            }
        }];
    }
}

- (void) appendViewDetailsWithValues: (NSDictionary *) viewValues
{
    [self.viewDetails addObject:viewValues];
    if ([NSNumber numberWithLong:self.viewDetails.count] == self.view_count) {
        [self persistViewDetailsToLocalStorage];
    }
}*/

- (void) appendBuildDetailsWithValues: (NSDictionary *) buildValues forJobAtURL: (NSString *) jobURL
{
    NSMutableArray *builds = [self.jobsBuildsDetails objectForKey:jobURL];
    if (builds==nil) {
        builds = [[NSMutableArray alloc] init];
    }
    [builds addObject:buildValues];
    [self.jobsBuildsDetails setObject:builds forKey:jobURL];
    if (builds.count==[[self.jobsBuildsCounts objectForKey:jobURL] intValue]) {
        [self persistBuildDetailsToLocalStorageForJobAtURL:jobURL];
    }
}

- (void) persistTestResultsImage: (UIImage *)image forJobWithName:jobName
{
    [self.importJobsMOC performBlock:^{
        Job *job = [Job fetchJobWithName:jobName inManagedObjectContext:self.importJobsMOC];
        [job setTestResultsImageWithImage:image];
        
        NSError *importJobsError;
        if (![self.importJobsMOC save:&importJobsError]) {
            NSLog(@"Error saving import jobs context %@, %@", importJobsError, [importJobsError userInfo]);
            abort();
        }
        [self.managedObjectContext performBlock:^ {
            NSError *masterError;
            if (![self.managedObjectContext save:&masterError]) {
                NSLog(@"Error saving master context %@, %@", masterError, [masterError userInfo]);
                abort();
            }
        }];
    }];
}

- (void) createBuilds: (NSArray *) builds forJobAtURL: (NSString *) jobURL
{
    @autoreleasepool {
        for (NSDictionary *build in builds) {
            [self.importBuildsMOC performBlock:^{
                [Build createBuildWithValues:build inManagedObjectContext:self.importBuildsMOC forJobAtURL:jobURL];
            }];
        }
        [self.importBuildsMOC performBlock:^{
            NSError *importbuildserror;
            if (![self.importBuildsMOC save:&importbuildserror]) {
                NSLog(@"Error saving import builds context %@, %@", importbuildserror, [importbuildserror userInfo]);
                abort();
            }
            [self.managedObjectContext performBlock:^{
                NSError *masterError;
                if (![self.managedObjectContext save:&masterError]) {
                    NSLog(@"Error saving master context %@, %@", masterError, [masterError userInfo]);
                    abort();
                }
            }];
        }];
    }
}

- (void) persistBuildDetailsToLocalStorageForJobAtURL: (NSString *) jobURL
{
    @autoreleasepool {
        for (NSDictionary *build in [self.jobsBuildsDetails objectForKey:jobURL]) {
            [self.importBuildsMOC performBlock:^{
                [Build createBuildWithValues:build inManagedObjectContext:self.importBuildsMOC forJobAtURL:jobURL];
            }];
        }
        //NSLog([NSString stringWithFormat:@"%@%@",@"saving details for builds for job: ",jobURL]);
        [self.importBuildsMOC performBlock:^ {
            //NSLog([NSString stringWithFormat:@"%@%lu",@"saving this many objs: ",(unsigned long)[[self.importBuildsMOC registeredObjects] count]]);
            NSError *importBuildsError;
            if (![self.importBuildsMOC save:&importBuildsError]) {
                NSLog(@"Error saving import builds context %@, %@", importBuildsError, [importBuildsError userInfo]);
                abort();
            }
            [self.managedObjectContext performBlock:^ {
                NSError *masterError;
                if (![self.managedObjectContext save:&masterError]) {
                    NSLog(@"Error saving master context %@, %@", masterError, [masterError userInfo]);
                    abort();
                }
            }];
            [self.importBuildsMOC reset];
        }];
    }
}

// This context is for import jobs in a background thread
// If the context doesn't already exist, it is created and bound to the master managed object context
- (NSManagedObjectContext *)importJobsMOC
{
    @synchronized(_importJobsMOC) {
        if (_importJobsMOC != nil) {
            return _importJobsMOC;
        }
        
        _importJobsMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_importJobsMOC performBlockAndWait:^{
            [_importJobsMOC setUndoManager:nil];
            [_importJobsMOC setParentContext:self.managedObjectContext];
        }];
        
        return _importJobsMOC;
    }
}

// This context is for import builds in a background thread
// If the context doesn't already exist, it is created and bound to the master managed object context
- (NSManagedObjectContext *)importBuildsMOC
{
    @synchronized(_importBuildsMOC) {
        if (_importBuildsMOC != nil) {
            return _importBuildsMOC;
        }
        
        _importBuildsMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_importBuildsMOC performBlockAndWait:^{
            [_importBuildsMOC setUndoManager:nil];
            [_importBuildsMOC setParentContext:self.managedObjectContext];
        }];
        
        return _importBuildsMOC;
    }
}


@end
