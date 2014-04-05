//
//  KDBJenkinsURLProtocol.m
//  JenkinsMobile
//
//  Largely lifted from ILTesting/ILCannedURLProtocol (https://github.com/InfiniteLoopDK/ILTesting)
//  Modified to be ARC compliant
//
//  Created by Kyle on 4/5/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJenkinsURLProtocol.h"

// Undocumented initializer obtained by class-dump - don't use this in production code destined for the App Store
@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

static id<KDBJenkinsURLProtocolDelegate> delegate = nil;

static void(^startLoadingBlock)(NSURLRequest *request) = nil;
static NSData *cannedResponseData = nil;
static NSDictionary *cannedHeaders = nil;
static NSInteger cannedStatusCode = 200;
static NSError *cannedError = nil;
static NSArray *supportedMethods = nil;
static NSArray *supportedSchemes = nil;
static NSURL *supportedBaseURL = nil;
static CGFloat responseDelay = 0;

@implementation KDBJenkinsURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
	BOOL canInit = YES;
    
	if (delegate && [delegate respondsToSelector:@selector(shouldInitWithRequest:)]) {
		canInit = [delegate shouldInitWithRequest:request];
	} else {
		canInit = (
				   (!supportedBaseURL || [request.URL.absoluteString hasPrefix:supportedBaseURL.absoluteString]) &&
				   (!supportedMethods || [supportedMethods containsObject:request.HTTPMethod]) &&
				   (!supportedSchemes || [supportedSchemes containsObject:request.URL.scheme])
				   );
	}
    
	return canInit;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

+ (void)setDelegate:(id<KDBJenkinsURLProtocolDelegate>)newdelegate {
	delegate = newdelegate;
}

+ (void)setCannedResponseData:(NSData*)data {
    cannedResponseData = data;
}

+ (void)setCannedHeaders:(NSDictionary*)headers {
    cannedHeaders = headers;
}

+ (void)setCannedStatusCode:(NSInteger)statusCode {
	cannedStatusCode = statusCode;
}

+ (void)setCannedError:(NSError*)error {
    cannedError = error;
}

- (NSCachedURLResponse *)cachedResponse {
	return nil;
}

+ (void)setSupportedMethods:(NSArray*)methods {
    supportedMethods=methods;
}

+ (void)setSupportedSchemes:(NSArray*)schemes {
    supportedSchemes=schemes;
}

+ (void)setSupportedBaseURL:(NSURL*)baseURL {
    supportedBaseURL=baseURL;
}

+ (void)setResponseDelay:(CGFloat)newresponseDelay {
	responseDelay = newresponseDelay;
}

- (void)startLoading {
    NSURLRequest *request = [self request];
	id<NSURLProtocolClient> client = [self client];
    
    if (startLoadingBlock) {
        startLoadingBlock(request);
    }
    
	NSInteger statusCode = cannedStatusCode;
	NSDictionary *headers = cannedHeaders;
	NSData *responseData = cannedResponseData;
    
    // Handle redirects
    if (delegate && [delegate respondsToSelector:@selector(redirectForClient:request:)]) {
        NSURL *redirectUrl = [delegate redirectForClient:client request:request];
        if (redirectUrl) {
            NSHTTPURLResponse *redirectResponse = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                                              statusCode:302
                                                                            headerFields: [NSDictionary dictionaryWithObject:[redirectUrl absoluteString] forKey:@"Location"]
                                                                             requestTime:0.0];
            
            [client URLProtocol:self wasRedirectedToRequest:[NSURLRequest requestWithURL:redirectUrl] redirectResponse:redirectResponse];
            return;
        }
    }
    
    
	if (cannedError) {
		[client URLProtocol:self didFailWithError:cannedError];
        
	} else {
        
		if (delegate && [delegate respondsToSelector:@selector(responseDataForClient:request:)]) {
            
			if ([delegate respondsToSelector:@selector(statusCodeForClient:request:)]) {
				statusCode  = [delegate statusCodeForClient:client request:request];
			}
            
			if ([delegate respondsToSelector:@selector(headersForClient:request:)]) {
				headers  = [delegate headersForClient:client request:request];
			}
            
			responseData = [delegate responseDataForClient:client request:request];
		}
        
        
		NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                                  statusCode:statusCode
                                                                headerFields:headers
                                                                 requestTime:0.0];
        
		[NSThread sleepForTimeInterval:responseDelay];        
        
		[client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		[client URLProtocol:self didLoadData:responseData];
		[client URLProtocolDidFinishLoading:self];
        
	}
}

@end
