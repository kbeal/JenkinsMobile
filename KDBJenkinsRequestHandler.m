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
    [view setRel_View_Jobs:[self createJobsFromArray:[values objectForKey:@"jobs"]]];
    view.rel_View_JenkinsInstance = jinstance;
    
    return view;
}

- (NSSet *) createJobsFromArray: (NSArray *) jobsArray
{
    NSMutableSet *jobs = [[NSMutableSet alloc] initWithCapacity:jobsArray.count];
    for (int i=0; i<jobsArray.count; i++) {
        [jobs addObject:[self createJobWithValues:[jobsArray objectAtIndex:i]]];
    }
    return jobs;
}

- (void) persistJob: (Job *) job
{

}

- (Job *) createJobWithValues: (NSDictionary *) values
{
    // TODO: get current Jenkins Instance
    JenkinsInstance *jinstance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:self.managedObjectContext];
    jinstance.name = @"TestInstance";
    jinstance.url = @"http://www.google.com";
    
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"All",@"http://www.google.com", nil];
    View *view = [self createViewWithValues:[NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys]];

    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:self.managedObjectContext];
    job.rel_Job_JenkinsInstance = jinstance;
    [job addRel_Job_ViewObject:view];
    job.url = [values objectForKey:@"url"];
    job.name = [values objectForKey:@"name"];
    job.color = [values objectForKey:@"color"];
    job.buildable = [[values objectForKey:@"buildable"] isEqualToString:@"true"] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    job.concurrentBuild = [[values objectForKey:@"concurrentBuild"] isEqualToString:@"true"] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    job.displayName = [values objectForKey:@"displayName"];
    job.queueItem = [values objectForKey:@"queueItem"];
    job.inQueue = [[values objectForKey:@"inQueue"] isEqualToString:@"true"] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    job.job_description = [values objectForKey:@"description"];
    job.keepDependencies = [[values objectForKey:@"keepDependencies"] isEqualToString:@"true"] ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
    job.firstBuild = [values objectForKey:@"firstBuild"];
    job.lastBuild = [values objectForKey:@"lastBuild"];
    job.lastCompletedBuild = [values objectForKey:@"lastCompletedBuild"];
    job.lastFailedBuild = [values objectForKey:@"lastFailedBuild"];
    job.lastStableBuild = [values objectForKey:@"lastStableBuild"];
    job.lastSuccessfulBuild= [values objectForKey:@"lastSuccessfulBuild"];
    job.lastUnstableBuild = [values objectForKey:@"lastUnstableBuild"];
    job.lastUnsuccessfulBuild = [values objectForKey:@"lastUnsuccessfulBuild"];
    job.nextBuildNumber = [values objectForKey:@"nextBuildNumber"];
    


    return job;
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
