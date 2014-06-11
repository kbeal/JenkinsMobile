//
//  KDBViewPickerDelegate.h
//  JenkinsMobile
//
//  Created by Kyle on 6/10/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KDBViewPickerDelegate <NSObject>
@required
-(void)selectedView:(NSURL *)newViewURL withName:(NSString *) name;
@end
