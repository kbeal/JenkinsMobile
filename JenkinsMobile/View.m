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
    [self setRel_View_Jobs:[self createJobsFromViewValues:[values objectForKey:@"jobs"]]];
    [self createChildViews:NULL_TO_NIL([values objectForKey:ViewViewsKey])];
}

- (void) createChildViews: (NSArray *) viewsArray
{
    NSMutableSet *currentChildViews = (NSMutableSet*)self.rel_View_Views;
    
    NSMutableArray *currentChildViewsURLs = [[NSMutableArray alloc] init];
    for (View *view in currentChildViews) {
        [currentChildViewsURLs addObject:view.url];
    }
    
    for (NSDictionary *childView in viewsArray) {
        if (![currentChildViewsURLs containsObject:[childView objectForKey:ViewURLKey]]) {
            NSMutableDictionary *mutchildView = [NSMutableDictionary dictionaryWithDictionary:childView];
            [mutchildView setObject:self.rel_View_JenkinsInstance forKey:ViewJenkinsInstanceKey];
            View *newView = [View createViewWithValues:mutchildView inManagedObjectContext:self.managedObjectContext];
            [currentChildViews addObject:newView];
            [currentChildViewsURLs addObject:newView.url];
        }
    }
}

- (NSSet *) createJobsFromViewValues: (NSArray *) jobsArray
{
    NSMutableSet *jobs = [[NSMutableSet alloc] initWithCapacity:jobsArray.count];
    for (int i=0; i<jobsArray.count; i++) {
        [self.managedObjectContext performBlockAndWait:^{
            NSMutableDictionary *jobvalues = [[jobsArray objectAtIndex:i] mutableCopy];
            [jobvalues setObject:self.rel_View_JenkinsInstance forKey:JobJenkinsInstanceKey];
            Job *job = [Job createJobWithValues:jobvalues inManagedObjectContext:self.managedObjectContext];
            NSMutableSet *jobviews = (NSMutableSet *)job.rel_Job_Views;
            [jobviews addObject:self];
            job.rel_Job_Views = jobviews;
            [jobs addObject:job];
        }];
    }
    return jobs;
}

@end
