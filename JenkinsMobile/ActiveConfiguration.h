//
//  ActiveConfiguration.h
//  JenkinsMobile
//
//  Created by Kyle on 8/29/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Job.h"

@interface ActiveConfiguration : NSObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * color;

- (id) initWithName: (NSString *)name Color: (NSString *)color andURL: (NSString *)url;

@end
