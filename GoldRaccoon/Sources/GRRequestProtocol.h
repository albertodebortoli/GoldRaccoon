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
- (void)requestCompleted:(id<GRRequestProtocol>)request;
- (void)requestFailed:(id<GRRequestProtocol>)request;

@optional
- (void)percentCompleted:(float)percent forRequest:(id<GRRequestProtocol>)request;
- (void)dataAvailable:(NSData *)data forRequest:(id<GRDataExchangeRequestProtocol>)request;
- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<GRDataExchangeRequestProtocol>)request;

@end

@protocol GRRequestDataSource <NSObject>

@required
- (NSString *)hostnameForRequest:(id<GRRequestProtocol>)request;
- (NSString *)usernameForRequest:(id<GRRequestProtocol>)request;
- (NSString *)passwordForRequest:(id<GRRequestProtocol>)request;

@optional
- (long)requestDataSendSize:(id<GRDataExchangeRequestProtocol>)request;
- (NSData *)requestDataToSend:(id<GRDataExchangeRequestProtocol>)request;

@end
