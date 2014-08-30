//
//  ActiveConfiguration.m
//  JenkinsMobile
//
//  Created by Kyle on 8/29/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "ActiveConfiguration.h"
#import "Constants.h"

@implementation ActiveConfiguration

- (id) initWithName: (NSString *)name Color: (NSString *)color andURL: (NSString *)url
{
    self.name=name;
    self.color=color;
    self.url=url;
    return self;
}



@end
