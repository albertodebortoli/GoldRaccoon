//
//  GRRequestsManagerProtocol.h
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 17/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GRRequestProtocol;
@protocol GRDataExchangeRequestProtocol;
@protocol GRRequestsManagerProtocol;

@protocol GRRequestsManagerDelegate <NSObject>

@optional
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didStartRequest:(id<GRRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteListingRequest:(id<GRRequestProtocol>)request listing:(NSArray *)listing;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteCreateDirectoryRequest:(id<GRRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDeleteRequest:(id<GRRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(id<GRRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteUploadRequest:(id<GRDataExchangeRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDownloadRequest:(id<GRDataExchangeRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(id<GRDataExchangeRequestProtocol>)request error:(NSError *)error;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(id<GRRequestProtocol>)request withError:(NSError *)error;

@end

@protocol GRRequestsManagerProtocol <NSObject>

@property (nonatomic, copy) NSString *hostname;

- (id<GRRequestProtocol>)addRequestForListDirectoryAtPath:(NSString *)filePath;
- (id<GRRequestProtocol>)addRequestForCreateDirectoryAtPath:(NSString *)filePath;
- (id<GRRequestProtocol>)addRequestForDeleteFileAtPath:(NSString *)filePath;
- (id<GRRequestProtocol>)addRequestForDeleteDirectoryAtPath:(NSString *)filePath;
- (id<GRDataExchangeRequestProtocol>)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath;
- (id<GRDataExchangeRequestProtocol>)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath;

- (void)startProcessingRequests;
- (void)stopAndCancelAllRequests;
- (BOOL)cancelRequest:(id<GRRequestProtocol>)request;

@end
