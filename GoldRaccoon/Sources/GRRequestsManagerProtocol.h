//
//  GRRequestsManagerProtocol.h
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 17/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GRRequest;
@class GRRequestCreateDirectory;
@class GRRequestDelete;
@class GRRequestListDirectory;
@class GRRequestDownload;
@class GRRequestUpload;
@class GRRequestDelete;
@protocol GRRequestsManagerProtocol;

@protocol GRRequestsManagerDelegate <NSObject>

@optional
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didStartRequest:(GRRequest *)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestUpload:(GRRequestUpload *)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestDownload:(GRRequestDownload *)request;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteRequestListing:(GRRequestListDirectory *)request listing:(NSArray *)listing;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(GRRequest *)request error:(NSError *)error;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(GRRequest *)request withError:(NSError *)error;
- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(GRRequest *)request;

@end

@protocol GRRequestsManagerProtocol <NSObject>

@property (nonatomic, copy) NSString *hostname;

- (GRRequestCreateDirectory *)addRequestForCreateDirectoryAtPath:(NSString *)path;
- (GRRequestDelete *)addRequestForDeleteDirectoryAtPath:(NSString *)path;
- (GRRequestListDirectory *)addRequestForListDirectoryAtPath:(NSString *)path;
- (GRRequestDownload *)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath;
- (GRRequestUpload *)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath;
- (GRRequestDelete *)addRequestForDeleteFileAtPath:(NSString *)filepath;

- (void)startProcessingRequests;
- (void)stopAndCancelAllRequests;
- (BOOL)cancelRequest:(GRRequest *)request;

@end
