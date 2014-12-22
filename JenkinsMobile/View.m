//
//  View.m
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "View.h"
#import "Job.h"
#import "Constants.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation View

@dynamic name;
@dynamic property;
@dynamic url;
@dynamic view_description;
@dynamic rel_View_JenkinsInstance;
@dynamic rel_View_Jobs;
@dynamic rel_View_Views;

+ (View *)createViewWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context
{
    View *view = [NSEntityDescription insertNewObjectForEntityForName:@"View" inManagedObjectContext:context];
    
    [view setValues:values];
    
    return view;
}

+ (View *)fetchViewWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context
{
    __block View *view = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [context performBlockAndWait:^{
        request.entity = [NSEntityDescription entityForName:@"View" inManagedObjectContext:context];
        request.predicate = [NSPredicate predicateWithFormat:@"url = %@", url];
        NSError *executeFetchError = nil;
        view = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
        if (executeFetchError) {
            NSLog(@"[%@, %@] error looking up view with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, [executeFetchError localizedDescription]);
        }
    }];
    
    return view;
}

- (void)setValues:(NSDictionary *) values
{
    self.name = NULL_TO_NIL([values objectForKey:@"name"]);
    self.url = NULL_TO_NIL([values objectForKey:@"url"]);
    self.property = NULL_TO_NIL([values objectForKey:@"property"]);
    self.view_description = NULL_TO_NIL([values objectForKey:@"description"]);
    self.rel_View_JenkinsInstance = NULL_TO_NIL([values objectForKey:@"jenkinsInstance"]);
    [self createJobsFromViewValues:[values objectForKey:@"jobs"]];
    [self createChildViews:NULL_TO_NIL([values objectForKey:ViewViewsKey])];
}

- (void) createChildViews: (NSArray *) viewsArray
{
    NSMutableSet *currentChildViews = (NSMutableSet*)self.rel_View_Views;
    
    NSMutableArray *currentChildViewsURLs = [[NSMutableArray alloc] init];
    for (View *view in currentChildViews) {
        [currentChildViewsURLs addObject:view.url];
    }
    
    for (NSDictionary *childViewDict in viewsArray) {
        if (![currentChildViewsURLs containsObject:[childViewDict objectForKey:ViewURLKey]]) {
            View *newView;
            // find existing view with url
            newView = [View fetchViewWithURL:[childViewDict objectForKey:ViewURLKey] inContext:self.managedObjectContext];
            if (newView==nil) {
                // or create new view with url
                NSMutableDictionary *mutchildView = [NSMutableDictionary dictionaryWithDictionary:childViewDict];
                [mutchildView setObject:self.rel_View_JenkinsInstance forKey:ViewJenkinsInstanceKey];
                newView = [View createViewWithValues:mutchildView inManagedObjectContext:self.managedObjectContext];
            }
            
            // add child view to relation
            [currentChildViews addObject:newView];
            [currentChildViewsURLs addObject:newView.url];
        }
    }
}

- (Job *) findOrCreateJobWithValues: (NSDictionary *) jobDict
{
    Job *job;
    // fetch job
    job = [Job fetchJobWithName:[jobDict objectForKey:JobNameKey] inManagedObjectContext:self.managedObjectContext];
    // if it doesn't exist
    if (job==nil) {
        // create it
        job = [Job createJobWithValues:jobDict inManagedObjectContext:self.managedObjectContext];
    }
    return job;
}

- (void) createJobsFromViewValues: (NSArray *) jobsArray
{
    JenkinsInstance *ji = (JenkinsInstance *)self.rel_View_JenkinsInstance;
    NSSet *allJobs = ji.rel_Jobs;
    NSMutableArray *allJobsNames = [[NSMutableArray alloc] initWithCapacity:allJobs.count];
    for (Job *job in allJobs) {
        [allJobsNames addObject:job.name];
    }
    
    NSSet *viewsJobs = self.rel_View_Jobs;
    NSMutableArray *viewsJobsNames = [[NSMutableArray alloc] initWithCapacity:viewsJobs.count];
    for (Job *job in viewsJobs) {
        [viewsJobsNames addObject:job.name];
    }
    
    for (NSDictionary *jobDict in jobsArray) {
        NSMutableDictionary *jobvalues = [jobDict mutableCopy];
        [jobvalues setObject:self.rel_View_JenkinsInstance forKey:JobJenkinsInstanceKey];
        
        // if the job doesn't exist create it
        Job *job = [self findOrCreateJobWithValues:jobvalues];
        
        // if there is no relation between this job and this view, create it
        if (![viewsJobsNames containsObject:[jobDict objectForKey:JobNameKey]]) {
            NSMutableSet *viewjobs = (NSMutableSet *)self.rel_View_Jobs;
            [viewjobs addObject:job];
            NSMutableSet *jobviews = (NSMutableSet *)job.rel_Job_Views;
            [jobviews addObject:self];
        }
    }
}

@end
