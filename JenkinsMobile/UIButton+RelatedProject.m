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

static char UIB_RELATEDPROJECT_URL_KEY;

@dynamic relatedProjectURL;

-(void)setRelatedProjectURL:(NSString *)relatedProjectURL
{
    objc_setAssociatedObject(self, &UIB_RELATEDPROJECT_URL_KEY, relatedProjectURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString*)relatedProjectURL
{
    return (NSString*)objc_getAssociatedObject(self, &UIB_RELATEDPROJECT_URL_KEY);
}

@end
