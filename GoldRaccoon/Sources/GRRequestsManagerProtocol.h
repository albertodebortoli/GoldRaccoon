//
//  GRRequestsManagerProtocol.h
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 17/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GRRequest;
@class GRCreateDirectoryRequest;
@class GRDeleteRequest;
@class GRListingRequest;
@class GRDownloadRequest;
@class GRUploadRequest;
@class GRDeleteRequest;
@protocol GRRequestProtocol;
@protocol GRRequestsManagerProtocol;

@protocol GRRequestsManagerDelegate <NSObject>

@optional
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didStartRequest:(id<GRRequestProtocol>)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestUpload:(GRUploadRequest *)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestDownload:(GRDownloadRequest *)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestListing:(GRListingRequest *)request listing:(NSArray *)listing;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(id<GRRequestProtocol>)request error:(NSError *)error;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(id<GRRequestProtocol>)request withError:(NSError *)error;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(id<GRRequestProtocol>)request;

@end

@protocol GRRequestsManagerProtocol <NSObject>

@property (nonatomic, copy) NSString *hostname;

- (GRCreateDirectoryRequest *)addRequestForCreateDirectoryAtPath:(NSString *)path;
- (GRDeleteRequest *)addRequestForDeleteDirectoryAtPath:(NSString *)path;
- (GRListingRequest *)addRequestForListDirectoryAtPath:(NSString *)path;
- (GRDownloadRequest *)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath;
- (GRUploadRequest *)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath;
- (GRDeleteRequest *)addRequestForDeleteFileAtPath:(NSString *)filepath;

- (void)startProcessingRequests;
- (void)stopAndCancelAllRequests;
- (BOOL)cancelRequest:(id<GRRequestProtocol>)request;

@end
