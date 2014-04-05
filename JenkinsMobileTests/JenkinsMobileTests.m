//
//  JenkinsMobileTests.m
//  JenkinsMobileTests
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KDBJenkinsRequestHandler.h"
#import "Job.h"

@interface JenkinsMobileTests : XCTestCase
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation JenkinsMobileTests

- (void)setUp
{
    [super setUp];

    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles: nil];
    NSLog(@"model: %@", model);
    NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
    [coord addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    _context = [[NSManagedObjectContext alloc] init];
    [_context setPersistentStoreCoordinator: coord];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    //TODO: delete all data
    [super tearDown];
}

- (void)testInsertingJobs
{
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origjobs = [_context executeFetchRequest:allJobs error:&error];

    [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:_context];
    
    NSArray *newjobs = [_context executeFetchRequest:allJobs error:&error];
    
    XCTAssert(newjobs.count==origjobs.count+1, @"jobs count should incrase by 1 to %d, instead got %d",origjobs.count+1,newjobs.count);
}

- (void)testInsertingViews
{
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origviews = [_context executeFetchRequest:allViews error:&error];
    
    [NSEntityDescription insertNewObjectForEntityForName:@"View" inManagedObjectContext:_context];
    
    NSArray *newviews = [_context executeFetchRequest:allViews error:&error];
    
    XCTAssert(newviews.count==origviews.count+1, @"jobs count should incrase by 1 to %d, instead got %d",origviews.count+1,newviews.count);
}

- (void)testInsertingJenkinsInstances
{
    NSError *error;
    NSFetchRequest *allInstances = [[NSFetchRequest alloc] init];
    [allInstances setEntity:[NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:_context]];
    [allInstances setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *originstances = [_context executeFetchRequest:allInstances error:&error];
    
    [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:_context];
    
    NSArray *newinstances = [_context executeFetchRequest:allInstances error:&error];
    
    XCTAssert(newinstances.count==originstances.count+1, @"jobs count should incrase by 1 to %d, instead got %d",originstances.count+1,newinstances.count);
}

- (void)testInsertingBuilds
{
    NSError *error;
    NSFetchRequest *allBuilds = [[NSFetchRequest alloc] init];
    [allBuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allBuilds setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    [NSEntityDescription insertNewObjectForEntityForName:@"Build" inManagedObjectContext:_context];
    
    NSArray *newbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    XCTAssert(newbuilds.count==origbuilds.count+1, @"jobs count should incrase by 1 to %d, instead got %d",origbuilds.count+1,newbuilds.count);
}

/*
- (void)testImportAllJenkinsViews
{
    KDBJenkinsRequestHandler *requestHandler = [[KDBJenkinsRequestHandler alloc] init];
    [requestHandler importAllViews];
    XCTFail(@"Verify some shit dude");
}

- (void)testImportAllJenkinsJobsForView
{
    KDBJenkinsRequestHandler *requestHandler = [[KDBJenkinsRequestHandler alloc] init];
    [requestHandler importAllJobs];
    XCTFail(@"Verify some shit dude");
}*/

@end
