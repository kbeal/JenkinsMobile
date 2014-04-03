//
//  KDBViewPickerViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 3/29/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ViewPickerDelegate <NSObject>
@required
-(void)selectedView:(NSURL *)newViewURL withName:(NSString *) name;
@end

@interface KDBViewPickerViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *views;
@property (nonatomic, weak) id<ViewPickerDelegate> delegate;

@end
