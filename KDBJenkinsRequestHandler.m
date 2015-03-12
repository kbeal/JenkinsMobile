//
//  KDBJenkinsRequestHandler.m
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJenkinsRequestHandler.h"
#import "AFNetworking.h"
#import "Constants.h"

@implementation KDBJenkinsRequestHandler

- (void) importDetailsForJobWithURL:(NSURL *) jobURL andJenkinsInstance:(JenkinsInstance *) jinstance
{
    NSURL *requestURL = [NSURL URLWithString:@"api/json" relativeToURL:jobURL];
    NSLog(@"%@%@",@"Requesting details for Job at URL: ",requestURL.absoluteString);
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    manager.securityPolicy.allowInvalidCertificates = jinstance.allowInvalidSSLCertificate.boolValue;
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];

    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"response received for job at url: ",jobURL.absoluteString);
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [info setObject:jinstance forKey:JobJenkinsInstanceKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JobDetailResponseReceivedNotification object:self userInfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"failed to receive response for job at url: ",jobURL.absoluteString);
        // since the Job actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:jobURL forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:jinstance forKey:JobJenkinsInstanceKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JobDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        return urlRequest;
    }];
    
    [operation start];
}

- (void) importDetailsForView: (View *) view
{
    NSString *viewURL = view.url;
    NSURL *requestURL = [NSURL URLWithString:@"api/json" relativeToURL:[NSURL URLWithString:view.url]];
    NSLog(@"%@%@",@"Requesting details for View at URL: ",requestURL.absoluteString);
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    JenkinsInstance *jinstance = (JenkinsInstance *)view.rel_View_JenkinsInstance;
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    manager.securityPolicy.allowInvalidCertificates = jinstance.allowInvalidSSLCertificate.boolValue;
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ViewDetailResponseReceivedNotification object:self userInfo:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"failed to receive response for view at url: ",viewURL);
        // since the View actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:[NSURL URLWithString:viewURL] forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ViewDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        return urlRequest;
    }];
    
    [operation start];
}

- (void) importDetailsForActiveConfiguration: (ActiveConfiguration *) ac
{
    NSURL *requestURL = [NSURL URLWithString:@"api/json" relativeToURL:[NSURL URLWithString:ac.url]];
    NSLog(@"%@%@",@"Requesting details for ActiveConfiguration at URL: ",requestURL.absoluteString);
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    JenkinsInstance *jinstance = (JenkinsInstance *)ac.rel_ActiveConfiguration_Job.rel_Job_JenkinsInstance;
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    manager.securityPolicy.allowInvalidCertificates = jinstance.allowInvalidSSLCertificate.boolValue;
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];
    manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"response received for ActiveConfiguration at url: ",requestURL.absoluteString);
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [userInfo setObject:ac.rel_ActiveConfiguration_Job forKey:ActiveConfigurationJobKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ActiveConfigurationDetailResponseReceivedNotification object:self userInfo:userInfo];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"failed to receive response for ActiveConfiguration at url: ",requestURL.absoluteString);
        // since the AC actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:[NSURL URLWithString:ac.url] forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:ac.rel_ActiveConfiguration_Job forKey:ActiveConfigurationJobKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ActiveConfigurationDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        return urlRequest;
    }];
    
    [operation start];
}

- (void) importDetailsForBuild: (Build *) build
{
    NSURL *requestURL = [NSURL URLWithString:@"api/json" relativeToURL:[NSURL URLWithString:build.url]];
    NSLog(@"%@%@",@"Requesting details for Build at URL: ",requestURL.absoluteString);
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    JenkinsInstance *jinstance = (JenkinsInstance *)build.rel_Build_Job.rel_Job_JenkinsInstance;
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    manager.securityPolicy.allowInvalidCertificates = jinstance.allowInvalidSSLCertificate.boolValue;
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];
    manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"response received for Build at url: ",requestURL.absoluteString);
        [[NSNotificationCenter defaultCenter] postNotificationName:BuildDetailResponseReceivedNotification object:self userInfo:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"failed to receive response for Build at url: ",requestURL.absoluteString);
        // since the Build actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:[NSURL URLWithString:build.url] forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BuildDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        return urlRequest;
    }];
    
    [operation start];
}

- (void) importDetailsForJenkinsInstance: (JenkinsInstance *) jinstance
{
    NSURL *requestURL = [NSURL URLWithString:@"api/json" relativeToURL:[NSURL URLWithString:jinstance.url]];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    NSLog(@"%@%@",@"Requesting details for Jenkins at URL: ",requestURL.absoluteString);
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    NSURL *jinstanceURL = [NSURL URLWithString:jinstance.url];
    NSString *jinstanceName = jinstance.name;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    manager.securityPolicy.allowInvalidCertificates = jinstance.allowInvalidSSLCertificate.boolValue;
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];

    manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [userInfo setObject:jinstanceURL.absoluteString forKey:JenkinsInstanceURLKey];
        [userInfo setObject:jinstanceName forKey:JenkinsInstanceNameKey];
        [userInfo setObject:username forKey:JenkinsInstanceUsernameKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceDetailResponseReceivedNotification object:self userInfo:userInfo];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"failed to receive response for jenkins at url: ",requestURL.absoluteString);
        // since the JenkinsInstance actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:jinstanceURL forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
        [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        return urlRequest;
    }];
    
    [operation start];
}

/*
- (void) importTestResultsImageForJobAtURL:(NSURL *) jobURL
{
    NSURL *requestURL = [jobURL URLByAppendingPathComponent:@"test/trend"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"response received for test results image at url: ", requestURL);
        [[NSNotificationCenter defaultCenter] postNotificationName:JobTestResultsImageResponseReceivedNotification object:self userInfo:[NSDictionary dictionaryWithObject:jobURL forKey:JobURLKey]];
        [self persistTestResultsImage:responseObject forJobWithName:jobName];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) importProgressForBuild:(NSNumber *) buildNumber ofJobAtURL:(NSString *) jobURL
{
    NSString *buildURL = [NSString stringWithFormat:@"%@%d",jobURL,[buildNumber intValue]];
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@%@%@%@",buildURL,@"/api/json?tree=",BuildBuildingKey,@",",BuildTimestampKey,@",",BuildEstimatedDurationKey]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"response received for build progress at url: ",buildURL);
        
        NSNumber *building = [NSNumber numberWithBool:[[responseObject objectForKey:BuildBuildingKey] boolValue]];
        NSNumber *timestamp = [NSNumber numberWithDouble:[[responseObject objectForKey:BuildTimestampKey] doubleValue]];
        NSNumber *estimatedDuration = [NSNumber numberWithDouble:[[responseObject objectForKey:BuildEstimatedDurationKey] doubleValue]];

        NSArray *keys = [NSArray arrayWithObjects:JobURLKey,BuildNumberKey,BuildBuildingKey,BuildTimestampKey,BuildEstimatedDurationKey, nil];
        NSArray *objs = [NSArray arrayWithObjects:jobURL,buildNumber,building,timestamp,estimatedDuration,nil];

        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjects:objs forKeys:keys];
        [[NSNotificationCenter defaultCenter] postNotificationName:BuildProgressResponseReceivedNotification object:self userInfo:userInfoDict];

//        [self persistJobAtURL:jobURL withValues:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
} */

@end
