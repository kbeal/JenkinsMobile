//
//  JenkinsMobileTests.m
//  JenkinsMobileTests
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KDBJenkinsRequestHandler.h"

@interface JenkinsMobileTests : XCTestCase

@end

@implementation JenkinsMobileTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/*
- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}*/

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
}

@end
