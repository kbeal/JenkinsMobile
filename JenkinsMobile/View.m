//
//  View.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 12/8/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//

#import "View.h"
#import "Constants.h"
#import "Job.h"
#import "JenkinsInstance.h"
#import "JenkinsMobile-Swift.h"

// Convert any NULL values to nil. Lifted from Kevin Ballard here: http://stackoverflow.com/a/9138033
#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

@implementation View

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

// used when all values are present in response data
- (void)setValues:(NSDictionary *) values
{
    self.name = NULL_TO_NIL([values objectForKey:@"name"]);
    self.url = NULL_TO_NIL([values objectForKey:@"url"]);
    self.property = NULL_TO_NIL([values objectForKey:@"property"]);
    self.lastSyncResult = NULL_TO_NIL([values objectForKey:ViewLastSyncResultKey]);
    self.view_description = NULL_TO_NIL([values objectForKey:@"description"]);
    self.rel_View_JenkinsInstance = NULL_TO_NIL([values objectForKey:@"jenkinsInstance"]);
    self.rel_ParentView = NULL_TO_NIL([values objectForKey:ViewParentViewKey]);
    [self setCanonicalURL];
    [self createJobsFromViewValues:[values objectForKey:@"jobs"]];
    [self createChildViews:NULL_TO_NIL([values objectForKey:ViewViewsKey])];
}

// used when only subset of values are present in response data
- (void)updateValues:(NSDictionary *) values
{
    self.name = [values objectForKey:ViewNameKey]!=NULL ? [values objectForKey:ViewNameKey] : self.name;
    self.view_description = [values objectForKey:ViewDescriptionKey]!=NULL ? [values objectForKey:ViewDescriptionKey] : self.view_description;
    self.property = [values objectForKey:ViewPropertyKey]!=NULL ? [values objectForKey:ViewPropertyKey] : self.property;
    self.lastSyncResult = [values objectForKey:ViewLastSyncResultKey]!=NULL ? [values objectForKey:ViewLastSyncResultKey] : self.lastSyncResult;
    
    if ([values objectForKey:ViewURLKey]) {
        self.url = [values objectForKey:ViewURLKey];
        [self setCanonicalURL];
    }
    
    if ([values objectForKey:ViewJobsKey]) {
        [self createJobsFromViewValues:[values objectForKey:ViewJobsKey]];
    }
    
    if ([values objectForKey:ViewViewsKey]) {
        [self createChildViews:[values objectForKey:ViewViewsKey]];
    }
}

// returns the view's canonical URL
// removes /api/json
// adds /view/<ViewName> if view is JenkinsInstance's primaryView
- (void) setCanonicalURL
{
    NSString *canonicalURL;
    canonicalURL = [View removeApiFromURL:[NSURL URLWithString:self.url]];
    
    if ([[self.rel_View_JenkinsInstance.primaryView objectForKey:ViewNameKey] isEqualToString:self.name]) {
        NSString *encodedName = [self.name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        canonicalURL = [NSString stringWithFormat:@"%@%@%@%@",self.rel_View_JenkinsInstance.url,@"view/",encodedName,@"/"];
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
                [mutchildView setObject:self forKey:ViewParentViewKey];
                newView = [View createViewWithValues:mutchildView inManagedObjectContext:self.managedObjectContext];
            }
            
            // add child view to relation
            [currentChildViews addObject:newView];
            [currentChildViewsURLs addObject:newView.url];
        }
    }
}

- (NSSet *)findJobsInResponseToRelate:(NSSet *) responseJobs
{
    // get names of Jobs already related to View
    NSSet *relatedJobs = (NSSet *)self.jobs;
    NSSet *relatedJobNames = [relatedJobs valueForKey:JobNameKey];
    // find jobs (not managed objects) needing to be related view
    return [responseJobs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT name IN %@",relatedJobNames]];
}

- (void) createJobsFromViewValues: (NSArray *) jobsArray
{
    DataManager *datamgr = [DataManager sharedInstance];
    if (jobsArray.count > 0 && (self.managedObjectContext == datamgr.masterMOC)) {
        // try to fetch the JenkinsInstance on a backgrond context.
        JenkinsInstance *bgji = (JenkinsInstance *)[datamgr ensureObjectOnBackgroundThread:self.rel_View_JenkinsInstance];
        // only create jobs if instance exists on master context.
        // Will only exist if it has been persisted to disk.
        if (bgji != nil) {
            // copy response object jobs into Set of JobDictionaries
            // JobDictionary is specialized NSDictionary using name Key for comparison
            NSMutableSet *responseJobDicts = [NSMutableSet setWithCapacity:jobsArray.count];
            for (NSDictionary *job in jobsArray) {
                [responseJobDicts addObject:[[JobDictionary alloc] initWithDictionary:job]];
            }

            // send the jobs needing related to this View to the JenkinsInstance to see if they already exist in CoreData and create them if not
            NSSet *jobsToRelate = [self findJobsInResponseToRelate:responseJobDicts];
            NSSet *managedJobs = [self.rel_View_JenkinsInstance findOrCreateJobs:jobsToRelate inView:self];
            [self addRel_View_Jobs:managedJobs];
            self.jobs = responseJobDicts;
            
            // save our work
            [self.managedObjectContext performBlockAndWait:^{
                [datamgr saveContext:self.managedObjectContext];
            }];
        }
    }
}

@end
