//
//  JenkinsInstance.m
//  JenkinsMobile
//
//  Created by Kyle on 4/6/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "JenkinsInstance.h"
#import "Job.h"
#import "View.h"


@implementation JenkinsInstance

@dynamic name;
@dynamic url;
@dynamic current;
@dynamic rel_Jobs;
@dynamic rel_Views;

+ (JenkinsInstance *)createJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context
{
    JenkinsInstance *instance = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = [NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@", [values objectForKey:@"url"]];
    NSError *executeFetchError = nil;
    instance = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up JenkinsInstance with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [values objectForKey:@"url"], [executeFetchError localizedDescription]);
    } else if (!instance) {
        instance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance"
                                             inManagedObjectContext:context];
    }
    
    [instance setValues:values];
    
    return instance;
}

+ (JenkinsInstance *)fetchJenkinsInstanceWithURL: (NSString *) url fromManagedObjectContext: (NSManagedObjectContext *) context
{
    JenkinsInstance *instance = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = [NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"url = %@", url];
    NSError *executeFetchError = nil;
    instance = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    if (executeFetchError) {
        NSLog(@"[%@, %@] error looking up JenkinsInstance with url: %@ with error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url, [executeFetchError localizedDescription]);
    }
    
    return instance;
}

+ (JenkinsInstance *)getCurrentJenkinsInstanceFromManagedObjectContext:(NSManagedObjectContext *) context
{
    JenkinsInstance *instance = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    request.entity = [NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:context];
    request.predicate = [NSPredicate predicateWithFormat:@"current = %d", 1];
    NSError *executeFetchError = nil;
    instance = [[context executeFetchRequest:request error:&executeFetchError] lastObject];
    
    return instance;
}

- (void)setValues:(NSDictionary *) values
{
    self.name = [values objectForKey:@"name"];
    self.url = [values objectForKey:@"url"];
    self.current = [values objectForKey:@"current"];
}

@end
