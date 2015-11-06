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
#import "JenkinsMobile-Swift.h"

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

- (NSArray *) fetchRelatedJobsWithNames:(NSArray *) names
{
    NSArray *jobs = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Job" inManagedObjectContext:self.managedObjectContext];
    request.predicate = [NSPredicate predicateWithFormat:@"name IN %@ && ANY rel_Job_Views.url == %@", names, self.url];
    [request setPropertiesToFetch:[NSArray arrayWithObjects:JobNameKey, nil]];
    NSError *executeFetchError = nil;
    
    jobs = [self.managedObjectContext executeFetchRequest:request error:&executeFetchError];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up related jobs with names for View: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.name, [executeFetchError localizedDescription]);
    }
    
    return jobs;
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

// splits an array of dictionaries (of jobs) into an array of arrays with max 1,000 elements containing
// the names of the jobs
- (NSArray *)splitJobsArrayIntoBatches:(NSArray *) jobs
{
    int batchsize = 1000;
    unsigned long numbatches = jobs.count / batchsize;
    int lastbatchsize = jobs.count % batchsize;
    NSMutableArray *batches = [NSMutableArray arrayWithCapacity:numbatches];
    
    for (int i=0; i<numbatches; i++) {
        NSRange batchrange;
        batchrange.location = i * batchsize;
        batchrange.length = batchsize;
        NSArray *jobbatch = [jobs subarrayWithRange:batchrange];
        [batches addObject:jobbatch];
        //[batches addObject:[jobbatch valueForKey:JobNameKey]];
    }
    
    if (lastbatchsize != 0) {
        NSRange lastbatchrange;
        lastbatchrange.location = numbatches * batchsize;
        lastbatchrange.length = lastbatchsize;
        NSArray *lastbatch = [jobs subarrayWithRange:lastbatchrange];
        [batches addObject:lastbatch];
        //[batches addObject:[lastbatch valueForKey:JobNameKey]];
    }
    
    return batches;
}

// filters down a batch of jobs to those that are new to this View
- (NSArray *) findJobsToRelateFromBatch: (NSArray *) jobBatch
{
    // lookup this batch of names against the JenkinsInstance
    NSArray *batchjobsnames = [jobBatch valueForKey:JobNameKey];
    NSArray *existingRelatedJobs = [self fetchRelatedJobsWithNames:batchjobsnames];
    NSArray *existingRelatedJobsNames = [existingRelatedJobs valueForKey:JobNameKey];
    NSMutableArray *jobDicts = [NSMutableArray arrayWithCapacity:jobBatch.count];
    
    for (NSDictionary *job in jobBatch) {
        [jobDicts addObject:[[JobDictionary alloc] initWithDictionary:job]];
    }
    
    // remove the jobs from the batch that are already imported
    NSSet *jobbatchset = [NSSet setWithArray:jobDicts];
    NSSet *paredJobList = [Job removeJobs:existingRelatedJobsNames fromBatch:jobbatchset];
    return [Job fetchJobsWithNames:[[paredJobList allObjects] valueForKey:JobNameKey] inManagedObjectContext:self.managedObjectContext andJenkinsInstance:self.rel_View_JenkinsInstance];
}

// parses given jobBatch for jobs not yet related to this View and adds this view to the job's relation
// jobBatch is an array of Jobs
// makes a blocking save after inserts
- (void) insertJobBatch:(NSArray *) jobBatch
{
    DataManager *datamgr = [DataManager sharedInstance];
    NSArray *newJobs = [self findJobsToRelateFromBatch:jobBatch];
    // for each job not yet saved
    for (Job *job in newJobs) {
        // relate it to the view
        [self addRel_View_JobsObject:job];
        [job addRel_Job_ViewsObject:self];
    }
    // save our work
    [self.managedObjectContext performBlockAndWait:^{
        [datamgr saveContext:self.managedObjectContext];
    }];
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
            // split the jobs returned in the response data into batches of 1000 job names
            NSArray *batches = [self splitJobsArrayIntoBatches:jobsArray];
            
            for (NSMutableArray *jobbatch in batches) {
                [self.rel_View_JenkinsInstance insertJobBatch:jobbatch forView:self];
                [self insertJobBatch:jobbatch];
            }
        }
    }
}
//            // sort the jobs array by job name
//            NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
//            NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
//            NSArray *sortedJobsArray = [jobsArray sortedArrayUsingDescriptors:sortDescriptors];

//            // place all jobs related to this view's JenkinsInstance in a name -> Job map.
//            NSMutableSet *allJobs = (NSMutableSet*)bgji.rel_Jobs;
//            NSMutableDictionary *allJobsMap = [NSMutableDictionary dictionaryWithCapacity:jobsArray.count];
//            for (Job *job in allJobs) {
//                [allJobsMap setObject:job forKey:job.name];
//            }
//
//            // place all jobs related to this view in a name -> Job map.
//            NSMutableSet *viewsJobs = (NSMutableSet *)self.rel_View_Jobs;
//            NSMutableDictionary *viewsJobsMap = [NSMutableDictionary dictionaryWithCapacity:jobsArray.count];
//            for (Job *job in viewsJobs) {
//                [viewsJobsMap setObject:job forKey:job.name];
//            }


//                    // look up the job name against the View's JenkinsInstance's Jobs
//                    Job *existingJIJob = [allJobsMap objectForKey:[job objectForKey:JobNameKey]];
//                    // look up the job name against the View's Jobs
//                    Job *existingViewJob = [viewsJobsMap objectForKey:[job objectForKey:JobNameKey]];
//                    // if the Job doesn't exist within the JenkinsInstance
//                    if (existingJIJob == nil) {
//                        NSMutableDictionary *mutjob = [NSMutableDictionary dictionaryWithDictionary:job];
//                        [mutjob setObject:bgji forKey:JobJenkinsInstanceKey];
//                        // create it
//                        Job *newJob = [Job createJobWithValues:mutjob inManagedObjectContext:datamgr.masterMOC];
//                        // relate it to this View's JenkinsInstance and to this View
//                        [allJobs addObject:newJob];
//                        [bgji addRel_JobsObject:newJob];
//                        [self addRel_View_JobsObject:newJob];
//                        [viewsJobsMap setObject:newJob forKey:[job objectForKey:JobNameKey]];
//                        [allJobsMap setObject:newJob forKey:[job objectForKey:JobNameKey]];
//                        [newJob addRel_Job_ViewsObject:self];
//                        [viewsJobs addObject:newJob];
//                        [newJob setRel_Job_JenkinsInstance:bgji];
//                    // if the Job exists as relation to View's JenkinsInstance, but not to this View itself
//                    } else if (existingViewJob == nil) {
//                        // look it up against the name -> JenkinsInstance.Jobs map
//                        Job *existingJob = [allJobsMap objectForKey:[job objectForKey:JobNameKey]];
//                        // relate it to this View
//                        [existingJob addRel_Job_ViewsObject:self];
//                        [viewsJobsMap setObject:existingJob forKey:[job objectForKey:JobNameKey]];
//                        [viewsJobs addObject:existingJob];
//                        [self addRel_View_JobsObject:existingJob];
//                    }


@end
