//
//  KDBJenkinsRequestHandler.m
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJenkinsRequestHandler.h"
#import "AFNetworking.h"
#import "JenkinsInstance.h"

@implementation KDBJenkinsRequestHandler

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context
{
    self.managedObjectContext=context;
    return self;
}

- (void) importAllViews
{
    NSURL *requestURL = [NSURL URLWithString:@"http://tomcat:8080/api/json"];
    
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
}

- (void) persistViewsToLocalStorage: (NSArray *) views
{
    JenkinsInstance *jinstance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:self.managedObjectContext];
    jinstance.name = @"TestInstance";
    jinstance.url = @"http://www.google.com";
    
    for (int i=0; i<views.count; i++) {
        [View createViewWithValues:[views objectAtIndex:i] inManagedObjectContext:self.managedObjectContext forJenkinsInstance:jinstance];
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to import views" format:@"Error saving context: %@", error];
    }
}

- (void) persistJobsToLocalStorage: (NSArray *) jobs forJenkinsInstance: (JenkinsInstance *) jinstance
{
    for (NSDictionary *job in jobs) {
        [Job createJobWithValues:job inManagedObjectContext:self.managedObjectContext forJenkinsInstance:jinstance];
    }
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to import jobs" format:@"Error saving context: %@", error];
    }
}

- (View *) importViewDetails: (NSString *) viewName
{
    //property
    //description
    //jobs
    View *view;
    return view;
}



- (void) importAllJobs
{
    
}

@end
