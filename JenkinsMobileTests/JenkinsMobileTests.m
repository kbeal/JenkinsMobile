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
#import "View.h"
#import "JenkinsInstance.h"
#import "Build.h"
#import "KDBJenkinsURLProtocol.h"

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
    
    [NSURLProtocol registerClass:[KDBJenkinsURLProtocol class]];
    
	[KDBJenkinsURLProtocol setDelegate:nil];
    
	[KDBJenkinsURLProtocol setCannedStatusCode:200];
	[KDBJenkinsURLProtocol setCannedHeaders:nil];
	[KDBJenkinsURLProtocol setCannedResponseData:nil];
	[KDBJenkinsURLProtocol setCannedError:nil];
    
	[KDBJenkinsURLProtocol setSupportedMethods:nil];
	[KDBJenkinsURLProtocol setSupportedSchemes:nil];
	[KDBJenkinsURLProtocol setSupportedBaseURL:nil];
    
	[KDBJenkinsURLProtocol setResponseDelay:0];
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

    JenkinsInstance *jinstance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:_context];
    jinstance.name = @"TestInstance";
    jinstance.url = @"http://www.google.com";
    
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:_context];
    job.name = @"TestJob";
    job.url = @"http://www.google.com";
    job.job_description = @"Test job description";
    job.rel_Job_JenkinsInstance = jinstance;
    
    if (![_context save:&error]) {
        XCTFail(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *newjobs = [_context executeFetchRequest:allJobs error:&error];
    
    XCTAssert(newjobs.count==origjobs.count+1, @"jobs count should incrase by 1 to %d, instead got %d",origjobs.count+1,newjobs.count);
    XCTAssert([jinstance rel_Jobs].count==1, @"jenkins instance's job count should be 1, instead got %d",[jinstance rel_Jobs].count);
}


- (void)testInsertingViews
{
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origviews = [_context executeFetchRequest:allViews error:&error];
    
    JenkinsInstance *jinstance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:_context];
    jinstance.name = @"TestInstance";
    jinstance.url = @"http://www.google.com";
    
    
    
    View *view = [NSEntityDescription insertNewObjectForEntityForName:@"View" inManagedObjectContext:_context];
    view.rel_View_JenkinsInstance = jinstance;
    view.name = @"TestView";
    view.url = @"http://www.google.com";
    
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:_context];
    job.name = @"TestJob";
    job.url = @"http://www.google.com";
    job.job_description = @"Test job description";
    job.rel_Job_JenkinsInstance = jinstance;
    [view addRel_View_JobsObject:job];
    
    if (![_context save:&error]) {
        XCTFail(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *newviews = [_context executeFetchRequest:allViews error:&error];
    
    XCTAssert(newviews.count==origviews.count+1, @"views count should incrase by 1 to %d, instead got %d",origviews.count+1,newviews.count);
    XCTAssert([view rel_View_Jobs].count==1, @"jobs count should be 1, instead it is %d",[view rel_View_Jobs].count);
    XCTAssert([job rel_Job_View].count==1, @"job's view count should be 1, instead it is %d",[job rel_Job_View].count);
    XCTAssert([jinstance rel_Views].count==1, @"jenkins instance's view count should be 1, instead it is %d",[jinstance rel_Views].count);
}


- (void)testInsertingJenkinsInstances
{
    NSError *error;
    NSFetchRequest *allInstances = [[NSFetchRequest alloc] init];
    [allInstances setEntity:[NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:_context]];
    [allInstances setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *originstances = [_context executeFetchRequest:allInstances error:&error];
    
    JenkinsInstance *jinstance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:_context];
    jinstance.name = @"TestInstance";
    jinstance.url = @"http://www.google.com";
    if (![_context save:&error]) {
        XCTFail(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *newinstances = [_context executeFetchRequest:allInstances error:&error];
    
    XCTAssert(newinstances.count==originstances.count+1, @"JenkinsInstance count should incrase by 1 to %d, instead got %d",originstances.count+1,newinstances.count);
}

- (void)testInsertingBuilds
{
    NSError *error;
    NSFetchRequest *allBuilds = [[NSFetchRequest alloc] init];
    [allBuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allBuilds setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    Build *build = [NSEntityDescription insertNewObjectForEntityForName:@"Build" inManagedObjectContext:_context];
    
    JenkinsInstance *jinstance = [NSEntityDescription insertNewObjectForEntityForName:@"JenkinsInstance" inManagedObjectContext:_context];
    jinstance.name = @"TestInstance";
    jinstance.url = @"http://www.google.com";
    
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:_context];
    job.name = @"TestJob";
    job.url = @"http://www.google.com";
    job.job_description = @"Test job description";
    job.rel_Job_JenkinsInstance = jinstance;
    
    build.rel_Build_Job = job;
    if (![_context save:&error]) {
        XCTFail(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *newbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    XCTAssert(newbuilds.count==origbuilds.count+1, @"Build count should incrase by 1 to %d, instead got %d",origbuilds.count+1,newbuilds.count);
    XCTAssert([job rel_Job_Builds].count==1, @"Job's build count should be 1, instead got %d",[job rel_Job_Builds].count);
}


- (void)testImportAllJenkinsViews
{
    KDBJenkinsRequestHandler *requestHandler = [[KDBJenkinsRequestHandler alloc] init];
    [requestHandler importAllViews];
    
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *views = [_context executeFetchRequest:allViews error:&error];
    XCTAssert(views.count==4, @"view count should be 4, instead got %d", views.count);
}

- (void)testKDBJenkinsURLProtocol
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
    id requestObject = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:1], [NSNumber numberWithInt:2], nil], @"array",
                        @"hello", @"string",
                        nil];
    
	NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestObject options:0 error:nil];
    [KDBJenkinsURLProtocol setCannedResponseData:requestData];
    
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
	id responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
    
    XCTAssertNotNil(responseObject, @"no canned response from http request");
    XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]], @"canned response has wrong format (nont dictionary)");
}

/*
- (void)testImportAllJenkinsJobsForView
{
    KDBJenkinsRequestHandler *requestHandler = [[KDBJenkinsRequestHandler alloc] init];
    [requestHandler importAllJobs];
    XCTFail(@"Verify some shit dude");
}*/

@end
