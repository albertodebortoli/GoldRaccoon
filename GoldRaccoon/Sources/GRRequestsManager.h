//
//  GRRequestsManager.h
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 14/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GRRequestsManagerProtocol.h"

/**
 Instances of this class manage a queue of requests against an FTP server.
 The different request types are: create directory, delete directory, list directory, download file, upload file, delete file.
 As soon as the requests are submitted to the GRRequestsManager, they are queued in a FIFO queue.
 The FTP Manager must be started with the startProcessingRequests method and can be shut down with the stopAndCancelAllRequests method.
 When processed, the requests are executed one at a time (max concurrency = 1).
 When no more requests are in the queue the GRRequestsManager automatically shut down.
*/
@interface GRRequestsManager : NSObject <GRRequestsManagerProtocol>

@property (nonatomic, weak) id<GRRequestsManagerDelegate> delegate;

- (instancetype)initWithHostname:(NSString *)hostname user:(NSString *)username password:(NSString *)password;

@end
