//
//  View+More.m
//  JenkinsMobile
//
//  Created by Kyle on 2/25/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "View+More.h"
#import "Constants.h"
#import "Job+More.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation View (More)

+ (View *)createViewWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context
{
    View *view = [NSEntityDescription insertNewObjectForEntityForName:@"View" inManagedObjectContext:context];
    
    [view setValues:values];
    
    return view;
}

+ (View *)fetchViewWithURL:(NSString *)url inContext:(NSManagedObjectContext *) context
{
    View *view = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = [NSEntityDescription entityForName:@"View" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@", url];
    NSError *executeFetchError = nil;
    view = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up view with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, [executeFetchError localizedDescription]);
    }
    
    return view;
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

- (void)setValues:(NSDictionary *) values
{
    self.name = NULL_TO_NIL([values objectForKey:@"name"]);
    self.url = NULL_TO_NIL([values objectForKey:@"url"]);
    self.property = NULL_TO_NIL([values objectForKey:@"property"]);
    self.lastSyncResult = NULL_TO_NIL([values objectForKey:ViewLastSyncResultKey]);
    self.view_description = NULL_TO_NIL([values objectForKey:@"description"]);
    self.rel_View_JenkinsInstance = NULL_TO_NIL([values objectForKey:@"jenkinsInstance"]);
    [self setCanonicalURL];
    [self createJobsFromViewValues:[values objectForKey:@"jobs"]];
    [self createChildViews:NULL_TO_NIL([values objectForKey:ViewViewsKey])];
}

// returns the view's canonical URL
// removes /api/json
// adds /view/<ViewName> if view is JenkinsInstance's primaryView
- (void) setCanonicalURL
{
    NSString *canonicalURL;
    canonicalURL = [View removeApiFromURL:[NSURL URLWithString:self.url]];
    
    if ([[self.rel_View_JenkinsInstance.primaryView objectForKey:ViewNameKey] isEqualToString:self.name]) {
        canonicalURL = [NSString stringWithFormat:@"%@%@%@%@",self.rel_View_JenkinsInstance.url,@"view/",self.name,@"/"];
    }
    self.url = canonicalURL;
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
    job = [Job fetchJobWithName:[jobDict objectForKey:JobNameKey] inManagedObjectContext:self.managedObjectContext andJenkinsInstance:(JenkinsInstance *)self.rel_View_JenkinsInstance];
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
