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
@class GRDownloadRequest;
@class GRUploadRequest;
@class GRError;
@class GRStreamInfo;

@protocol GRRequestProtocol <NSObject>

@property BOOL passiveMode;
@property NSString *uuid;

@property (readonly) NSURL *fullURL;
@property NSString *path;
@property (strong) GRError *error;
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

@protocol GRDataExchangeRequestProtocol <GRRequestProtocol>

@property (nonatomic, copy) NSString *localFilepath;
@property (nonatomic, readonly) NSString *fullRemotePath;

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
- (void)percentCompleted:(GRRequest *)request;
- (void)dataAvailable:(NSData *)data forRequest:(GRDownloadRequest *)request;
- (long)requestDataSendSize:(GRUploadRequest *)request;
- (NSData *)requestDataToSend:(GRUploadRequest *)request;

@end

@protocol GRRequestDataSource <NSObject>

@required
- (NSString *)hostname;
- (NSString *)username;
- (NSString *)password;

@end
