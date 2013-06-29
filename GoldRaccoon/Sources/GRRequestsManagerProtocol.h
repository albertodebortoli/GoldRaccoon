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
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestUpload:(id<GRDataExchangeRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestDownload:(id<GRDataExchangeRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestListing:(id<GRRequestProtocol>)request listing:(NSArray *)listing;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(id<GRRequestProtocol>)request error:(NSError *)error;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(id<GRRequestProtocol>)request withError:(NSError *)error;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(id<GRRequestProtocol>)request;

@end

@protocol GRRequestsManagerProtocol <NSObject>

@property (nonatomic, copy) NSString *hostname;

- (id<GRRequestProtocol>)addRequestForCreateDirectoryAtPath:(NSString *)path;
- (id<GRRequestProtocol>)addRequestForDeleteDirectoryAtPath:(NSString *)path;
- (id<GRRequestProtocol>)addRequestForListDirectoryAtPath:(NSString *)path;
- (id<GRDataExchangeRequestProtocol>)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath;
- (id<GRDataExchangeRequestProtocol>)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath;
- (id<GRRequestProtocol>)addRequestForDeleteFileAtPath:(NSString *)filepath;

- (void)startProcessingRequests;
- (void)stopAndCancelAllRequests;
- (BOOL)cancelRequest:(id<GRRequestProtocol>)request;

@end
