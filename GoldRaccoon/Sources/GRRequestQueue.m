//
//  GRRequestQueue.m
//  GoldRaccoon
//
//  Created by Valentin Radu on 8/23/11.
//  Copyright 2011 Valentin Radu. All rights reserved.
//
//  Modified and/or redesigned by Lloyd Sargent to be ARC compliant.
//  Copyright 2012 Lloyd Sargent. All rights reserved.
//
//  Modified and redesigned by Alberto De Bortoli.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRRequestQueue.h"

@implementation GRRequestQueue

@synthesize queueDelegate;

/**
 
 */
- (id)init
{
    self = [super init];
    if (self) {
        headRequest = nil;
        tailRequest = nil;
    }
    return self;
}

/**
 
 */
- (void)addRequest:(GRRequest *)request
{
    request.delegate = self;
    
    if (request.password == nil) {
        request.password = self.password;
    }
    if (request.username == nil) {
        request.username = self.username;
    }
    if (request.hostname == nil) {
        request.hostname = self.hostname;
    }
    
    if (tailRequest == nil) {
        tailRequest = request;
    }
    else {
        tailRequest.nextRequest = request;
        request.prevRequest = tailRequest;
        tailRequest = request;
    }
    
    if (headRequest == nil) {
        headRequest = tailRequest;        
    }    
}

/**
 
 */
- (void)addRequestInFront:(GRRequest *)request
{
    request.delegate = self;
    if (request.password == nil) {
        request.password = self.password;
    }
    if (request.username == nil) {
        request.username = self.username;
    }
    if (request.hostname == nil) {
        request.hostname = self.hostname;
    }
    
    if (headRequest != nil) {
        request.nextRequest = headRequest.nextRequest;
        request.nextRequest.prevRequest = request;
        
        headRequest.nextRequest = request;
        request.prevRequest = headRequest.nextRequest;
    }
    else {
        InfoLog(@"Adding in front of the queue request at least one element already in the queue. Use 'addRequest' otherwise.");
        return;
    }
    
    if (tailRequest == nil) {
        tailRequest = request;        
    }
}

/**
 
 */
- (void)addRequestsFromArray:(NSArray *)array
{
    //TBD
}

/**
 
 */
- (void)removeRequestFromQueue:(GRRequest *)request
{
    if ([headRequest isEqual:request]) {
        headRequest = request.nextRequest;
    }
    
    if ([tailRequest isEqual:request]) {
        tailRequest = request.prevRequest;
    }
    
    request.prevRequest.nextRequest = request.nextRequest;
    request.nextRequest.prevRequest = request.prevRequest;
    
    request.nextRequest = nil;
    request.prevRequest = nil;
}

/**
 
 */
- (void)start
{
    [headRequest start];
}

/**
 
 */
- (void)requestCompleted:(GRRequest *)request
{
    [self.queueDelegate requestCompleted:request];
    
    headRequest = headRequest.nextRequest;
    
    if (headRequest==nil) {
        [self.queueDelegate queueCompleted:self];
    }
    else {
        [headRequest start]; 
    }
}

/**
 
 */
- (void)requestFailed:(GRRequest *)request
{
    [self.queueDelegate requestFailed:request];
    
    headRequest = headRequest.nextRequest;    
    
    [headRequest start];
}

/**
 
 */
- (BOOL)shouldOverwriteFileWithRequest:(GRRequest *)request
{
    if (![self.queueDelegate respondsToSelector:@selector(shouldOverwriteFileWithRequest:)]) {
        return NO;
    }
    else {
        return [self.queueDelegate shouldOverwriteFileWithRequest:request];
    }
}

@end
