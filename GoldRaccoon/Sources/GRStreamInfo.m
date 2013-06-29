//
//  GRStreamInfo.m
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

#import "GRStreamInfo.h"
#import "GRRequest.h"

@implementation GRStreamInfo

@synthesize writeStream;    
@synthesize readStream;
@synthesize bytesThisIteration;
@synthesize bytesTotal;
@synthesize timeout;
@synthesize cancelRequestFlag;
@synthesize cancelDoesNotCallDelegate;

/**
 @brief dispatch_get_local_queue() is designed to get our local queue, if it exists, or create one if it doesn't exist.
 @return queue of type dispatch_queue_t
 */
dispatch_queue_t dispatch_get_local_queue()
{
    static dispatch_queue_t _queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _queue = dispatch_queue_create("com.github.goldraccoon", 0);
        dispatch_queue_set_specific(_queue, "com.github.goldraccoon", (void*) "com.github.goldraccoon", NULL);
    });
    return _queue;
}

/**
 
 */
- (void)openRead:(GRRequest *)request
{
    if ([request.dataSource hostname] == nil) {
        InfoLog(@"The host name is nil!");
        request.error = [[GRError alloc] init];
        request.error.errorCode = kGRFTPClientHostnameIsNil;
        [request.delegate requestFailed: request];
        [request.streamInfo close: request];
        return;
    }
    
    // a little bit of C because I was not able to make NSInputStream play nice
    CFReadStreamRef readStreamRef = CFReadStreamCreateWithFTPURL(NULL, ( __bridge CFURLRef) request.fullURL);
    
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPUsePassiveMode, request.passiveMode ? kCFBooleanTrue :kCFBooleanFalse);
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPFetchResourceInfo, kCFBooleanTrue);
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPUserName, (__bridge CFStringRef) [request.dataSource username]);
    CFReadStreamSetProperty(readStreamRef, kCFStreamPropertyFTPPassword, (__bridge CFStringRef) [request.dataSource password]);
    readStream = ( __bridge_transfer NSInputStream *) readStreamRef;
    
    if (readStream==nil)
    {
        InfoLog(@"Can't open the read stream! Possibly wrong URL");
        request.error = [[GRError alloc] init];
        request.error.errorCode = kGRFTPClientCantOpenStream;
        [request.delegate requestFailed: request];
        [request.streamInfo close: request];
        return;
    }
    
    readStream.delegate = request;
	[readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[readStream open];
    
    request.didOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC), dispatch_get_local_queue(), ^{
        if (!request.didOpenStream && request.error == nil)
        {
            InfoLog(@"No response from the server. Timeout.");
            request.error = [[GRError alloc] init];
            request.error.errorCode = kGRFTPClientStreamTimedOut;
            [request.delegate requestFailed: request];
            [request.streamInfo close: request];
        }
    });
}

/**
 
 */
- (void)openWrite:(GRRequest *)request
{
    if ([request.dataSource hostname] == nil) {
        InfoLog(@"The host name is nil!");
        request.error = [[GRError alloc] init];
        request.error.errorCode = kGRFTPClientHostnameIsNil;
        [request.delegate requestFailed: request];
        [request.streamInfo close: request];
        return;
    }
    
    CFWriteStreamRef writeStreamRef = CFWriteStreamCreateWithFTPURL(NULL, ( __bridge CFURLRef) request.fullURL);
    
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPUsePassiveMode, request.passiveMode ? kCFBooleanTrue :kCFBooleanFalse);
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPFetchResourceInfo, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPUserName, (__bridge CFStringRef) [request.dataSource username]);
    CFWriteStreamSetProperty(writeStreamRef, kCFStreamPropertyFTPPassword, (__bridge CFStringRef) [request.dataSource password]);
    
    writeStream = ( __bridge_transfer NSOutputStream *) writeStreamRef;
    
    if (writeStream == nil)
    {
        InfoLog(@"Can't open the write stream! Possibly wrong URL!");
        request.error = [[GRError alloc] init];
        request.error.errorCode = kGRFTPClientCantOpenStream;
        [request.delegate requestFailed: request];
        [request.streamInfo close: request];
        return;
    }
    
    writeStream.delegate = request;
    [writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [writeStream open];
    
    request.didOpenStream = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC), dispatch_get_local_queue(), ^{
        if (!request.didOpenStream && request.error==nil)
        {
            InfoLog(@"No response from the server. Timeout.");
            request.error = [[GRError alloc] init];
            request.error.errorCode = kGRFTPClientStreamTimedOut;
            [request.delegate requestFailed:request];
            [request.streamInfo close: request];
        }
    });
}

/**
 
 */
- (BOOL)checkCancelRequest:(GRRequest *)request
{
    if (!cancelRequestFlag) {
        return NO;
    }
    
    // see if we don't want to call the delegate (set and forget)
    if (cancelDoesNotCallDelegate == YES) {
        [request.streamInfo close: request];
    }
    
    // otherwise indicate that the request to cancel was completed
    else {
        [request.delegate requestCompleted: request];
        [request.streamInfo close: request];
    }
    
    return YES;
}

/**
 
 */
- (NSData *)read:(GRRequest *)request
{
    NSData *data;
    NSMutableData *bufferObject = [NSMutableData dataWithLength:kGRDefaultBufferSize];

    bytesThisIteration = [readStream read: (UInt8 *) [bufferObject bytes] maxLength:kGRDefaultBufferSize];
    bytesTotal += bytesThisIteration;
    
    // return the data
    if (bytesThisIteration > 0) {
        data = [NSData dataWithBytes: (UInt8 *) [bufferObject bytes] length: bytesThisIteration];
        request.percentCompleted = bytesTotal / request.maximumSize;
        
        if ([request.delegate respondsToSelector:@selector(percentCompleted:)]) {
            [request.delegate percentCompleted: request];
        }
        
        return data;
    }
    
    // return no data, but this isn't an error... just the end of the file
    else if (bytesThisIteration == 0) {
        return [NSData data]; // returns empty data object - means no error, but no data
    }
    // otherwise we had an error, return an error
    [self streamError: request errorCode:kGRFTPClientCantReadStream];
    InfoLog(@"%@", request.error.message);
    
    return nil;
}

/**
 
 */
- (BOOL)write:(GRRequest *)request data:(NSData *)data
{
    bytesThisIteration = [writeStream write: [data bytes] maxLength: [data length]];
    bytesTotal += bytesThisIteration;
            
    if (bytesThisIteration > 0) {
        request.percentCompleted = bytesTotal / request.maximumSize;
        if ([request.delegate respondsToSelector:@selector(percentCompleted:)]) {
            [request.delegate percentCompleted: request];
        }
        
        return YES;
    }
    
    if (bytesThisIteration == 0) {
        return YES;
    }
    
    [self streamError: request errorCode:kGRFTPClientCantWriteStream]; // perform callbacks and close out streams
    InfoLog(@"%@", request.error.message);

    return NO;
}

/**
 
 */
- (void)streamError:(GRRequest *)request errorCode:(enum BRErrorCodes)errorCode
{
    request.error = [[GRError alloc] init];
    request.error.errorCode = errorCode;
    [request.delegate requestFailed: request];
    [request.streamInfo close: request];
}

/**
 
 */
- (void)streamComplete:(GRRequest *)request
{
    [request.delegate requestCompleted: request];
    [request.streamInfo close: request];
}

/**
 
 */
- (void)close:(GRRequest *)request
{
    if (readStream) {
        [readStream close];
        [readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        readStream = nil;
    }
    
    if (writeStream) {
        [writeStream close];
        [writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        writeStream = nil;
    }
    
    request.streamInfo = nil;
}

@end
