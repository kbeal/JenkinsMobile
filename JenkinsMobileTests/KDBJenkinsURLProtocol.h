//
//  KDBJenkinsURLProtocol.h
//  JenkinsMobile
//
//  Created by Kyle on 4/5/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KDBJenkinsURLProtocolDelegate <NSObject>
- (NSData*)responseDataForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest*)request;
@optional
- (BOOL)shouldInitWithRequest:(NSURLRequest*)request;
- (NSURL *)redirectForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest *)request;
- (NSInteger)statusCodeForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest*)request;
- (NSDictionary*)headersForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest*)request;
@end

@interface KDBJenkinsURLProtocol : NSURLProtocol
//+ (void)setStartLoadingBlock:(void(^)(NSURLRequest *request))block;
+ (void)setDelegate:(id<KDBJenkinsURLProtocolDelegate>)delegate;

+ (void)setCannedResponseData:(NSData*)data;
+ (void)setCannedHeaders:(NSDictionary*)headers;
+ (void)setCannedStatusCode:(NSInteger)statusCode;
+ (void)setCannedError:(NSError*)error;

+ (void)setSupportedMethods:(NSArray*)methods;
+ (void)setSupportedSchemes:(NSArray*)schemes;
+ (void)setSupportedBaseURL:(NSURL*)baseURL;

+ (void)setResponseDelay:(CGFloat)responseDelay;
@end
