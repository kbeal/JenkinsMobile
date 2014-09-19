//
//  UIButton+RelatedProject.m
//  JenkinsMobile
//
//  Created by Kyle on 7/19/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "UIButton+RelatedProject.h"
#import <objc/runtime.h>

@implementation UIButton (RelatedProject)

static char UIB_RELATEDPROJECT_NAME_KEY;

@dynamic relatedProjectName;

-(void)setRelatedProjectName:(NSString *)relatedProjectName
{
    objc_setAssociatedObject(self, &UIB_RELATEDPROJECT_NAME_KEY, relatedProjectName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString*)relatedProjectName
{
    return (NSString*)objc_getAssociatedObject(self, &UIB_RELATEDPROJECT_NAME_KEY);
}

@end
