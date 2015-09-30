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

- (void) importDetailsForJob:(Job *) job;
{
    NSURL *requestURL = [NSURL URLWithString:@"api/json" relativeToURL:[NSURL URLWithString:job.url]];
    NSLog(@"%@%@",@"Requesting details for Job at URL: ",requestURL.absoluteString);
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    JenkinsInstance *jinstance = job.rel_Job_JenkinsInstance;
    NSString *username = job.rel_Job_JenkinsInstance.username;
    NSString *password = job.rel_Job_JenkinsInstance.password;
    BOOL shouldAuthenticate = [jinstance.shouldAuthenticate boolValue];
    NSString *jobURL = job.url;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    if (shouldAuthenticate) {
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];
        manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    }
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Response received for job at url: ",jobURL);
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [info setObject:job forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JobDetailResponseReceivedNotification object:self userInfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to receive response for job at url: ",jobURL);
        // since the Job actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:[NSURL URLWithString:jobURL] forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:job forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JobDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        if (shouldAuthenticate) {
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
            NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
            [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            return urlRequest;
        } else {
            return request;
        }
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
    BOOL shouldAuthenticate = [jinstance.shouldAuthenticate boolValue];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    if (shouldAuthenticate) {
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];
        manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    }

    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Response received for View at URL: ",viewURL);
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [info setObject:view forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ViewDetailResponseReceivedNotification object:self userInfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to receive response for View at URL: ",viewURL);
        // since the View actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:[NSURL URLWithString:viewURL] forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:view forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ViewDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        if (shouldAuthenticate) {
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
            NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
            [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            return urlRequest;
        } else {
            return request;
        }
    }];
    
    [operation start];
}

- (void) importChildViewsForView: (View *) view
{
    NSString *viewURL = view.url;
    NSURL *requestURL = [NSURL URLWithString:@"api/json?tree=name,url,views[name,url]" relativeToURL:[NSURL URLWithString:view.url]];
    NSLog(@"%@%@",@"Requesting child views for View at URL: ",requestURL.absoluteString);
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    
    JenkinsInstance *jinstance = (JenkinsInstance *)view.rel_View_JenkinsInstance;
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    BOOL shouldAuthenticate = [jinstance.shouldAuthenticate boolValue];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    if (shouldAuthenticate) {
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];
        manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    }
    
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Response received for View at URL: ",viewURL);
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [info setObject:view forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ViewChildViewsResponseReceivedNotification object:self userInfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to receive response for child views for View at URL: ",viewURL);
        // since the View actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:[NSURL URLWithString:viewURL] forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:view forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ViewChildViewsRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        if (shouldAuthenticate) {
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
            NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
            [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            return urlRequest;
        } else {
            return request;
        }
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
    BOOL shouldAuthenticate = [jinstance.shouldAuthenticate boolValue];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    
    if (shouldAuthenticate) {
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];
        manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    }
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Response received for ActiveConfiguration at url: ",requestURL.absoluteString);
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [info setObject:ac forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ActiveConfigurationDetailResponseReceivedNotification object:self userInfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to receive response for ActiveConfiguration at url: ",requestURL.absoluteString);
        // since the AC actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:[NSURL URLWithString:ac.url] forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:ac forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ActiveConfigurationDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        if (shouldAuthenticate) {
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
            NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
            [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            return urlRequest;
        } else {
            return request;
        }
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
    BOOL shouldAuthenticate = [jinstance.shouldAuthenticate boolValue];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    
    if (shouldAuthenticate) {
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:jinstance.username password:jinstance.password];
        manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    }
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Response received for Build at url: ",requestURL.absoluteString);
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [info setObject:build forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BuildDetailResponseReceivedNotification object:self userInfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to receive response for Build at url: ",requestURL.absoluteString);
        // since the Build actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:[NSURL URLWithString:build.url] forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:build forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:BuildDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        if (shouldAuthenticate) {
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
            NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
            [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            return urlRequest;
        } else {
            return request;
        }
    }];
    
    [operation start];
}

- (void) pingJenkinsInstance: (JenkinsInstance *) jinstance
{
    NSURL *requestURL = [NSURL URLWithString:@"login" relativeToURL:[NSURL URLWithString:jinstance.url]];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    NSURL *jinstanceURL = [NSURL URLWithString:jinstance.url];
    NSLog(@"%@%@",@"Pinging details for Jenkins at URL: ",requestURL.absoluteString);
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Ping response received for JenkinsInstance at url: ",jinstanceURL);
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstancePingResponseReceivedNotification object:self userInfo:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to receive ping response for jenkins at url: ",requestURL.absoluteString);
        // since the JenkinsInstance actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:jinstanceURL forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:jinstance forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstancePingRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation start];
}

- (void) authenticateJenkinsInstance:(JenkinsInstance *)jinstance
{
    NSURL *requestURL = [NSURL URLWithString:@"api/json?tree=nodeDescription" relativeToURL:[NSURL URLWithString:jinstance.url]];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    NSLog(@"%@%@",@"Authenticating with Jenkins at URL: ",requestURL.absoluteString);
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    NSURL *jinstanceURL = [NSURL URLWithString:jinstance.url];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    
    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];
    manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Authentication response received for JenkinsInstance at url: ",jinstanceURL);
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceAuthenticationResponseReceivedNotification object:self userInfo:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to authenticate with jenkins at url: ",requestURL.absoluteString);
        // since the JenkinsInstance actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:jinstanceURL forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:jinstance forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceAuthenticationRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        } else {
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
            NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
            [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            return urlRequest;
        }
    }];
    
    [operation start];
}

- (void) importDetailsForJenkinsInstance: (JenkinsInstance *) jinstance
{
    NSURL *requestURL = [NSURL URLWithString:@"api/json?tree=primaryView[name,url],views[name,url,jobs[name,url],views[name,url]]" relativeToURL:[NSURL URLWithString:jinstance.url]];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    NSLog(@"%@%@",@"Requesting details for Jenkins at URL: ",requestURL.absoluteString);
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    BOOL shouldAuthenticate = [jinstance.shouldAuthenticate boolValue];
    NSURL *jinstanceURL = [NSURL URLWithString:jinstance.url];
    //NSString *jinstanceName = jinstance.name;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];

    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    
    if (shouldAuthenticate) {
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];
        manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    }
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Response received for JenkinsInstance at url: ",jinstanceURL);
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [info setObject:jinstance forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceDetailResponseReceivedNotification object:self userInfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to receive response for jenkins at url: ",requestURL.absoluteString);
        // since the JenkinsInstance actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:jinstanceURL forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:jinstance forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceDetailRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        
        if (shouldAuthenticate) {
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
            NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
            [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            return urlRequest;
        } else {
            return request;
        }
    }];
    
    [operation start];
}

- (void) importViewsForJenkinsInstance: (JenkinsInstance *) jinstance
{
    NSURL *requestURL = [NSURL URLWithString:@"api/json?tree=views[name,url]" relativeToURL:[NSURL URLWithString:jinstance.url]];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    NSLog(@"%@%@",@"Requesting views for Jenkins at URL: ",requestURL.absoluteString);
    NSString *username = jinstance.username;
    NSString *password = jinstance.password;
    BOOL shouldAuthenticate = [jinstance.shouldAuthenticate boolValue];
    NSURL *jinstanceURL = [NSURL URLWithString:jinstance.url];
    //NSString *jinstanceName = jinstance.name;
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:requestURL];
    AFSecurityPolicy *secPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [secPolicy setValidatesDomainName:NO];
    [secPolicy setAllowInvalidCertificates:jinstance.allowInvalidSSLCertificate.boolValue];
    [manager setSecurityPolicy:secPolicy];
    [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
    
    if (shouldAuthenticate) {
        [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];
        manager.credential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
    }
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@%@",@"Response received for Views in JenkinsInstance at url: ",jinstanceURL);
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        [info setObject:jinstance forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceViewsResponseReceivedNotification object:self userInfo:info];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@%@",@"Failed to receive response for views in jenkins at url: ",requestURL.absoluteString);
        // since the JenkinsInstance actually exists, we need to inject it's url so that coredata can find it.
        NSMutableDictionary *errUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        [errUserInfo setObject:jinstanceURL forKey:NSErrorFailingURLKey];
        NSError *newError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:errUserInfo];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newError, nil] forKeys:[NSArray arrayWithObjects:RequestErrorKey, nil]];
        
        if (operation.response) {
            [info setObject:[NSNumber numberWithLong:[operation.response statusCode]] forKey:StatusCodeKey];
        }
        [info setObject:jinstance forKey:RequestedObjectKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceViewsRequestFailedNotification object:self userInfo:info];
    }];
    
    [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        if ([request.allHTTPHeaderFields objectForKey:@"Authorization"] != nil) {
            return request;
        }
        
        if (shouldAuthenticate) {
            NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
            NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
            NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
            NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]];
            [urlRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
            return urlRequest;
        } else {
            return request;
        }
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
