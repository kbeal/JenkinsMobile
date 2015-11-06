//
//  JenkinsMobileTests.m
//  JenkinsMobileTests
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Job+More.h"
#import "View+More.h"
#import "JenkinsInstance+More.h"
#import "Build+More.h"
#import "Constants.h"
#import "ActiveConfiguration+More.h"
#import "JenkinsMobileTests-Swift.h"
#import "JenkinsMobile-Swift.h"

@interface JenkinsMobileTests : XCTestCase
@property (nonatomic, strong) DataManager *datamgr;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) JenkinsInstance *jinstance;

@end

@implementation JenkinsMobileTests

- (void)setUp
{
    [super setUp];
    self.datamgr = [DataManager sharedInstance];
    self.context = self.datamgr.masterMOC;
    NSArray *viewKeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey, nil];
    NSArray *priViewVals = [NSArray arrayWithObjects:@"All",@"http://tomcat:8080/", nil];
    NSDictionary *primaryView = [NSDictionary dictionaryWithObjects:priViewVals forKeys:viewKeys];
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"current",JenkinsInstanceEnabledKey,JenkinsInstancePrimaryViewKey, nil];
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://tomcat:8080/",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],primaryView, nil];
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
    
    XCTAssert(newjobs.count==origjobs.count+1, @"jobs count should incrase by 1 to %lu, instead got %lu",origjobs.count+1,(unsigned long)newjobs.count);
    XCTAssert([_jinstance rel_Jobs].count==1, @"jenkins instance's job count should be 1, instead got %lu",(unsigned long)[_jinstance rel_Jobs].count);
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
    
    XCTAssert(newviews.count==origviews.count+1, @"views count should incrase by 1 to %lu, instead got %lu",origviews.count+1,(unsigned long)newviews.count);
    XCTAssert([view rel_View_Jobs].count==1, @"jobs count should be 1, instead it is %lu",(unsigned long)[view rel_View_Jobs].count);
    XCTAssert([_jinstance rel_Views].count==1, @"jenkins instance's view count should be 1, instead it is %lu",(unsigned long)[_jinstance rel_Views].count);
}

- (void)testInsertingBuilds
{
    NSError *error;
    NSFetchRequest *allBuilds = [[NSFetchRequest alloc] init];
    [allBuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allBuilds setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *origbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    Build *build = [NSEntityDescription insertNewObjectForEntityForName:@"Build" inManagedObjectContext:_context];
    build.url = @"http://www.google.com";
    build.number = [NSNumber numberWithInt:100];
    
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
    
    XCTAssert(newbuilds.count==origbuilds.count+1, @"Build count should incrase by 1 to %luu, instead got %lu",origbuilds.count+1,(unsigned long)newbuilds.count);
}

- (void) testFindJobsToInsertFromBatch
{
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey,nil];
    NSArray *jobVals1 = [NSArray arrayWithObjects:@"Job1",@"http://localhost:8080/job/Job1/",@"blue",nil];
    NSArray *jobVals2 = [NSArray arrayWithObjects:@"Job2",@"http://localhost:8080/job/Job2/",@"blue",nil];
    NSArray *jobVals3 = [NSArray arrayWithObjects:@"Job3",@"http://localhost:8080/job/Job3/",@"blue",nil];
    NSArray *jobVals4 = [NSArray arrayWithObjects:@"Job4",@"http://localhost:8080/job/Job2/",@"blue",nil];
    NSArray *jobVals5 = [NSArray arrayWithObjects:@"Job5",@"http://localhost:8080/job/Job3/",@"blue",nil];
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"current",JenkinsInstanceEnabledKey,JenkinsInstanceJobsKey, nil];
    NSDictionary *jobDict1 = [NSDictionary dictionaryWithObjects:jobVals1 forKeys:jobKeys];
    NSDictionary *jobDict2 = [NSDictionary dictionaryWithObjects:jobVals2 forKeys:jobKeys];
    NSDictionary *jobDict3 = [NSDictionary dictionaryWithObjects:jobVals3 forKeys:jobKeys];
    NSDictionary *jobDict4 = [NSDictionary dictionaryWithObjects:jobVals4 forKeys:jobKeys];
    NSDictionary *jobDict5 = [NSDictionary dictionaryWithObjects:jobVals5 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3, nil];
    NSArray *jobs2 = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3,jobDict4,jobDict5, nil];

    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://tomcat:8080/",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],jobs, nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    JenkinsInstance *ji = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    
    XCTAssertEqual(ji.rel_Jobs.count, 3);
    
    NSSet *newJobs = [ji findJobsToInsertFromBatch:jobs2];
    
    XCTAssertEqual(newJobs.count, 2);
}

- (void) testInsertJobsBatchJenkinsInstance
{
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey,ViewJenkinsInstanceKey,nil];
    NSArray *jobVals1 = [NSArray arrayWithObjects:@"Job1",@"http://localhost:8080/job/Job1/",@"blue",nil];
    NSArray *jobVals2 = [NSArray arrayWithObjects:@"Job2",@"http://localhost:8080/job/Job2/",@"blue",nil];
    NSArray *jobVals3 = [NSArray arrayWithObjects:@"Job3",@"http://localhost:8080/job/Job3/",@"blue",nil];
    NSArray *jobVals4 = [NSArray arrayWithObjects:@"Job4",@"http://localhost:8080/job/Job2/",@"blue",nil];
    NSArray *jobVals5 = [NSArray arrayWithObjects:@"Job5",@"http://localhost:8080/job/Job3/",@"blue",nil];
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"current",JenkinsInstanceEnabledKey,JenkinsInstanceJobsKey, nil];
    NSDictionary *jobDict1 = [NSDictionary dictionaryWithObjects:jobVals1 forKeys:jobKeys];
    NSDictionary *jobDict2 = [NSDictionary dictionaryWithObjects:jobVals2 forKeys:jobKeys];
    NSDictionary *jobDict3 = [NSDictionary dictionaryWithObjects:jobVals3 forKeys:jobKeys];
    NSDictionary *jobDict4 = [NSDictionary dictionaryWithObjects:jobVals4 forKeys:jobKeys];
    NSDictionary *jobDict5 = [NSDictionary dictionaryWithObjects:jobVals5 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3, nil];
    NSArray *jobs2 = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3,jobDict4,jobDict5, nil];

    
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://tomcat:8080/",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],jobs, nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    JenkinsInstance *ji = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    
    XCTAssertEqual(ji.rel_Jobs.count, 3);
    
    NSArray *viewVals = [NSArray arrayWithObjects:@"TestView",@"http://localhost:8080/view/TestView/", ji, nil];
    NSDictionary *viewDict = [NSDictionary dictionaryWithObjects:viewVals forKeys:viewKeys];
    View *view = [View createViewWithValues:viewDict inManagedObjectContext:_context];
    [ji insertJobBatch:jobs2 forView:view];
    
    XCTAssertEqual(ji.rel_Jobs.count, 5);
}

- (void) testInsertJobBatchView
{
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey,JobJenkinsInstanceKey,nil];
    NSArray *jiKeys = [NSArray arrayWithObjects:@"name",@"url",@"current",JenkinsInstanceEnabledKey,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey,ViewJenkinsInstanceKey,nil];
    NSArray *jobVals1 = [NSArray arrayWithObjects:@"Job1",@"http://localhost:8080/job/Job1/",@"blue",self.jinstance,nil];
    NSArray *jobVals2 = [NSArray arrayWithObjects:@"Job2",@"http://localhost:8080/job/Job2/",@"blue",self.jinstance,nil];
    NSArray *jobVals3 = [NSArray arrayWithObjects:@"Job3",@"http://localhost:8080/job/Job3/",@"blue",self.jinstance,nil];
    NSDictionary *jobDict1 = [NSDictionary dictionaryWithObjects:jobVals1 forKeys:jobKeys];
    NSDictionary *jobDict2 = [NSDictionary dictionaryWithObjects:jobVals2 forKeys:jobKeys];
    NSDictionary *jobDict3 = [NSDictionary dictionaryWithObjects:jobVals3 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3, nil];
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://tomcat:8080/",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES], nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:jiKeys];
    JenkinsInstance *ji = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    
    NSArray *viewVals = [NSArray arrayWithObjects:@"TestView",@"http://localhost:8080/view/TestView/", ji, nil];
    NSDictionary *viewDict = [NSDictionary dictionaryWithObjects:viewVals forKeys:viewKeys];
    View *view = [View createViewWithValues:viewDict inManagedObjectContext:_context];
    
    for (NSDictionary *job in jobs) {
        [Job createJobWithValues:job inManagedObjectContext:_context];
    }
    [view insertJobBatch:jobs];
    
    XCTAssertEqual(view.rel_View_Jobs.count, 3);
}

- (void) testFetchRelatedJobsWithNames
{
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey,JobJenkinsInstanceKey,nil];
    NSArray *jiKeys = [NSArray arrayWithObjects:@"name",@"url",@"current",JenkinsInstanceEnabledKey,JenkinsInstanceJobsKey, nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey,ViewJenkinsInstanceKey,nil];
    NSArray *jobnames = [NSArray arrayWithObjects:@"Job1",@"Job2",@"Job4",@"Job5", nil];
    NSArray *jobVals1 = [NSArray arrayWithObjects:@"Job1",@"http://localhost:8080/job/Job1/",@"blue",self.jinstance,nil];
    NSArray *jobVals2 = [NSArray arrayWithObjects:@"Job2",@"http://localhost:8080/job/Job2/",@"blue",self.jinstance,nil];
    NSArray *jobVals3 = [NSArray arrayWithObjects:@"Job3",@"http://localhost:8080/job/Job3/",@"blue",self.jinstance,nil];
    NSArray *jobVals4 = [NSArray arrayWithObjects:@"Job2",@"http://localhost:8080/job/Job4/",@"blue",self.jinstance,nil];
    NSArray *jobVals5 = [NSArray arrayWithObjects:@"Job3",@"http://localhost:8080/job/Job5/",@"blue",self.jinstance,nil];
    NSDictionary *jobDict1 = [NSDictionary dictionaryWithObjects:jobVals1 forKeys:jobKeys];
    NSDictionary *jobDict2 = [NSDictionary dictionaryWithObjects:jobVals2 forKeys:jobKeys];
    NSDictionary *jobDict3 = [NSDictionary dictionaryWithObjects:jobVals3 forKeys:jobKeys];
    NSDictionary *jobDict4 = [NSDictionary dictionaryWithObjects:jobVals4 forKeys:jobKeys];
    NSDictionary *jobDict5 = [NSDictionary dictionaryWithObjects:jobVals5 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3, nil];
    NSArray *jobs2 = [NSArray arrayWithObjects:jobDict4,jobDict5,nil];
    
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://tomcat:8080/",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],jobs2, nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:jiKeys];
    JenkinsInstance *ji = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    
    NSArray *viewVals = [NSArray arrayWithObjects:@"TestView",@"http://localhost:8080/view/TestView/", ji, nil];
    NSDictionary *viewDict = [NSDictionary dictionaryWithObjects:viewVals forKeys:viewKeys];
    View *view = [View createViewWithValues:viewDict inManagedObjectContext:_context];
    
    for (NSDictionary *job in jobs) {
        Job *jobmo = [Job createJobWithValues:job inManagedObjectContext:_context];
        [view addRel_View_JobsObject:jobmo];
    }
    XCTAssertEqual(view.rel_View_Jobs.count, 3);
    XCTAssertEqual(ji.rel_Jobs.count, 2);
    
    NSArray *relatedJobs = [view fetchRelatedJobsWithNames:jobnames];
    XCTAssertEqual(relatedJobs.count, 2);
}

//- (void) testFindJobsToRelateFromBatch
//{
//    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey,JobJenkinsInstanceKey,nil];
//    NSArray *viewKeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey,ViewJenkinsInstanceKey,nil];
//    NSArray *jiKeys = [NSArray arrayWithObjects:@"name",@"url",@"current",JenkinsInstanceEnabledKey, nil];
//    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://tomcat:8080/",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES], nil];
//    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:jiKeys];
//    JenkinsInstance *ji = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
//    NSArray *jobVals1 = [NSArray arrayWithObjects:@"Job1",@"http://localhost:8080/job/Job1/",@"blue",ji,nil];
//    NSArray *jobVals2 = [NSArray arrayWithObjects:@"Job2",@"http://localhost:8080/job/Job2/",@"blue",ji,nil];
//    NSArray *jobVals3 = [NSArray arrayWithObjects:@"Job3",@"http://localhost:8080/job/Job3/",@"blue",ji,nil];
//    NSArray *jobVals4 = [NSArray arrayWithObjects:@"Job4",@"http://localhost:8080/job/Job2/",@"blue",ji,nil];
//    NSArray *jobVals5 = [NSArray arrayWithObjects:@"Job5",@"http://localhost:8080/job/Job3/",@"blue",ji,nil];
//    NSDictionary *jobDict1 = [NSDictionary dictionaryWithObjects:jobVals1 forKeys:jobKeys];
//    NSDictionary *jobDict2 = [NSDictionary dictionaryWithObjects:jobVals2 forKeys:jobKeys];
//    NSDictionary *jobDict3 = [NSDictionary dictionaryWithObjects:jobVals3 forKeys:jobKeys];
//    NSDictionary *jobDict4 = [NSDictionary dictionaryWithObjects:jobVals4 forKeys:jobKeys];
//    NSDictionary *jobDict5 = [NSDictionary dictionaryWithObjects:jobVals5 forKeys:jobKeys];
//    NSArray *jobs = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3, nil];
//    NSArray *jobs2 = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3,jobDict4,jobDict5, nil];
//    NSMutableArray *jobsBatch = [NSMutableArray arrayWithCapacity:jobs2.count];
//    
//    Job *jobmo4 = [Job createJobWithValues:jobDict4 inManagedObjectContext:_context];
//    Job *jobmo5 = [Job createJobWithValues:jobDict5 inManagedObjectContext:_context];
//    [jobsBatch addObject:jobmo4];
//    [jobsBatch addObject:jobmo5];
//    
//    NSArray *viewVals = [NSArray arrayWithObjects:@"TestView",@"http://localhost:8080/view/TestView/", self.jinstance, nil];
//    NSDictionary *viewDict = [NSDictionary dictionaryWithObjects:viewVals forKeys:viewKeys];
//    View *view = [View createViewWithValues:viewDict inManagedObjectContext:_context];
//    
//    for (NSDictionary *job in jobs) {
//        Job *jobmo = [Job createJobWithValues:job inManagedObjectContext:_context];
//        [view addRel_View_JobsObject:jobmo];
//    }
//    XCTAssertEqual(view.rel_View_Jobs.count, 3);
//    XCTAssertEqual(ji.rel_Jobs.count, 5);
//    
//    NSArray *jobsToRelate = [view findJobsToRelateFromBatch:jobsBatch];
//    XCTAssertEqual(jobsToRelate.count, 2);
//
//}

- (void) testFetchJobsWithNamesFromJenkinsInstance
{
    int jobscount = 20;
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey,nil];
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"current",JenkinsInstanceEnabledKey,JenkinsInstanceJobsKey, nil];
    NSMutableArray *jobs = [NSMutableArray arrayWithCapacity:jobscount];
    NSMutableArray *jobnames = [NSMutableArray arrayWithCapacity:jobscount];
    
    for (int i=0; i<jobscount; i++) {
        NSString *jobname = [[NSUUID UUID] UUIDString];
        [jobnames addObject:jobname];
        NSArray *jobValues = [NSArray arrayWithObjects:jobname,@"blue",@"http://www.google.com", nil];
        NSDictionary *job = [NSDictionary dictionaryWithObjects:jobValues forKeys:jobKeys];
        [jobs addObject:job];
    }
    
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://tomcat:8080/",[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],jobs, nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    JenkinsInstance *ji = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    
    // add one more random jobname to the array that won't be created as an actual Job and tied to the view.
    [jobnames addObject:[[NSUUID UUID] UUIDString]];
    
    NSArray *jobsWithNames = [Job fetchJobsWithNames:jobnames inManagedObjectContext:_context andJenkinsInstance:ji];
    
    XCTAssertEqual(ji.rel_Jobs.count, 20);
    XCTAssertEqual(jobnames.count, 21);
    XCTAssertEqual(jobsWithNames.count, 20);
}

- (void) testRemoveJobsFromBatch
{
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey,nil];
    NSArray *jobVals1 = [NSArray arrayWithObjects:@"Job1",@"http://localhost:8080/job/Job1/",@"blue",nil];
    NSArray *jobVals2 = [NSArray arrayWithObjects:@"Job2",@"http://localhost:8080/job/Job2/",@"blue",nil];
    NSArray *jobVals3 = [NSArray arrayWithObjects:@"Job3",@"http://localhost:8080/job/Job3/",@"blue",nil];
    NSDictionary *jobDict1 = [NSDictionary dictionaryWithObjects:jobVals1 forKeys:jobKeys];
    NSDictionary *jobDict2 = [NSDictionary dictionaryWithObjects:jobVals2 forKeys:jobKeys];
    NSDictionary *jobDict3 = [NSDictionary dictionaryWithObjects:jobVals3 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:jobDict1,jobDict2,jobDict3, nil];
    NSArray *jobNames = [NSArray arrayWithObjects:@"Job1",@"Job2", nil];
    NSSet *filteredJobs = [Job removeJobs:jobNames fromBatch:[NSSet setWithArray:jobs]];
    
    XCTAssertEqual(filteredJobs.count, 1);
    XCTAssertEqual([[filteredJobs anyObject] objectForKey:JobNameKey], @"Job3");
}

- (void) testSplitViewJobsArrayIntoBatches
{
    int jobscount = 20500;
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey,ViewJobsKey,ViewJenkinsInstanceKey, nil];
    NSMutableArray *jobs = [NSMutableArray arrayWithCapacity:jobscount];
    NSArray *viewValues = [NSArray arrayWithObjects:@"TestView",@"http://localhost:8080/view/TestView/",jobs,self.jinstance, nil];
    NSDictionary *viewDict = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    View *view = [View createViewWithValues:viewDict inManagedObjectContext:_context];
    
    for (int i=0; i<jobscount; i++) {
        NSArray *jobValues = [NSArray arrayWithObjects:[[NSUUID UUID] UUIDString],@"blue",@"http://www.google.com", nil];
        NSDictionary *job = [NSDictionary dictionaryWithObjects:jobValues forKeys:jobKeys];
        [jobs addObject:job];
    }
    
    NSArray *batches = [view splitJobsArrayIntoBatches:jobs];
    
    XCTAssertEqual(view.name, @"TestView");
    XCTAssertEqual(batches.count, 21);
    XCTAssertEqual([[batches objectAtIndex:0] count], 1000);
    XCTAssertEqual([[batches objectAtIndex:20] count], 500);
    XCTAssertTrue([[[batches objectAtIndex:0] objectAtIndex:0] isKindOfClass:[NSDictionary class]]);
}

- (void)testCreateViewWithValues
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSArray *jobValues2 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSDictionary *job2 = [NSDictionary dictionaryWithObjects:jobValues2 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,job2,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs",ViewJenkinsInstanceKey, nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"All",@"http://tomcat:8080/",@"descriptiontest1",@"",jobs,_jinstance,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context];
    
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *views = [_context executeFetchRequest:allViews error:&error];
    
    XCTAssert([view.name isEqualToString:@"All"], @"view name wrong");
    XCTAssert([view.url isEqualToString:@"http://tomcat:8080/view/All/"], @"view url wrong");
    XCTAssert(view.rel_View_Jobs.count==1, @"view's job count should be 1, got %lu instead",(unsigned long)view.rel_View_Jobs.count);
    XCTAssert(views.count==1, @"view count should be 4, instead got %lu", (unsigned long)views.count);
    XCTAssert(_jinstance.rel_Jobs.count==1, @"jenkins instance's related job count should be 1, got %lu instead",(unsigned long)_jinstance.rel_Jobs.count);
    
}

- (void)testUpdateViewWithValues
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSArray *jobValues2 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSDictionary *job2 = [NSDictionary dictionaryWithObjects:jobValues2 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,job2,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs",ViewJenkinsInstanceKey, nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"All",@"http://tomcat:8080/",@"descriptiontest1",@"",jobs,_jinstance,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context];
    
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *views = [_context executeFetchRequest:allViews error:&error];
    
    XCTAssert([view.name isEqualToString:@"All"], @"view name wrong");
    XCTAssert([view.url isEqualToString:@"http://tomcat:8080/view/All/"], @"view url wrong");
    XCTAssert(view.rel_View_Jobs.count==1, @"view's job count should be 1, got %lu instead",(unsigned long)view.rel_View_Jobs.count);
    XCTAssert(views.count==1, @"view count should be 4, instead got %lu", (unsigned long)views.count);
    XCTAssert(_jinstance.rel_Jobs.count==1, @"jenkins instance's related job count should be 1, got %lu instead",(unsigned long)_jinstance.rel_Jobs.count);
    
    // change view values to have nothing for name.
    viewKeys = [NSArray arrayWithObjects:ViewPropertyKey,ViewJenkinsInstanceKey, nil];
    viewValues = [NSArray arrayWithObjects:@"what's a property?",_jinstance,nil];
    values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    [view updateValues:values];
    XCTAssert([view.name isEqualToString:@"All"], @"view name wrong");
    XCTAssert([view.property isEqualToString:@"what's a property?"], @"view property wrong");
}

- (void)testCreateJobWithValues
{
    
    NSDictionary *jobbuilddict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"number"];
    NSArray *relatedProjectsKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *upstreamProjectValues = [NSArray arrayWithObjects:@"maven-surefire",@"https://builds.apache.org/job/maven-surefire/",@"blue", nil];
    NSArray *downstreamProjectValues1 = [NSArray arrayWithObjects:@"test4commerce",@"http://www.google.com",@"green", nil];
    NSArray *downstreamProjectValues2 = [NSArray arrayWithObjects:@"test3commerce",@"http://www.yahoo.com",@"blue", nil];
    NSDictionary *upstreamProject = [NSDictionary dictionaryWithObjects:upstreamProjectValues forKeys:relatedProjectsKeys];
    NSDictionary *downstreamProject1 = [NSDictionary dictionaryWithObjects:downstreamProjectValues1 forKeys:relatedProjectsKeys];
    NSDictionary *downstreamProject2 = [NSDictionary dictionaryWithObjects:downstreamProjectValues2 forKeys:relatedProjectsKeys];
    NSArray *upstreamProjects = [NSArray arrayWithObjects:upstreamProject, nil];
    NSArray *downstreamProjects = [NSArray arrayWithObjects:downstreamProject1, downstreamProject2, nil];
    NSArray *healthReportKeys = [NSArray arrayWithObjects:@"description",@"iconUrl",@"score", nil];
    NSArray *healthReportValues = [NSArray arrayWithObjects:@"Build stability: No recent builds failed.",@"health-80plus.png",@"100", nil];
    NSDictionary *healthReport = [NSDictionary dictionaryWithObjects:healthReportValues forKeys:healthReportKeys];
    NSArray *activeConfigurationsKeys = [NSArray arrayWithObjects:ActiveConfigurationNameKey,ActiveConfigurationURLKey,ActiveConfigurationColorKey, nil];
    NSArray *activeConfigurationsValues1 = [NSArray arrayWithObjects:@"config1",@"www.config1.com",@"blue", nil];
    NSArray *activeConfigurationsValues2 = [NSArray arrayWithObjects:@"config2",@"www.config2.com",@"red", nil];
    NSDictionary *activeConfigurations1 = [NSDictionary dictionaryWithObjects:activeConfigurationsValues1 forKeys:activeConfigurationsKeys];
    NSDictionary *activeConfigurations2 = [NSDictionary dictionaryWithObjects:activeConfigurationsValues2 forKeys:activeConfigurationsKeys];
    NSArray *activeConfigurations = [NSArray arrayWithObjects:activeConfigurations1,activeConfigurations2, nil];
    UIImage *testImage = [UIImage imageNamed:@"blue.png"];
    
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"color",@"url",@"buildable",@"concurrentBuild",@"displayName",@"firstBuild",@"lastBuild",@"lastCompletedBuild",@"lastFailedBuild",@"lastStableBuild",@"lastSuccessfulBuild",@"lastUnstableBuild",@"lastUnsuccessfulBuild",@"nextBuildNumber",@"inQueue",@"description",@"keepDependencies",@"upstreamProjects",@"downstreamProjects",@"healthReport",JobActiveConfigurationsKey,JobTestResultsImageKey,nil ];
    
    NSArray *jobValues = [NSArray arrayWithObjects:@"Test1",@"blue",@"http://tomcat:8080/view/JobsView1/job/Job1/",[NSNumber numberWithInt:1],[NSNumber numberWithInt:0],@"Test1",jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,[NSNumber numberWithInt:2],[NSNumber numberWithBool:NO],@"Test1 Description",[NSNumber numberWithBool:NO],upstreamProjects,downstreamProjects,healthReport,activeConfigurations,testImage, nil];

    Job *job = [Job createJobWithValues:[NSDictionary dictionaryWithObjects:jobValues forKeys:jobKeys] inManagedObjectContext:_context];
    job.rel_Job_JenkinsInstance = _jinstance;
    [job setTestResultsImageWithImage:testImage];
    
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
    XCTAssert([job.upstreamProjects count]==1, @"wrong number of upstream projects");
    XCTAssert([job.downstreamProjects count]==2, @"wrong number of downstream projects");
    XCTAssert([[[job.upstreamProjects objectAtIndex:0] objectForKey:@"color"] isEqualToString:@"blue"], @"upstream project has wrong color");
    XCTAssert([[[job.downstreamProjects objectAtIndex:0] objectForKey:@"color"] isEqualToString:@"green"], @"downstream project1 has wrong color");
    XCTAssert([[[job.downstreamProjects objectAtIndex:1] objectForKey:@"url"] isEqualToString:@"http://www.yahoo.com"], @"downstream project2 has wrong url");
    XCTAssert([[job.healthReport objectForKey:@"iconUrl"] isEqualToString:@"health-80plus.png"], @"health report is wrong %@", [job.healthReport objectForKey:@"iconUrl"]);
    XCTAssert([job.activeConfigurations count]==2, @"wrong number of active configurations");
    XCTAssert([[[job.activeConfigurations objectAtIndex:1] objectForKey:@"color"] isEqualToString:@"red"], @"active config has wrong color %@", [[job.activeConfigurations objectAtIndex:1] objectForKey:@"color"]);
    XCTAssertTrue([job.getTestResultsImage isKindOfClass:[UIImage class]], @"%@%@",@"test results image is not UIImage, returned ",NSStringFromClass([job.getTestResultsImage class]));
    XCTAssertNotNil(job.testResultsImage, @"job's test results image is nil");
}

- (void)testCreateJobWithMinimalValues
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    Job *job = [Job createJobWithValues:jobvalues inManagedObjectContext:_context];
    
    XCTAssert([job.name isEqualToString:@"Job1"], @"job name should be Job1, is actually %@",job.name);
    XCTAssert([job.color isEqualToString:@"blue"], @"job color is wrong");
    XCTAssert([job.url isEqualToString:@"http://www.google.com"], @"job url is wrong, is actually %@",job.url);
}

-(void) testJobSetTestResultsImage
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];

    Job *job = [Job createJobWithValues:jobvalues inManagedObjectContext:_context];
    
    [job setTestResultsImageWithImage:[UIImage imageNamed:@"blue.png"]];
    
    XCTAssertNotNil(job.testResultsImage, @"job's test results image is nil");
}

-(void) testJobGetTestResultsImage
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];

    Job *job = [Job createJobWithValues:jobvalues inManagedObjectContext:_context];
    [job setTestResultsImageWithImage:[UIImage imageNamed:@"blue.png"]];
    
    XCTAssertTrue([job.getTestResultsImage isKindOfClass:[UIImage class]], @"%@%@",@"test results image is not UIImage, returned ",NSStringFromClass([job.getTestResultsImage class]));
    
}

- (void) testCreateJenkinsInstance
{
    NSArray *viewkeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey, nil];
    NSArray *view1vals = [NSArray arrayWithObjects:@"View One",@"http://ci.kylebeal.com/", nil];
    NSArray *view2vals = [NSArray arrayWithObjects:@"View2",@"http://ci.kylebeal.com/view/View2/", nil];
    NSArray *priviewvals = [NSArray arrayWithObjects:@"View One",@"http://ci.kylebeal.com/", nil];
    NSDictionary *view1 = [NSDictionary dictionaryWithObjects:view1vals forKeys:viewkeys];
    NSDictionary *view2 = [NSDictionary dictionaryWithObjects:view2vals forKeys:viewkeys];
    NSDictionary *priview = [NSDictionary dictionaryWithObjects:priviewvals forKeys:viewkeys];
    NSArray *views = [NSArray arrayWithObjects:view1,view2, nil];
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://ci.kylebeal.com/",[NSNumber numberWithBool:YES],views,priview, nil];
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"current",JenkinsInstanceViewsKey,JenkinsInstancePrimaryViewKey, nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    JenkinsInstance *instance = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    instance.username = @"admin";
    instance.password = @"password";
    NSDictionary *primaryView = instance.primaryView;
    
    XCTAssert([instance.name isEqualToString:@"TestInstance"], @"name is wrong");
    XCTAssert([instance.url isEqualToString:@"http://ci.kylebeal.com/"], @"url is wrong");
    XCTAssert([instance.username isEqualToString:@"admin"], @"username is wrong");
    XCTAssert([instance.password isEqualToString:@"password"], @"password is wrong");
    XCTAssert(instance.rel_Views.count==2,@"views count is wrong");
    XCTAssert([[primaryView objectForKey:ViewNameKey] isEqualToString:@"View One"],@"primary view name is wrong; got %@", [primaryView objectForKey:ViewNameKey]);
    
    NSArray *savedViews = [instance.rel_Views allObjects];
    View *savedPrimaryView;
    for (View *view in savedViews) {
        if (view.name == [primaryView objectForKey:ViewNameKey]) {
            savedPrimaryView = view;
        }
    }
    XCTAssert([savedPrimaryView.url isEqualToString:@"http://ci.kylebeal.com/view/View%20One/"],@"primary view url is wrong; got %@", savedPrimaryView.url);
}

- (void) testUpdatingJenkinsInstance
{
    NSArray *viewkeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey, nil];
    NSArray *view1vals = [NSArray arrayWithObjects:@"View1",@"http://ci.kylebeal.com/", nil];
    NSArray *view2vals = [NSArray arrayWithObjects:@"View2",@"http://ci.kylebeal.com/view/View2/", nil];
    NSDictionary *view1 = [NSDictionary dictionaryWithObjects:view1vals forKeys:viewkeys];
    NSDictionary *view2 = [NSDictionary dictionaryWithObjects:view2vals forKeys:viewkeys];
    NSArray *views = [NSArray arrayWithObjects:view1,view2, nil];
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",@"http://ci.kylebeal.com/",views, nil];
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",JenkinsInstanceViewsKey, nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    JenkinsInstance *instance = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];

    XCTAssertEqual(instance.rel_Views.count, 2);
    
    instance.url = @"http://kylebeal.com/jenkins/";
    [self.datamgr saveContext:self.context];
    
    XCTAssertEqual(instance.rel_Views.count, 0);
    XCTAssertEqual(instance.url, @"http://kylebeal.com/jenkins/");
}

- (void) testUpdatingJob
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSArray *values2 = [NSArray arrayWithObjects:@"Job1",@"http://www.google1.com",@"green",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSDictionary *jobvalues2 = [NSDictionary dictionaryWithObjects:values2 forKeys:keys];

    [Job createJobWithValues:jobvalues inManagedObjectContext:_context];
    
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setPredicate:[NSPredicate predicateWithFormat:@"name = %@", @"Job1"]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedjobs = [_context executeFetchRequest:allJobs error:&error];
    Job *fetchedjob = [fetchedjobs lastObject];
    
    [fetchedjob setValues:jobvalues2];
    
    XCTAssert(fetchedjobs.count==1, @"wrong number of fetched jobs. fetched %lu",(unsigned long)fetchedjobs.count);
    XCTAssert([fetchedjob.name isEqualToString:@"Job1"], @"job name is wrong. name is actually: %@", fetchedjob.name);
    XCTAssert([fetchedjob.url isEqualToString:@"http://www.google1.com"], @"job url is wrong. url is actually: %@", fetchedjob.url);
    XCTAssert([fetchedjob.color isEqualToString:@"green"], @"job color is wrong");
}

- (void) testUpdatingView
{
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",ViewJenkinsInstanceKey, nil];
    NSArray *viewValues1 = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",_jinstance,nil];
    NSArray *viewValues2 = [NSArray arrayWithObjects:@"test2",@"url1",@"descriptiontest2",@"",_jinstance,nil];
    NSDictionary *values1 = [NSDictionary dictionaryWithObjects:viewValues1 forKeys:viewKeys];
    NSDictionary *values2 = [NSDictionary dictionaryWithObjects:viewValues2 forKeys:viewKeys];
    
    
    [View createViewWithValues:values1 inManagedObjectContext:_context];
    
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setPredicate:[NSPredicate predicateWithFormat:@"url = %@", @"url1"]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedviews = [_context executeFetchRequest:allViews error:&error];
    View *fetchedview = [fetchedviews lastObject];
    
    [fetchedview setValues:values2];
    
    XCTAssert(fetchedviews.count==1, @"wrong number of fetched views");
    XCTAssert([fetchedview.name isEqualToString:@"test2"], @"view name is wrong");
    XCTAssert([fetchedview.url isEqualToString:@"url1"], @"view url is wrong");
    XCTAssert([fetchedview.view_description isEqualToString:@"descriptiontest2"], @"view description is wrong");
}

- (void) testDeletingView
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs",ViewJenkinsInstanceKey, nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",jobs,_jinstance,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context];
    [_context deleteObject:view];
    NSError *saveError = nil;
    [_context save:&saveError];
    
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setPredicate:[NSPredicate predicateWithFormat:@"url = %@", @"http://www.google.com"]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedjobs = [_context executeFetchRequest:allJobs error:&error];
    Job *fetchedjob = [fetchedjobs lastObject];
    
    XCTAssert(fetchedjobs.count==1, @"job count is wrong");
    XCTAssert([fetchedjob.name isEqualToString:@"Job1"], @"job name is wrong");
    XCTAssert(_jinstance.rel_Views.count==0, @"jenkins instance's view count is wrong");
}

- (void) testDeletingJob
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs",ViewJenkinsInstanceKey, nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",jobs,_jinstance,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context];
    
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setPredicate:[NSPredicate predicateWithFormat:@"url = %@", @"http://www.google.com"]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedjobs = [_context executeFetchRequest:allJobs error:&error];
    Job *fetchedjob = [fetchedjobs lastObject];
    
    XCTAssert(view.rel_View_Jobs.count==1, @"view's job count is wrong");
    XCTAssert(fetchedjob.rel_Job_Views.count==1, @"job's view count is wrong");
    
    [_context deleteObject:fetchedjob];
    NSError *saveError = nil;
    [_context save:&saveError];
    
    NSFetchRequest *allBuilds = [[NSFetchRequest alloc] init];
    [allBuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allBuilds setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    XCTAssert(view.rel_View_Jobs.count==0, @"view's job count is wrong, got: %lu",(unsigned long)view.rel_View_Jobs.count);
    XCTAssert(_jinstance.rel_Jobs.count==0, @"jenkins instance's job count is wrong");
    XCTAssert(fetchedbuilds.count==0, @"build count is wrong");
}

- (void) testDeletingJenkinsInstance
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs",ViewJenkinsInstanceKey, nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",jobs,_jinstance,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    [View createViewWithValues:values inManagedObjectContext:_context];
    
    [_context deleteObject:_jinstance];
    NSError *saveError = nil;
    [_context save:&saveError];
    
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedjobs = [_context executeFetchRequest:allJobs error:&error];
    
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedviews = [_context executeFetchRequest:allViews error:&error];
    
    NSFetchRequest *allBuilds = [[NSFetchRequest alloc] init];
    [allBuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allBuilds setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    XCTAssert(fetchedjobs.count==0, @"should be no more jobs!, but there are: %lu", fetchedjobs.count);
    XCTAssert(fetchedviews.count==0, @"should be no more views!");
    XCTAssert(fetchedbuilds.count==0, @"should be no more builds!");
}

- (void) testCreateBuild
{
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey, nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    Job *job = [Job createJobWithValues:job1 inManagedObjectContext:_context];
    
    NSArray *buildkeys = [NSArray arrayWithObjects:@"description",@"building",@"builtOn",@"duration",@"estimatedDuration",@"executor",@"fullDisplayName",BuildIDKey,@"keepLog",@"number",@"result",@"timestamp",@"url",BuildJobKey,nil];
    NSArray *buildvalues = [NSArray arrayWithObjects:@"build 1 description",[NSNumber numberWithBool:NO],@"1/1/14",[NSNumber numberWithInt:123456],[NSNumber numberWithInt:123456],@"",@"build 1 test",@"build test id",[NSNumber numberWithBool:NO],[NSNumber numberWithInt:100],@"SUCCESS",[NSNumber numberWithDouble:528823830000],@"http://www.google.com",job, nil];
    NSDictionary *buildvals = [NSDictionary dictionaryWithObjects:buildvalues forKeys:buildkeys];
    
    Build *build = [Build createBuildWithValues:buildvals inManagedObjectContext:_context];
    
    XCTAssert([build.build_description isEqual:@"build 1 description"], @"build description is wrong, is actually %@",build.build_description);
    XCTAssert([build.building isEqual:[NSNumber numberWithBool:NO]], @"building is wrong");
    XCTAssert([build.builtOn isEqual:@"1/1/14"], @"built on is wrong, is actually %@", build.builtOn);
    XCTAssert([build.duration isEqualToNumber:[NSNumber numberWithInt:123456]], @"build duration is wrong");
    XCTAssert([build.estimatedDuration isEqualToNumber:[NSNumber numberWithInt:123456]], @"estimated build duration is wrong");
    XCTAssert([build.executor isEqual:@""], @"build executor should be nil");
    XCTAssert([build.fullDisplayName isEqual:@"build 1 test"], @"build full display name is wrong");
    XCTAssert([build.build_id isEqual:@"build test id"], @"build id is wrong");
    XCTAssert([build.keepLog isEqualToNumber:[NSNumber numberWithBool:NO]], @"keep log is wrong");
    XCTAssert([build.number isEqualToNumber:[NSNumber numberWithInt:100]], @"build number is wrong");
    XCTAssert([build.result isEqual:@"SUCCESS"], @"build result is wrong");
    XCTAssert([build.timestamp isEqualToDate:[NSDate dateWithTimeIntervalSince1970:528823830]], @"build timestamp is wrong %f",[build.timestamp timeIntervalSince1970]);
    XCTAssert([build.url isEqual:@"http://www.google.com"], @"build url is wrong");
    XCTAssert([build.rel_Build_Job.url isEqualToString:@"http://www.google.com"], @"build's job url is wrong");
}

- (void) testCreateBuildWithMinimalValues
{
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey, nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    Job *job = [Job createJobWithValues:job1 inManagedObjectContext:_context];
    
    NSArray *buildkeys = [NSArray arrayWithObjects:@"number",@"url",BuildJobKey,nil];
    NSArray *buildvalues = [NSArray arrayWithObjects:[NSNumber numberWithInt:100],@"http://www.google.com",job, nil];
    NSDictionary *buildvals = [NSDictionary dictionaryWithObjects:buildvalues forKeys:buildkeys];
    
    Build *build = [Build createBuildWithValues:buildvals inManagedObjectContext:_context];
    
    XCTAssert([build.url isEqual:@"http://www.google.com"], @"build url is wrong");
    XCTAssert([build.number isEqualToNumber:[NSNumber numberWithInt:100]], @"build number is wrong");
}

- (void) testDeleteBuild
{
    NSFetchRequest *allbuilds = [[NSFetchRequest alloc] init];
    [allbuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allbuilds setIncludesPropertyValues:NO];
    NSError *error = nil;
    
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobColorKey, nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    Job *job = [Job createJobWithValues:job1 inManagedObjectContext:_context];
    
    NSArray *buildkeys = [NSArray arrayWithObjects:@"number",@"url",BuildJobKey,nil];
    NSArray *buildvalues = [NSArray arrayWithObjects:[NSNumber numberWithInt:100],@"http://www.google.com",job, nil];
    NSDictionary *buildvals = [NSDictionary dictionaryWithObjects:buildvalues forKeys:buildkeys];
    
    Build *build = [Build createBuildWithValues:buildvals inManagedObjectContext:_context];
    
    NSUInteger orig_cnt = [_context countForFetchRequest:allbuilds error:&error];

    [_context deleteObject:build];
    NSError *saveError = nil;
    [_context save:&saveError];
    
    NSUInteger new_cnt = [_context countForFetchRequest:allbuilds error:&error];
    
    XCTAssert(orig_cnt==1, @"wrong original build count");
    XCTAssert(new_cnt==0, @"wrong build count after delete");
}

- (void) testNestedViews
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,nil];
    
    NSArray *viewKeys = [NSArray arrayWithObjects:ViewNameKey,ViewURLKey,ViewPropertyKey,ViewDescriptionKey,ViewJobsKey,ViewViewsKey,ViewJenkinsInstanceKey, nil];
    
    NSArray *childView1Values = [NSArray arrayWithObjects:@"test1",@"url1",[NSNull null],@"descriptiontest1",jobs,[NSNull null],_jinstance,nil];
    NSArray *childView2Values = [NSArray arrayWithObjects:@"test2",@"url2",[NSNull null],@"descriptiontest2",jobs,[NSNull null],_jinstance,nil];
    NSArray *childView3Values = [NSArray arrayWithObjects:@"test3",@"url3",[NSNull null],@"descriptiontest3",jobs,[NSNull null],_jinstance,nil];
    
    NSDictionary *childView1 = [NSDictionary dictionaryWithObjects:childView1Values forKeys:viewKeys];
    NSDictionary *childView2 = [NSDictionary dictionaryWithObjects:childView2Values forKeys:viewKeys];
    NSDictionary *childView3 = [NSDictionary dictionaryWithObjects:childView3Values forKeys:viewKeys];
    NSDictionary *childView4 = [NSDictionary dictionaryWithObjects:childView3Values forKeys:viewKeys];
    
    NSArray *childViews = [NSArray arrayWithObjects:childView1,childView2,childView3,childView4,nil];
    NSArray *childViews2 = [NSArray arrayWithObjects:childView1,childView2, nil];

    NSArray *parentViewValues = [NSArray arrayWithObjects:@"parent",@"parent.com",@"property",@"parent view",jobs,childViews,_jinstance,nil];
    NSArray *parentView2Values = [NSArray arrayWithObjects:@"parent2",@"parent2.com",@"property",@"parent view",jobs,childViews2,_jinstance,nil];
    NSDictionary *parentViewDict = [NSDictionary dictionaryWithObjects:parentViewValues forKeys:viewKeys];
    NSDictionary *parentView2Dict = [NSDictionary dictionaryWithObjects:parentView2Values forKeys:viewKeys];
    View *parentView = [View createViewWithValues:parentViewDict inManagedObjectContext:_context];
    View *parentView2 = [View createViewWithValues:parentView2Dict inManagedObjectContext:_context];
    View *childViewObj1 = [parentView.rel_View_Views anyObject];
    View *childViewObj2 = [parentView2.rel_View_Views anyObject];
    
    NSError *error;
    NSFetchRequest *allViews = [[NSFetchRequest alloc] init];
    [allViews setEntity:[NSEntityDescription entityForName:@"View" inManagedObjectContext:_context]];
    [allViews setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *views = [_context executeFetchRequest:allViews error:&error];
    
    XCTAssert(parentView.rel_View_Views.count==3, @"parentView's views count should be 3, got %lu instead",(unsigned long)parentView.rel_View_Views.count);
    XCTAssert(parentView2.rel_View_Views.count==2, @"parentView2's views count should be 2, got %lu instead",(unsigned long)parentView2.rel_View_Views.count);
    XCTAssert(childViewObj1.rel_ParentView==parentView, @"child view 1 has wrong parent view");
    XCTAssert(childViewObj2.rel_ParentView==parentView, @"child view 2 has wrong parent view");
    XCTAssert(views.count==5, @"view count should be 4, instead got %lu", (unsigned long)views.count);
    XCTAssert(_jinstance.rel_Views.count==5, @"jenkins instance should be related to 5 views, instead related to %lu",(unsigned long)_jinstance.rel_Views.count);
}

- (void) testJobColorIsAnimated
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSArray *values2 = [NSArray arrayWithObjects:@"Job2",@"www.google.com",@"blue_anime",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSDictionary *jobvalues2 = [NSDictionary dictionaryWithObjects:values2 forKeys:keys];

    Job *job1 = [Job createJobWithValues:jobvalues inManagedObjectContext:_context];
    Job *job2 = [Job createJobWithValues:jobvalues2 inManagedObjectContext:_context];
    
    XCTAssertFalse([job1 colorIsAnimated], @"job1 returned wrong value for colorIsAnimated");
    XCTAssertTrue([job2 colorIsAnimated], @"job2 returned wrong value for colorIsAnimated");
}

- (void) testJobNameFromJobURL
{
    NSString *url1str = @"http://www.google.com/view/Release/view/Release1/job/Job1/api/json";
    NSString *url2str = @"http://www.google.com/job/Job2/api/json";
    NSURL *url1 = [NSURL URLWithString:url1str];
    NSURL *url2 = [NSURL URLWithString:url2str];
    
    XCTAssertEqualObjects(@"Job1", [Job jobNameFromURL:url1]);
    XCTAssertEqualObjects(@"Job2", [Job jobNameFromURL:url2]);
}

- (void)testCreateActiveConfigurationWithValues
{
    
    NSDictionary *jobbuilddict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"number"];
    NSArray *relatedProjectsKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *upstreamProjectValues = [NSArray arrayWithObjects:@"maven-surefire",@"https://builds.apache.org/job/maven-surefire/",@"blue", nil];
    NSArray *downstreamProjectValues1 = [NSArray arrayWithObjects:@"test4commerce",@"http://www.google.com",@"green", nil];
    NSArray *downstreamProjectValues2 = [NSArray arrayWithObjects:@"test3commerce",@"http://www.yahoo.com",@"blue", nil];
    NSDictionary *upstreamProject = [NSDictionary dictionaryWithObjects:upstreamProjectValues forKeys:relatedProjectsKeys];
    NSDictionary *downstreamProject1 = [NSDictionary dictionaryWithObjects:downstreamProjectValues1 forKeys:relatedProjectsKeys];
    NSDictionary *downstreamProject2 = [NSDictionary dictionaryWithObjects:downstreamProjectValues2 forKeys:relatedProjectsKeys];
    NSArray *upstreamProjects = [NSArray arrayWithObjects:upstreamProject, nil];
    NSArray *downstreamProjects = [NSArray arrayWithObjects:downstreamProject1, downstreamProject2, nil];
    NSArray *healthReportKeys = [NSArray arrayWithObjects:@"description",@"iconUrl",@"score", nil];
    NSArray *healthReportValues = [NSArray arrayWithObjects:@"Build stability: No recent builds failed.",@"health-80plus.png",@"100", nil];
    NSDictionary *healthReport = [NSDictionary dictionaryWithObjects:healthReportValues forKeys:healthReportKeys];
    NSArray *jobkeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobJenkinsInstanceKey, nil];
    NSArray *jobvals = [NSArray arrayWithObjects:@"TestJob", @"http://jenkins:8080/job/TestJob", _jinstance, nil];
    NSDictionary *jobdict = [NSDictionary dictionaryWithObjects:jobvals forKeys:jobkeys];
    Job *job = [Job createJobWithValues:jobdict inManagedObjectContext:_context];
    
    NSArray *acKeys = [NSArray arrayWithObjects:ActiveConfigurationNameKey,ActiveConfigurationColorKey,ActiveConfigurationURLKey,ActiveConfigurationBuildableKey,ActiveConfigurationConcurrentBuildKey,ActiveConfigurationDisplayNameKey,ActiveConfigurationFirstBuildKey,ActiveConfigurationLastBuildKey,ActiveConfigurationLastCompletedBuildKey,ActiveConfigurationLastFailedBuildKey,ActiveConfigurationLastStableBuildKey,ActiveConfigurationLastSuccessfulBuildKey,ActiveConfigurationLastUnstableBuildKey,ActiveConfigurationLastUnsucessfulBuildKey,ActiveConfigurationNextBuildNumberKey,ActiveConfigurationInQueueKey,ActiveConfigurationDescriptionKey,ActiveConfigurationKeepDependenciesKey,ActiveConfigurationUpstreamProjectsKey,ActiveConfigurationDownstreamProjectsKey,ActiveConfigurationHealthReportKey,ActiveConfigurationJobKey,nil ];
    
    NSArray *acValues = [NSArray arrayWithObjects:@"config=1",@"blue",@"http://tomcat:8080/view/JobsView1/job/Job1/config=1",[NSNumber numberWithInt:1],[NSNumber numberWithInt:0],@"Test1",jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,[NSNumber numberWithInt:2],[NSNumber numberWithBool:NO],@"Test1 Description",[NSNumber numberWithBool:NO],upstreamProjects,downstreamProjects,healthReport,job, nil];
    
    NSDictionary *acVals = [NSDictionary dictionaryWithObjects:acValues forKeys:acKeys];
    
    ActiveConfiguration *ac = [ActiveConfiguration createActiveConfigurationWithValues:acVals inManagedObjectContext:_context];
    
    XCTAssert([ac.name isEqualToString:@"config=1"], @"ac name should be Test1, is actually %@",ac.name);
    XCTAssert([ac.color isEqualToString:@"blue"], @"ac color is wrong");
    XCTAssert([ac.url isEqualToString:@"http://tomcat:8080/view/JobsView1/job/Job1/config=1"], @"ac url is wrong, is actually %@",ac.url);
    XCTAssertEqualObjects(ac.buildable, [NSNumber numberWithBool:YES], @"ac should be buildable, is not");
    XCTAssertEqualObjects(ac.concurrentBuild, [NSNumber numberWithBool:NO], @"ac should be a concurrent build is actually %@", [ac.concurrentBuild stringValue]);
    XCTAssertEqual(ac.displayName, @"Test1", @"display name is wrong, is actually %@", ac.displayName);
    XCTAssertEqualObjects(ac.firstBuild, [NSNumber numberWithInt:1], @"first build number is wrong");
    XCTAssertEqualObjects(ac.lastBuild, [NSNumber numberWithInt:1], @"last build number is wrong");
    XCTAssertEqualObjects(ac.lastCompletedBuild, [NSNumber numberWithInt:1], @"last complete build number is wrong");
    XCTAssertEqualObjects(ac.lastFailedBuild, [NSNumber numberWithInt:1], @"last fail build number is wrong");
    XCTAssertEqualObjects(ac.lastStableBuild, [NSNumber numberWithInt:1], @"last stable build number is wrong");
    XCTAssertEqualObjects(ac.lastSuccessfulBuild, [NSNumber numberWithInt:1], @"last successful build number is wrong");
    XCTAssertEqualObjects(ac.lastUnstableBuild, [NSNumber numberWithInt:1], @"last unstable build number is wrong");
    XCTAssertEqualObjects(ac.lastUnsuccessfulBuild, [NSNumber numberWithInt:1], @"last unsuccessful build number is wrong");
    XCTAssertEqualObjects(ac.nextBuildNumber, [NSNumber numberWithInt:2], @"next build number is wrong");
    XCTAssertEqualObjects(ac.inQueue, [NSNumber numberWithBool:NO], @"in queue should be false, is actually %@", [ac.inQueue stringValue]);
    XCTAssertEqual(ac.activeConfiguration_description, @"Test1 Description", @"ac description is wrong is actually %@", ac.activeConfiguration_description);
    XCTAssertEqualObjects(ac.keepDependencies, [NSNumber numberWithBool:NO], @"keep dependencies should be false, is actually %@", [ac.keepDependencies stringValue]);
    XCTAssertNotNil(ac.rel_ActiveConfiguration_Job, @"ac job is null");
    XCTAssert([ac.upstreamProjects count]==1, @"wrong number of upstream projects");
    XCTAssert([ac.downstreamProjects count]==2, @"wrong number of downstream projects");
    XCTAssert([[[ac.upstreamProjects objectAtIndex:0] objectForKey:@"color"] isEqualToString:@"blue"], @"upstream project has wrong color");
    XCTAssert([[[ac.downstreamProjects objectAtIndex:0] objectForKey:@"color"] isEqualToString:@"green"], @"downstream project1 has wrong color");
    XCTAssert([[[ac.downstreamProjects objectAtIndex:1] objectForKey:@"url"] isEqualToString:@"http://www.yahoo.com"], @"downstream project2 has wrong url");
    XCTAssert([[ac.healthReport objectForKey:@"iconUrl"] isEqualToString:@"health-80plus.png"], @"health report is wrong %@", [ac.healthReport objectForKey:@"iconUrl"]);
}

- (void) testActiveConfigurationSimplifyURL
{
    NSArray *jobkeys = [NSArray arrayWithObjects:JobNameKey,JobURLKey,JobJenkinsInstanceKey, nil];
    NSArray *jobvals = [NSArray arrayWithObjects:@"TestJob", @"http://jenkins:8080/job/TestJob", _jinstance, nil];
    NSDictionary *jobdict = [NSDictionary dictionaryWithObjects:jobvals forKeys:jobkeys];
    Job *job = [Job createJobWithValues:jobdict inManagedObjectContext:_context];
    
    NSArray *ackeys = [NSArray arrayWithObjects:ActiveConfigurationColorKey, ActiveConfigurationJobKey, ActiveConfigurationNameKey, ActiveConfigurationURLKey, nil];
    NSArray *acvals = [NSArray arrayWithObjects:@"blue", job, @"port=4502,server=test", @"http://jenkins:8080/view/Project1/view/Dev2/job/Dev2%20Deploy%20Bundle/port=4503,server=mycqserver/", nil];
    NSDictionary *acdict = [NSDictionary dictionaryWithObjects:acvals forKeys:ackeys];
    ActiveConfiguration *ac = [ActiveConfiguration createActiveConfigurationWithValues:acdict inManagedObjectContext:_context];
    
    NSURL *simplifiedURL = [ac simplifiedURL];
    XCTAssertEqualObjects(simplifiedURL.absoluteString, @"http://jenkins:8080/job/Dev2%20Deploy%20Bundle/port=4503,server=mycqserver", @"simplified url is incorrect");
}

- (void) testRemoveApiFromJenkinsURL
{
    NSString *url1str = @"http://www.google.com/api/json";
    NSString *url2str = @"http://www.google.com/ci/jenkins/api/json";
    NSURL *url1 = [NSURL URLWithString:url1str];
    NSURL *url2 = [NSURL URLWithString:url2str];
    XCTAssertEqualObjects(@"http://www.google.com", [JenkinsInstance removeApiFromURL:url1]);
    XCTAssertEqualObjects(@"http://www.google.com/ci/jenkins", [JenkinsInstance removeApiFromURL:url2]);
}

- (void) testValidateURL
{
    NSString *url = nil;
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",nil];
    NSArray *keys = [NSArray arrayWithObjects:JenkinsInstanceNameKey,nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    JenkinsInstance *instance = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    
    NSError *error = nil;
    BOOL valid = [instance validateValue:&url forKey:JenkinsInstanceURLKey error:&error];
    
    XCTAssertFalse(valid);
}

-(void) testValidateUsername
{
    NSString *invalidusername = @"";
    NSString *validusername = @"admin";
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",nil];
    NSArray *keys = [NSArray arrayWithObjects:JenkinsInstanceNameKey,nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    JenkinsInstance *instance = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    
    NSString *message = nil;
    BOOL invalid = [instance validateUsername:invalidusername withMessage:&message];
    BOOL valid = [instance validateUsername:validusername withMessage:&message];
    
    XCTAssertFalse(invalid);
    XCTAssertTrue(valid);
}

-(void) testCorrectURL
{
    NSString *incorrectURL = @"http://localhost:8080";
    NSArray *values = [NSArray arrayWithObjects:@"TestInstance",incorrectURL,nil];
    NSArray *values2 = [NSArray arrayWithObjects:@"TestInstance2",@"",nil];
    NSArray *keys = [NSArray arrayWithObjects:JenkinsInstanceNameKey,JenkinsInstanceURLKey,nil];
    NSDictionary *instancevalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSDictionary *instancevalues2 = [NSDictionary dictionaryWithObjects:values2 forKeys:keys];
    JenkinsInstance *instance = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues inManagedObjectContext:_context];
    JenkinsInstance *instance2 = [JenkinsInstance createJenkinsInstanceWithValues:instancevalues2 inManagedObjectContext:_context];
    XCTAssertTrue([instance.url isEqualToString:@"http://localhost:8080/"]);
    XCTAssertTrue([instance2.url isEqualToString:@""]);
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
