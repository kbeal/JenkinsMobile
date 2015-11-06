//
//  JenkinsInstance+More.h
//  JenkinsMobile
//
//  Created by Kyle on 2/19/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "JenkinsInstance.h"

@interface JenkinsInstance (More)

@property (nonatomic, copy) NSString *password;

- (void)setValues:(NSDictionary *) values;
- (void)updateValues:(NSDictionary *) values;
- (BOOL)validateInstanceWithMessage:(NSString **) message;
- (BOOL)validateURL:(NSString *) newURL withMessage:(NSString **) message;
- (BOOL)validateName:(NSString *) newName withMessage:(NSString **) message;
- (BOOL)validateUsername:(NSString *) newUsername withMessage:(NSString **) message;
- (BOOL)validatePassword:(NSString *) newPassword withMessage:(NSString **) message;
- (void)correctURL;

+ (JenkinsInstance *)createJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
//+ (JenkinsInstance *)getCurrentJenkinsInstanceFromManagedObjectContext:(NSManagedObjectContext *) context;
+ (JenkinsInstance *)fetchJenkinsInstanceWithURL: (NSString *) url fromManagedObjectContext: (NSManagedObjectContext *) context;
+ (JenkinsInstance *)findOrCreateJenkinsInstanceWithValues:(NSDictionary *)values inManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSString *) removeApiFromURL:(NSURL *) url;

@end
