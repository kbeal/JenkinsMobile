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

@interface JenkinsMobileTests : XCTestCase
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) JenkinsInstance *jinstance;

@end

@implementation JenkinsMobileTests

- (void)setUp
{
    [super setUp];

    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles: nil];
    NSPersistentStoreCoordinator *coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
    [coord addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    _context = [[NSManagedObjectContext alloc] init];
    [_context setPersistentStoreCoordinator: coord];
    
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"current", nil];
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://tomcat:8080/",[NSNumber numberWithBool:YES], nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    _jinstance = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    [self deleteAllBuilds];
    [self deleteAllJobs];
    [self deleteAllViews];
    [self deleteAllJenkinsInstances];
    [super tearDown];
}

- (void)testInsertingJobs
{
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origjobs = [_context executeFetchRequest:allJobs error:&error];\
    
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:_context];
    job.name = @"TestJob";
    job.url = @"http://www.google.com";
    job.job_description = @"Test job description";
    job.color = @"color";
    job.rel_Job_JenkinsInstance = _jinstance;
    
    if (![_context save:&error]) {
        XCTFail(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *newjobs = [_context executeFetchRequest:allJobs error:&error];
    
    XCTAssert(newjobs.count==origjobs.count+1, @"jobs count should incrase by 1 to %d, instead got %d",origjobs.count+1,newjobs.count);
    XCTAssert([_jinstance rel_Jobs].count==1, @"jenkins instance's job count should be 1, instead got %d",[_jinstance rel_Jobs].count);
}


- (void)testInsertingViews
{
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origviews = [_context executeFetchRequest:allViews error:&error];
    
    View *view = [NSEntityDescription insertNewObjectForEntityForName:@"View" inManagedObjectContext:_context];
    view.rel_View_JenkinsInstance = _jinstance;
    view.name = @"TestView";
    view.url = @"http://www.google.com";
    
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:_context];
    job.name = @"TestJob";
    job.url = @"http://www.google.com";
    job.job_description = @"Test job description";
    job.rel_Job_JenkinsInstance = _jinstance;
    job.color = @"blue";
    [view addRel_View_JobsObject:job];
    
    if (![_context save:&error]) {
        XCTFail(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *newviews = [_context executeFetchRequest:allViews error:&error];
    
    XCTAssert(newviews.count==origviews.count+1, @"views count should incrase by 1 to %d, instead got %d",origviews.count+1,newviews.count);
    XCTAssert([view rel_View_Jobs].count==1, @"jobs count should be 1, instead it is %d",[view rel_View_Jobs].count);
    XCTAssert([job rel_Job_View].count==1, @"job's view count should be 1, instead it is %d",[job rel_Job_View].count);
    XCTAssert([_jinstance rel_Views].count==1, @"jenkins instance's view count should be 1, instead it is %d",[_jinstance rel_Views].count);
}

- (void)testInsertingBuilds
{
    NSError *error;
    NSFetchRequest *allBuilds = [[NSFetchRequest alloc] init];
    [allBuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allBuilds setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    Build *build = [NSEntityDescription insertNewObjectForEntityForName:@"Build" inManagedObjectContext:_context];
    
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:_context];
    job.name = @"TestJob";
    job.url = @"http://www.google.com";
    job.job_description = @"Test job description";
    job.color = @"blue";
    job.rel_Job_JenkinsInstance = _jinstance;
    
    build.rel_Build_Job = job;
    if (![_context save:&error]) {
        XCTFail(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *newbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    XCTAssert(newbuilds.count==origbuilds.count+1, @"Build count should incrase by 1 to %d, instead got %d",origbuilds.count+1,newbuilds.count);
    XCTAssert([job rel_Job_Builds].count==1, @"Job's build count should be 1, instead got %d",[job rel_Job_Builds].count);
}

- (void)testCreateViewWithValues
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",jobs,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];

    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context forJenkinsInstance:_jinstance];
    
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *views = [_context executeFetchRequest:allViews error:&error];
    
    XCTAssert([view.name isEqualToString:@"test1"], @"view name wrong");
    XCTAssert([view.url isEqualToString:@"url1"], @"view name wrong");
    XCTAssert(view.rel_View_Jobs.count==1, @"view's job count should be 1, got %d instead",view.rel_View_Jobs.count);
    XCTAssert(views.count==1, @"view count should be 4, instead got %d", views.count);
    
}

- (void)testPersistViewsToLocalStorage
{
    //pass an nsarray of views to KDBJenkinsRequestHandler.persistViewsToLocalStorage
    KDBJenkinsRequestHandler *jenkins = [[KDBJenkinsRequestHandler alloc] initWithManagedObjectContext:_context];
    
    NSArray *views = [NSArray arrayWithObjects: [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"test1",@"url1", nil] forKeys:[NSArray arrayWithObjects:@"name",@"url", nil]],  [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"test2",@"url2", nil] forKeys:[NSArray arrayWithObjects:@"name",@"url", nil]],  [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"test3",@"url3", nil] forKeys:[NSArray arrayWithObjects:@"name",@"url", nil]],  [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"test4",@"url4", nil] forKeys:[NSArray arrayWithObjects:@"name",@"url", nil]], nil ];
    
    [jenkins persistViewsToLocalStorage: views forJenkinsInstance:_jinstance];
    
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedviews = [_context executeFetchRequest:allViews error:&error];
    XCTAssert(fetchedviews.count==4, @"view count should be 4, instead got %d", fetchedviews.count);
}

- (void)testCreateJobWithValues
{
    
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"color",@"url",@"buildable",@"concurrentBuild",@"displayName",@"firstBuild",@"lastBuild",@"lastCompletedBuild",@"lastFailedBuild",@"lastStableBuild",@"lastSuccessfulBuild",@"lastUnstableBuild",@"lastUnsuccessfulBuild",@"nextBuildNumber",@"inQueue",@"description",@"keepDependencies",nil ];
    
    NSArray *jobValues = [NSArray arrayWithObjects:@"Test1",@"blue",@"http://tomcat:8080/view/JobsView1/job/Job1/",@"true",@"false",@"Test1",[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:2],@"false",@"Test1 Description",@"false", nil];
    
    Job *job = [Job createJobWithValues:[NSDictionary dictionaryWithObjects:jobValues forKeys:jobKeys] inManagedObjectContext:_context forJenkinsInstance:_jinstance];
    
    XCTAssert([job.name isEqualToString:@"Test1"], @"job name should be Test1, is actually %@",job.name);
    XCTAssert([job.color isEqualToString:@"blue"], @"job color is wrong");
    XCTAssert([job.url isEqualToString:@"http://tomcat:8080/view/JobsView1/job/Job1/"], @"job url is wrong, is actually %@",job.url);
    XCTAssertEqualObjects(job.buildable, [NSNumber numberWithBool:YES], @"job should be buildable, is not");
    XCTAssertEqualObjects(job.concurrentBuild, [NSNumber numberWithBool:NO], @"job should be a concurrent build is actually %@", [job.concurrentBuild stringValue]);
    XCTAssertEqual(job.displayName, @"Test1", @"display name is wrong, is actually %@", job.displayName);
    XCTAssertEqualObjects(job.firstBuild, [NSNumber numberWithInt:1], @"first build number is wrong");
    XCTAssertEqualObjects(job.lastBuild, [NSNumber numberWithInt:1], @"last build number is wrong");
    XCTAssertEqualObjects(job.lastCompletedBuild, [NSNumber numberWithInt:1], @"last complete build number is wrong");
    XCTAssertEqualObjects(job.lastFailedBuild, [NSNumber numberWithInt:1], @"last fail build number is wrong");
    XCTAssertEqualObjects(job.lastStableBuild, [NSNumber numberWithInt:1], @"last stable build number is wrong");
    XCTAssertEqualObjects(job.lastSuccessfulBuild, [NSNumber numberWithInt:1], @"last successful build number is wrong");
    XCTAssertEqualObjects(job.lastUnstableBuild, [NSNumber numberWithInt:1], @"last unstable build number is wrong");
    XCTAssertEqualObjects(job.lastUnsuccessfulBuild, [NSNumber numberWithInt:1], @"last unsuccessful build number is wrong");
    XCTAssertEqualObjects(job.nextBuildNumber, [NSNumber numberWithInt:2], @"next build number is wrong");
    XCTAssertEqualObjects(job.inQueue, [NSNumber numberWithBool:NO], @"in queue should be false, is actually %@", [job.inQueue stringValue]);
    XCTAssertEqual(job.job_description, @"Test1 Description", @"job description is wrong is actually %@", job.job_description);
    XCTAssertEqualObjects(job.keepDependencies, [NSNumber numberWithBool:NO], @"keep dependencies should be false, is actually %@", [job.keepDependencies stringValue]);
    XCTAssertNotNil(job.rel_Job_JenkinsInstance, @"jenkins instance is null");
}

- (void)testCreateJobWithMinimalValues
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    Job *job = [Job createJobWithValues:jobvalues inManagedObjectContext:_context forJenkinsInstance:_jinstance];
    
    XCTAssert([job.name isEqualToString:@"Job1"], @"job name should be Job1, is actually %@",job.name);
    XCTAssert([job.color isEqualToString:@"blue"], @"job color is wrong");
    XCTAssert([job.url isEqualToString:@"http://www.google.com"], @"job url is wrong, is actually %@",job.url);
}

- (void)testPersistJobsToLocalStorage
{
    //pass an nsarray of views to KDBJenkinsRequestHandler.persistViewsToLocalStorage
    KDBJenkinsRequestHandler *jenkins = [[KDBJenkinsRequestHandler alloc] initWithManagedObjectContext:_context];
    
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"color",@"url",@"buildable",@"concurrentBuild",@"displayName",@"firstBuild",@"lastBuild",@"lastCompletedBuild",@"lastFailedBuild",@"lastStableBuild",@"lastSuccessfulBuild",@"lastUnstableBuild",@"lastUnsuccessfulBuild",@"nextBuildNumber",@"inQueue",@"description",@"keepDependencies",nil ];
    
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Test1",@"blue",@"http://tomcat:8080/view/JobsView1/job/Job1/",@"true",@"false",@"Test1",[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:2],@"false",@"Test1 Description",@"false", nil];
    
    NSArray *jobValues2 = [NSArray arrayWithObjects:@"Test2",@"blue",@"http://tomcat:8080/view/JobsView1/job/Job2/",@"true",@"false",@"Test2",[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:2],@"false",@"Test2 Description",@"false", nil];
    
    NSArray *jobValues3 = [NSArray arrayWithObjects:@"Test3",@"blue",@"http://tomcat:8080/view/JobsView1/job/Job3/",@"true",@"false",@"Test3",[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:2],@"false",@"Test3 Description",@"false", nil];
    
    
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSDictionary *job2 = [NSDictionary dictionaryWithObjects:jobValues2 forKeys:jobKeys];
    NSDictionary *job3 = [NSDictionary dictionaryWithObjects:jobValues3 forKeys:jobKeys];

    [jenkins persistJobsToLocalStorage: [NSArray arrayWithObjects:job1,job2,job3, nil] forJenkinsInstance:_jinstance];
    
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedjobs = [_context executeFetchRequest:allJobs error:&error];
    XCTAssert(fetchedjobs.count==3, @"view count should be 3, instead got %d", fetchedjobs.count);
}

- (void) testCreateJenkinsInstance
{
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://ci.kylebeal.com",[NSNumber numberWithBool:YES], nil];
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"current", nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    JenkinsInstance *instance = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    
    XCTAssert([instance.name isEqualToString:@"TestInstance"], @"name is wrong");
    XCTAssert([instance.url isEqualToString:@"http://ci.kylebeal.com"], @"url is wrong");
    XCTAssert([instance.current isEqualToNumber:[NSNumber numberWithBool:YES]], @"not current instance");
}

- (void) testGetCurrentJenkinsInstance
{
    JenkinsInstance *current = [JenkinsInstance getCurrentJenkinsInstanceFromManagedObjectContext:_context];
    XCTAssertEqualObjects(current, _jinstance, @"instances aren't equal");
}

- (void) testNoDuplicateJenkinsInstances
{
    NSArray *values1 = [NSArray arrayWithObjects:@"TestInstance",@"http://ci.kylebeal.com",[NSNumber numberWithBool:YES], nil];
    NSArray *values2 = [NSArray arrayWithObjects:@"TestInstance2",@"http://ci.kylebeal.com",[NSNumber numberWithBool:NO], nil];
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"current", nil];

    NSDictionary *instancevalues1 = [NSDictionary dictionaryWithObjects:values1 forKeys:keys];
    NSDictionary *instancevalues2 = [NSDictionary dictionaryWithObjects:values2 forKeys:keys];
    
    [JenkinsInstance createJenkinsInstanceWithValues:instancevalues1 inManagedObjectContext:_context];
    [JenkinsInstance createJenkinsInstanceWithValues:instancevalues2 inManagedObjectContext:_context];
    
    NSError *error;
    NSFetchRequest *allJInstances = [[NSFetchRequest alloc] init];
    [allJInstances setEntity:[NSEntityDescription entityForName:@"JenkinsInstance" inManagedObjectContext:_context]];
    [allJInstances setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedinstances = [_context executeFetchRequest:allJInstances error:&error];
    
    XCTAssert(fetchedinstances.count==2,@"too many jenkins instances, should be 2, have %d",fetchedinstances.count);
}

- (void) testUpdatingJob
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSArray *values2 = [NSArray arrayWithObjects:@"Job1Test",@"http://www.google.com",@"green",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSDictionary *jobvalues2 = [NSDictionary dictionaryWithObjects:values2 forKeys:keys];
    
    [Job createJobWithValues:jobvalues inManagedObjectContext:_context forJenkinsInstance:_jinstance];
    [Job createJobWithValues:jobvalues2 inManagedObjectContext:_context forJenkinsInstance:_jinstance];
    
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setPredicate:[NSPredicate predicateWithFormat:@"url = %@", @"http://www.google.com"]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedjobs = [_context executeFetchRequest:allJobs error:&error];
    Job *fetchedjob = [fetchedjobs lastObject];
    
    XCTAssert(fetchedjobs.count==1, @"wrong number of fetched jobs");
    XCTAssert([fetchedjob.name isEqualToString:@"Job1Test"], @"job name is wrong");
    XCTAssert([fetchedjob.url isEqualToString:@"http://www.google.com"], @"job url is wrong");
    XCTAssert([fetchedjob.color isEqualToString:@"green"], @"job color is wrong");
}

- (void) testUpdatingView
{
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property", nil];
    NSArray *viewValues1 = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",nil];
    NSArray *viewValues2 = [NSArray arrayWithObjects:@"test2",@"url1",@"descriptiontest2",@"",nil];
    NSDictionary *values1 = [NSDictionary dictionaryWithObjects:viewValues1 forKeys:viewKeys];
    NSDictionary *values2 = [NSDictionary dictionaryWithObjects:viewValues2 forKeys:viewKeys];
    
    
    [View createViewWithValues:values1 inManagedObjectContext:_context forJenkinsInstance:_jinstance];
    [View createViewWithValues:values2 inManagedObjectContext:_context forJenkinsInstance:_jinstance];
    
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setPredicate:[NSPredicate predicateWithFormat:@"url = %@", @"url1"]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedviews = [_context executeFetchRequest:allViews error:&error];
    View *fetchedview = [fetchedviews lastObject];
    
    XCTAssert(fetchedviews.count==1, @"wrong number of fetched views");
    XCTAssert([fetchedview.name isEqualToString:@"test2"], @"view name is wrong");
    XCTAssert([fetchedview.url isEqualToString:@"url1"], @"view url is wrong");
    XCTAssert([fetchedview.view_description isEqualToString:@"descriptiontest2"], @"view description is wrong");
}

- (void) deleteAllRecordsForEntity: (NSString *) entityName
{
    NSFetchRequest * allRecords = [[NSFetchRequest alloc] init];
    [allRecords setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_context]];
    [allRecords setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * records = [_context executeFetchRequest:allRecords error:&error];


    for (NSManagedObject *obj in records) {
        [_context deleteObject:obj];
    }
    NSError *saveError = nil;
    [_context save:&saveError];
}

- (void) deleteAllJobs
{
    [self deleteAllRecordsForEntity:@"Job"];
}

- (void) deleteAllViews
{
    [self deleteAllRecordsForEntity:@"View"];
}

- (void) deleteAllJenkinsInstances
{
    [self deleteAllRecordsForEntity:@"JenkinsInstance"];
}

- (void) deleteAllBuilds
{
    [self deleteAllRecordsForEntity:@"Build"];
}

@end
