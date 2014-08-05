//
//  Constants.h
//  JenkinsMobile
//
//  Created by Kyle on 8/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

extern NSInteger const PermalinksSectionIndex;
extern NSInteger const UpstreamProjectsSectionIndex;
extern NSInteger const DownstreamProjectsSectionIndex;
extern NSInteger const LastBuildIndex;
extern NSInteger const LastCompletedBuildIndex;
extern NSInteger const LastFailedBuildIndex;
extern NSInteger const LastStableBuildIndex;
extern NSInteger const LastSuccessfulBuildIndex;
extern NSInteger const LastUnstableBuildIndex;
extern NSInteger const LastUnsuccessfulBuildIndex;

@end

// job detail section indices
NSInteger const PermalinksSectionIndex         = 0;
NSInteger const UpstreamProjectsSectionIndex   = 1;
NSInteger const DownstreamProjectsSectionIndex = 2;

// permalinks row indices
NSInteger const LastBuildRowIndex              = 0;
NSInteger const LastCompletedBuildRowIndex     = 1;
NSInteger const LastSuccessfulBuildRowIndex    = 2;
NSInteger const LastStableBuildRowIndex        = 3;
NSInteger const LastFailedBuildRowIndex        = 4;
NSInteger const LastUnsuccessfulBuildRowIndex  = 5;
NSInteger const LastUnstableBuildRowIndex      = 6;
