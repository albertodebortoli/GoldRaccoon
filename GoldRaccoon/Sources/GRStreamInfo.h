//
//  GRStreamInfo.h
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

#import "GRGlobal.h"
#import "GRError.h"

#define kGRDefaultBufferSize 32768

@class GRRequest;

@interface GRStreamInfo : NSObject
{
    NSOutputStream *writeStream;    
    NSInputStream *readStream;
}

@property (strong) NSOutputStream *writeStream;    
@property (strong) NSInputStream *readStream;
@property long bytesThisIteration;
@property long bytesTotal;
@property long timeout;
@property BOOL cancelRequestFlag;
@property BOOL cancelDoesNotCallDelegate;

- (void)openRead:(GRRequest *)request;
- (void)openWrite:(GRRequest *)request;
- (BOOL)checkCancelRequest:(GRRequest *)request;
- (NSData *)read:(GRRequest *)request;
- (BOOL)write:(GRRequest *)request data:(NSData *)data;
- (void)streamError:(GRRequest *)request errorCode:(enum BRErrorCodes)errorCode;
- (void)streamComplete:(GRRequest *)request;
- (void)close:(GRRequest *)request;

@end
