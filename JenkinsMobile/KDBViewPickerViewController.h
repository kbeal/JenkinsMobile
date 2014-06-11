//
//  KDBViewPickerViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 3/29/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KDBViewPickerDelegate.h"

@interface KDBViewPickerViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *views;
@property (nonatomic, weak) id<KDBViewPickerDelegate> delegate;

@end
