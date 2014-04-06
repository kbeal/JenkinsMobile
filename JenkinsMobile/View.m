//
//  View.m
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "View.h"
#import "Job.h"


@implementation View

@dynamic name;
@dynamic property;
@dynamic url;
@dynamic view_description;
@dynamic rel_View_JenkinsInstance;
@dynamic rel_View_Jobs;

+ (View *)createViewWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context forJenkinsInstance:(JenkinsInstance *) jinstance
{
    View *view = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = [NSEntityDescription entityForName:@"View" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@", [values objectForKey:@"url"]];
    NSError *executeFetchError = nil;
    view = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up view with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [values objectForKey:@"url"], [executeFetchError localizedDescription]);
    } else if (!view) {
        view = [NSEntityDescription insertNewObjectForEntityForName:@"View"
                                            inManagedObjectContext:context];
    }
    
    NSMutableDictionary *valuesWithJenkinsInstance = [NSMutableDictionary dictionaryWithDictionary:values];
    [valuesWithJenkinsInstance setObject:jinstance forKey:@"jenkinsInstance"];
    [view setValues:valuesWithJenkinsInstance];
    
    return view;
}

- (void)setValues:(NSDictionary *) values
{
    self.name = [values objectForKey:@"name"];
    self.url = [values objectForKey:@"url"];
    self.property = [values objectForKey:@"property"];
    self.view_description = [values objectForKey:@"description"];
    self.rel_View_JenkinsInstance = [values objectForKey:@"jenkinsInstance"];
    [self setRel_View_Jobs:[self createJobsFromViewValues:[values objectForKey:@"jobs"]]];
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to set view values" format:@"Error saving context: %@", error];
    }

}

- (NSSet *) createJobsFromViewValues: (NSArray *) jobsArray
{
    NSMutableSet *jobs = [[NSMutableSet alloc] initWithCapacity:jobsArray.count];
    for (int i=0; i<jobsArray.count; i++) {
        [jobs addObject:[Job createJobWithValues:[jobsArray objectAtIndex:i] inManagedObjectContext:self.managedObjectContext forJenkinsInstance:(JenkinsInstance *)self.rel_View_JenkinsInstance]];
    }
    return jobs;
}

@end
