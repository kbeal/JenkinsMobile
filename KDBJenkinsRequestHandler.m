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
    for (int i=0; i<views.count; i++) {
        [self createViewWithValues:[views objectAtIndex:i]];
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to import views" format:@"Error saving context: %@", error];
    }
}

- (View *) createViewWithValues: (NSDictionary *) values
{
    // TODO: get current Jenkins Instance
    JenkinsInstance *jinstance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:self.managedObjectContext];
    jinstance.name = @"TestInstance";
    jinstance.url = @"http://www.google.com";
    
    View *view = [NSEntityDescription insertNewObjectForEntityForName:@"View" inManagedObjectContext:self.managedObjectContext];
    view.name = [values objectForKey:@"name"];
    view.url = [values objectForKey:@"url"];
    view.property = [values objectForKey:@"property"];
    view.view_description = [values objectForKey:@"description"];
    [view setRel_View_Jobs:[self createJobsFromArray:[values objectForKey:@"jobs"] forJenkinsInstance:jinstance]];
    view.rel_View_JenkinsInstance = jinstance;
    
    return view;
}

- (NSSet *) createJobsFromArray: (NSArray *) jobsArray forJenkinsInstance: (JenkinsInstance *) jinstance
{
    NSMutableSet *jobs = [[NSMutableSet alloc] initWithCapacity:jobsArray.count];
    for (int i=0; i<jobsArray.count; i++) {
        [jobs addObject:[Job createJobWithValues:[jobsArray objectAtIndex:i] inManagedObjectContext:self.managedObjectContext forJenkinsInstance:jinstance]];
    }
    return jobs;
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
