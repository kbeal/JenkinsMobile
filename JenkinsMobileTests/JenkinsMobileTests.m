//
//  JenkinsMobileTests.m
//  JenkinsMobileTests
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Job.h"
#import "View.h"
#import "JenkinsInstance.h"
#import "Build.h"
#import "Constants.h"
#import "ActiveConfiguration.h"

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
    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
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
    build.url = @"http://www.google.com";
    build.number = [NSNumber numberWithInt:100];
    build.jobURL = @"http://www.google.com";
    
    Job *job = [NSEntityDescription insertNewObjectForEntityForName:@"Job" inManagedObjectContext:_context];
    job.name = @"TestJob";
    job.url = @"http://www.google.com";
    job.job_description = @"Test job description";
    job.color = @"blue";
    job.rel_Job_JenkinsInstance = _jinstance;
    
    if (![_context save:&error]) {
        XCTFail(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *newbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    XCTAssert(newbuilds.count==origbuilds.count+1, @"Build count should incrase by 1 to %d, instead got %d",origbuilds.count+1,newbuilds.count);
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

    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    
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
    
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"color",@"url",@"buildable",@"concurrentBuild",@"displayName",@"firstBuild",@"lastBuild",@"lastCompletedBuild",@"lastFailedBuild",@"lastStableBuild",@"lastSuccessfulBuild",@"lastUnstableBuild",@"lastUnsuccessfulBuild",@"nextBuildNumber",@"inQueue",@"description",@"keepDependencies",@"upstreamProjects",@"downstreamProjects",@"healthReport",JobActiveConfigurationsKey,nil ];
    
    NSArray *jobValues = [NSArray arrayWithObjects:@"Test1",@"blue",@"http://tomcat:8080/view/JobsView1/job/Job1/",[NSNumber numberWithInt:1],[NSNumber numberWithInt:0],@"Test1",jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,jobbuilddict,[NSNumber numberWithInt:2],[NSNumber numberWithBool:NO],@"Test1 Description",[NSNumber numberWithBool:NO],upstreamProjects,downstreamProjects,healthReport,activeConfigurations, nil];
    
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    

    Job *job = [Job createJobWithValues:[NSDictionary dictionaryWithObjects:jobValues forKeys:jobKeys] inManagedObjectContext:_context forView:view];
    
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
}

- (void)testActiveConfigurations
{
    NSArray *activeConfigurationsKeys = [NSArray arrayWithObjects:ActiveConfigurationNameKey,ActiveConfigurationURLKey,ActiveConfigurationColorKey, nil];
    NSArray *activeConfigurationsValues1 = [NSArray arrayWithObjects:@"config1",@"www.config1.com",@"blue", nil];
    NSArray *activeConfigurationsValues2 = [NSArray arrayWithObjects:@"config2",@"www.config2.com",@"red", nil];
    NSDictionary *activeConfigurations1 = [NSDictionary dictionaryWithObjects:activeConfigurationsValues1 forKeys:activeConfigurationsKeys];
    NSDictionary *activeConfigurations2 = [NSDictionary dictionaryWithObjects:activeConfigurationsValues2 forKeys:activeConfigurationsKeys];
    NSArray *activeConfigurations = [NSArray arrayWithObjects:activeConfigurations1,activeConfigurations2, nil];
    NSArray *jobKeys = [NSArray arrayWithObjects:JobNameKey,JobColorKey,JobURLKey,JobActiveConfigurationsKey,nil ];
    NSArray *jobValues = [NSArray arrayWithObjects:@"Test1",@"blue",@"http://tomcat:8080/view/JobsView1/job/Job1/",activeConfigurations, nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    Job *job = [Job createJobWithValues:[NSDictionary dictionaryWithObjects:jobValues forKeys:jobKeys] inManagedObjectContext:_context forView:view];
    NSArray *activeConfigs = [job getActiveConfigurations];
    ActiveConfiguration *ac1 = [activeConfigs objectAtIndex:0];
    ActiveConfiguration *ac2 = [activeConfigs objectAtIndex:1];
    
    XCTAssert([activeConfigs count]==2, @"active configs has wrong count");
    XCTAssert([ac1.name isEqualToString:@"config1"], @"ac1 has wrong name");
    XCTAssert([ac2.color isEqualToString:@"red"], @"ac2 has wrong color");
    
}

- (void)testCreateJobWithMinimalValues
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",nil];
    NSDictionary *viewvals = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    View *view = [View createViewWithValues:viewvals inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    Job *job = [Job createJobWithValues:jobvalues inManagedObjectContext:_context forView:view];
    
    XCTAssert([job.name isEqualToString:@"Job1"], @"job name should be Job1, is actually %@",job.name);
    XCTAssert([job.color isEqualToString:@"blue"], @"job color is wrong");
    XCTAssert([job.url isEqualToString:@"http://www.google.com"], @"job url is wrong, is actually %@",job.url);
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
    
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",nil];
    NSDictionary *viewvals = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    
    View *view = [View createViewWithValues:viewvals inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];

    
    [Job createJobWithValues:jobvalues inManagedObjectContext:_context forView:view];
    [Job createJobWithValues:jobvalues2 inManagedObjectContext:_context forView:view];
    
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
    
    
    [View createViewWithValues:values1 inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    [View createViewWithValues:values2 inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    
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

- (void) testDeletingView
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",jobs,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
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
    

    
    XCTAssert(fetchedjob.rel_Job_View.count==0, @"job's view count is wrong");
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
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",jobs,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    View *view = [View createViewWithValues:values inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    
    NSError *error;
    NSFetchRequest *allJobs = [[NSFetchRequest alloc] init];
    [allJobs setEntity:[NSEntityDescription entityForName:@"Job" inManagedObjectContext:_context]];
    [allJobs setPredicate:[NSPredicate predicateWithFormat:@"url = %@", @"http://www.google.com"]];
    [allJobs setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedjobs = [_context executeFetchRequest:allJobs error:&error];
    Job *fetchedjob = [fetchedjobs lastObject];
    
    XCTAssert(view.rel_View_Jobs.count==1, @"view's job count is wrong");
    XCTAssert(fetchedjob.rel_Job_View.count==1, @"job's view count is wrong");
    
    [_context deleteObject:fetchedjob];
    NSError *saveError = nil;
    [_context save:&saveError];
    
    NSFetchRequest *allBuilds = [[NSFetchRequest alloc] init];
    [allBuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allBuilds setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSArray *fetchedbuilds = [_context executeFetchRequest:allBuilds error:&error];
    
    XCTAssert(view.rel_View_Jobs.count==0, @"view's job count is wrong");
    XCTAssert(_jinstance.rel_Jobs.count==0, @"jenkins instance's job count is wrong");
    XCTAssert(fetchedbuilds.count==0, @"build count is wrong");
}

- (void) testDeletingJenkinsInstance
{
    NSArray *jobKeys = [NSArray arrayWithObjects:@"name",@"url",@"color", nil];
    NSArray *jobValues1 = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue", nil];
    NSDictionary *job1 = [NSDictionary dictionaryWithObjects:jobValues1 forKeys:jobKeys];
    NSArray *jobs = [NSArray arrayWithObjects:job1,nil];
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url",@"description",@"property",@"jobs", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",@"descriptiontest1",@"",jobs,nil];
    NSDictionary *values = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    [View createViewWithValues:values inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    
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
    
    XCTAssert(fetchedjobs.count==0, @"should be no more jobs!");
    XCTAssert(fetchedviews.count==0, @"should be no more views!");
    XCTAssert(fetchedbuilds.count==0, @"should be no more builds!");
}

- (void) testCreateBuild
{
    NSArray *buildkeys = [NSArray arrayWithObjects:@"description",@"building",@"builtOn",@"duration",@"estimatedDuration",@"executor",@"fullDisplayName",@"build_id",@"keepLog",@"number",@"result",@"timestamp",@"url",nil];
    NSArray *buildvalues = [NSArray arrayWithObjects:@"build 1 description",[NSNumber numberWithBool:NO],@"1/1/14",[NSNumber numberWithInt:123456],[NSNumber numberWithInt:123456],@"",@"build 1 test",@"build test id",[NSNumber numberWithBool:NO],[NSNumber numberWithInt:100],@"SUCCESS",[NSNumber numberWithDouble:139691690635],@"http://www.google.com", nil];
    NSDictionary *buildvals = [NSDictionary dictionaryWithObjects:buildvalues forKeys:buildkeys];
    
    Build *build = [Build createBuildWithValues:buildvals inManagedObjectContext:_context forJobAtURL:@"http://www.google.com"];
    
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
    XCTAssert([build.timestamp isEqualToDate:[NSDate dateWithTimeIntervalSince1970:139691690635]], @"build timestamp is wrong %f",[build.timestamp timeIntervalSince1970]);
    XCTAssert([build.url isEqual:@"http://www.google.com"], @"build url is wrong");
    XCTAssert([build.jobURL isEqualToString:@"http://www.google.com"], @"build's job url is wrong");
}

- (void) testCreateBuildWithoutJob
{
    NSArray *buildkeys = [NSArray arrayWithObjects:@"number",@"url",nil];
    NSArray *buildvalues = [NSArray arrayWithObjects:[NSNumber numberWithInt:100],@"http://www.google.com", nil];
    NSDictionary *buildvals = [NSDictionary dictionaryWithObjects:buildvalues forKeys:buildkeys];
    
    Build *build = [Build createBuildWithValues:buildvals inManagedObjectContext:_context forJobAtURL:@"http://www.google.com"];
    
    XCTAssert([build.number isEqualToNumber:[NSNumber numberWithInt:100]], @"build number is wrong");
    XCTAssert([build.url isEqual:@"http://www.google.com"], @"build url is wrong");
    XCTAssert([build.jobURL isEqualToString:@"http://www.google.com"], @"build's job url is wrong");
}

- (void) testCreateBuildWithMinimalValues
{
    NSArray *buildkeys = [NSArray arrayWithObjects:@"number",@"url",nil];
    NSArray *buildvalues = [NSArray arrayWithObjects:[NSNumber numberWithInt:100],@"http://www.google.com", nil];
    NSDictionary *buildvals = [NSDictionary dictionaryWithObjects:buildvalues forKeys:buildkeys];
    
    Build *build = [Build createBuildWithValues:buildvals inManagedObjectContext:_context forJobAtURL:@"http://www.google.com"];
    
    XCTAssert([build.url isEqual:@"http://www.google.com"], @"build url is wrong");
    XCTAssert([build.number isEqualToNumber:[NSNumber numberWithInt:100]], @"build number is wrong");
}

- (void) testDeleteBuild
{
    NSFetchRequest *allbuilds = [[NSFetchRequest alloc] init];
    [allbuilds setEntity:[NSEntityDescription entityForName:@"Build" inManagedObjectContext:_context]];
    [allbuilds setIncludesPropertyValues:NO];
    NSError *error = nil;
    
    NSArray *buildkeys = [NSArray arrayWithObjects:@"number",@"url",nil];
    NSArray *buildvalues = [NSArray arrayWithObjects:[NSNumber numberWithInt:100],@"http://www.google.com", nil];
    NSDictionary *buildvals = [NSDictionary dictionaryWithObjects:buildvalues forKeys:buildkeys];
    
    Build *build = [Build createBuildWithValues:buildvals inManagedObjectContext:_context forJobAtURL:@"http://www.google.com"];
    
    NSUInteger orig_cnt = [_context countForFetchRequest:allbuilds error:&error];

    [_context deleteObject:build];
    NSError *saveError = nil;
    [_context save:&saveError];
    
    NSUInteger new_cnt = [_context countForFetchRequest:allbuilds error:&error];
    
    XCTAssert(orig_cnt==1, @"wrong original build count");
    XCTAssert(new_cnt==0, @"wrong build count after delete");
}

- (void) testJobColorIsAnimated
{
    NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"color",nil];
    NSArray *values = [NSArray arrayWithObjects:@"Job1",@"http://www.google.com",@"blue",nil];
    NSArray *values2 = [NSArray arrayWithObjects:@"Job2",@"www.google.com",@"blue_anime",nil];
    NSDictionary *jobvalues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    NSDictionary *jobvalues2 = [NSDictionary dictionaryWithObjects:values2 forKeys:keys];
    
    NSArray *viewKeys = [NSArray arrayWithObjects:@"name",@"url", nil];
    NSArray *viewValues = [NSArray arrayWithObjects:@"test1",@"url1",nil];
    NSDictionary *viewvals = [NSDictionary dictionaryWithObjects:viewValues forKeys:viewKeys];
    
    
    View *view = [View createViewWithValues:viewvals inManagedObjectContext:_context forJenkinsInstance:@"http://tomcat:8080/"];
    Job *job1 = [Job createJobWithValues:jobvalues inManagedObjectContext:_context forView:view];
    Job *job2 = [Job createJobWithValues:jobvalues2 inManagedObjectContext:_context forView:view];
    
    XCTAssertFalse([job1 colorIsAnimated], @"job1 returned wrong value for colorIsAnimated");
    XCTAssertTrue([job2 colorIsAnimated], @"job2 returned wrong value for colorIsAnimated");
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
