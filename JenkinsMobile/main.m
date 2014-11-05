//
//  main.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KDBAppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        BOOL runningTests = NSClassFromString(@"XCTestCase") != nil;
        if(!runningTests) {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([KDBAppDelegate class]));
        } else {
            return UIApplicationMain(argc, argv, nil, @"TestAppDelegate");
        }
    }
}
