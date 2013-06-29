//
//  GRRequestDelegate.h
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

#import <Foundation/Foundation.h>

@class GRRequest;
@class GRRequestDownload;
@class GRRequestUpload;
@class GRRequestError;
@class GRStreamInfo;

@protocol GRRequestProtocol <NSObject>

@property BOOL passiveMode;
@property NSString *uuid;

@property NSString *username;
@property NSString *password;
@property NSString *hostname;

@property (readonly) NSURL *fullURL;
@property NSString *path;
@property (strong) GRRequestError *error;
@property float maximumSize;
@property float percentCompleted;
@property long timeout;

@property GRStreamInfo *streamInfo;
@property BOOL didOpenStream;               // whether the stream opened or not
@property (readonly) long bytesSent;        // will have bytes from the last FTP call
@property (readonly) long totalBytesSent;   // will have bytes total sent
@property BOOL cancelDoesNotCallDelegate;   // cancel closes stream without calling delegate

- (NSURL *)fullURLWithEscape;
- (void)start;
- (void)cancelRequest;

@end

@protocol GRRequestDelegate <NSObject>

@required
/**
 @param request The request object
 */
- (void)requestCompleted:(GRRequest *)request;

/**
 @param request The request object
 */
- (void)requestFailed:(GRRequest *)request;

/**
 @param request The request object
 */
- (BOOL)shouldOverwriteFileWithRequest:(GRRequest *)request;

@optional
- (void)percentCompleted:(GRRequest *) request;
- (void)requestDataAvailable:(GRRequestDownload *)request;
- (long)requestDataSendSize:(GRRequestUpload *)request;
- (NSData *)requestDataToSend:(GRRequestUpload *)request;

@end

