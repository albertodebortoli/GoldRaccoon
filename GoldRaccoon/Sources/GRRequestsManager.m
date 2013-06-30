//
//  GRRequestsManager.m
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 14/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRRequestsManager.h"

#import "GRListingRequest.h"
#import "GRCreateDirectoryRequest.h"
#import "GRUploadRequest.h"
#import "GRDownloadRequest.h"
#import "GRDeleteRequest.h"

#import "GRQueue.h"

@interface GRRequestsManager () <GRRequestDelegate, GRRequestDataSource>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, strong) GRQueue *requestQueue;
@property (nonatomic, strong) GRRequest *currentRequest;

- (id<GRRequestProtocol>)_addRequestOfType:(Class)clazz withPath:(NSString *)filePath;
- (id<GRDataExchangeRequestProtocol>)_addDataExchangeRequestOfType:(Class)clazz withLocalPath:(NSString *)localPath remotePath:(NSString *)remotePath;
- (void)_enqueueRequest:(id<GRRequestProtocol>)request;
- (void)_processNextRequest;

@end

@implementation GRRequestsManager
{
    NSMutableData *_currentDownloadData;
    NSData *_currentUploadData;
    BOOL _isRunning;
    
@private
    BOOL _delegateRespondsToPercentProgress;
}

@synthesize hostname = _hostname;
@synthesize delegate = _delegate;

#pragma mark - Dealloc and Initialization

- (instancetype)init
{
    NSAssert(NO, @"Initializer not allowed. Use designated initializer initWithHostname:username:password:");
    return nil;
}

- (instancetype)initWithHostname:(NSString *)hostname user:(NSString *)username password:(NSString *)password
{
    self = [super init];
    if (self) {
        _hostname = hostname;
        _username = username;
        _password = password;
        _requestQueue = [[GRQueue alloc] init];
        _isRunning = NO;
        _delegateRespondsToPercentProgress = NO;
    }
    return self;
}

- (void)dealloc
{
    [self stopAndCancelAllRequests];
}

#pragma mark - Setters

- (void)setDelegate:(id<GRRequestsManagerDelegate>)delegate
{
    if (_delegate != delegate) {
        _delegate = delegate;
        _delegateRespondsToPercentProgress = [_delegate respondsToSelector:@selector(requestsManager:didCompletePercent:forRequest:)];
    }
}

#pragma mark - Public Methods

- (void)startProcessingRequests
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_isRunning == NO) {
            _isRunning = YES;
            [self _processNextRequest];
        }
    });
}

- (void)stopAndCancelAllRequests
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.requestQueue clear];
        self.currentRequest.cancelDoesNotCallDelegate = TRUE;
        [self.currentRequest cancelRequest];
        self.currentRequest = nil;
        _isRunning = NO;
    });
}

- (BOOL)cancelRequest:(GRRequest *)request
{
    return [self.requestQueue removeObject:request];
}

#pragma mark - FTP Actions

- (id<GRRequestProtocol>)addRequestForListDirectoryAtPath:(NSString *)filePath
{
    return [self _addRequestOfType:[GRListingRequest class] withPath:filePath];
}

- (id<GRRequestProtocol>)addRequestForCreateDirectoryAtPath:(NSString *)filePath
{
    return [self _addRequestOfType:[GRCreateDirectoryRequest class] withPath:filePath];
}

- (id<GRRequestProtocol>)addRequestForDeleteFileAtPath:(NSString *)filePath
{
    return [self _addRequestOfType:[GRDeleteRequest class] withPath:filePath];
}

- (id<GRRequestProtocol>)addRequestForDeleteDirectoryAtPath:(NSString *)filePath
{
    return [self _addRequestOfType:[GRDeleteRequest class] withPath:filePath];
}

- (id<GRDataExchangeRequestProtocol>)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath
{
    return [self _addDataExchangeRequestOfType:[GRDownloadRequest class] withLocalPath:localPath remotePath:remotePath];
}

- (id<GRDataExchangeRequestProtocol>)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath
{
    return [self _addDataExchangeRequestOfType:[GRUploadRequest class] withLocalPath:localPath remotePath:remotePath];
}

#pragma mark - GRRequestDelegate required

- (void)requestCompleted:(GRRequest *)request
{
    // listing request
    if ([request isKindOfClass:[GRListingRequest class]]) {
        NSMutableArray *listing = [NSMutableArray array];
        for (NSDictionary *file in ((GRListingRequest *)request).filesInfo) {
            [listing addObject:[file objectForKey:(id)kCFFTPResourceName]];
        }
        if ([_delegate respondsToSelector:@selector(requestsManager:didCompleteListingRequest:listing:)]) {
            [self.delegate requestsManager:self
                 didCompleteListingRequest:((GRListingRequest *)request)
                                   listing:listing];
        }
    }
    
    // create directory request
    if ([request isKindOfClass:[GRCreateDirectoryRequest class]]) {
        if ([_delegate respondsToSelector:@selector(requestsManager:didCompleteCreateDirectoryRequest:)]) {
            [self.delegate requestsManager:self didCompleteCreateDirectoryRequest:(GRUploadRequest *)request];
        }
    }

    // delete request
    if ([request isKindOfClass:[GRUploadRequest class]]) {
        if ([_delegate respondsToSelector:@selector(requestsManager:didCompleteDeleteRequest:)]) {
            [self.delegate requestsManager:self didCompleteDeleteRequest:(GRUploadRequest *)request];
        }
    }

    // upload request
    if ([request isKindOfClass:[GRUploadRequest class]]) {
        if ([_delegate respondsToSelector:@selector(requestsManager:didCompleteUploadRequest:)]) {
            [self.delegate requestsManager:self didCompleteUploadRequest:(GRUploadRequest *)request];
        }
        _currentUploadData = nil;
    }
    
    // download request
    else if ([request isKindOfClass:[GRDownloadRequest class]]) {
        NSError *writeError = nil;
        BOOL writeToFileSucceeded = [_currentDownloadData writeToFile:((GRDownloadRequest *)request).localFilePath
                                                              options:NSDataWritingAtomic
                                                                error:&writeError];
        
        if (writeToFileSucceeded && !writeError) {
            if ([_delegate respondsToSelector:@selector(requestsManager:didCompleteDownloadRequest:)]) {
                [self.delegate requestsManager:self didCompleteDownloadRequest:(GRDownloadRequest *)request];
            }
        }
        else {
            if ([_delegate respondsToSelector:@selector(requestsManager:didFailWritingFileAtPath:forRequest:error:)]) {
                [self.delegate requestsManager:self
                      didFailWritingFileAtPath:((GRDownloadRequest *)request).localFilePath
                                    forRequest:(GRDownloadRequest *)request
                                         error:writeError];
            }
        }
        _currentDownloadData = nil;
    }
    
    [self _processNextRequest];
}

- (void)requestFailed:(GRRequest *)request
{
    if ([_delegate respondsToSelector:@selector(requestsManager:didFailRequest:withError:)]) {
        NSError *error = [NSError errorWithDomain:@"com.github.goldraccoon" code:-1000 userInfo:@{@"message": request.error.message}];
        [self.delegate requestsManager:self didFailRequest:request withError:error];
    }
    
    [self _processNextRequest];
}

#pragma mark - GRRequestDelegate optional

- (void)percentCompleted:(float)percent forRequest:(id<GRRequestProtocol>)request
{
    if (_delegateRespondsToPercentProgress) {
        [self.delegate requestsManager:self didCompletePercent:percent forRequest:request];
    }
}

////////////////////////////////////////////////////////////////////////////////
// description:	dataAvailable:forRequest: is used as part of the file download.
//
// important:   This is required to download data. If this method is missing
//              and you attempt to download, you will get a runtime error.
////////////////////////////////////////////////////////////////////////////////
- (void)dataAvailable:(NSData *)data forRequest:(id<GRDataExchangeRequestProtocol>)request
{
    [_currentDownloadData appendData:data];
}

- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<GRDataExchangeRequestProtocol>)request
{
    // called only with GRUploadRequest requests
    return YES;
}

#pragma mark - GRRequestDataSource

- (NSString *)hostnameForRequest:(id<GRRequestProtocol>)request
{
    return self.hostname;
}

- (NSString *)usernameForRequest:(id<GRRequestProtocol>)request
{
    return self.username;
}

- (NSString *)passwordForRequest:(id<GRRequestProtocol>)request
{
    return self.password;
}

////////////////////////////////////////////////////////////////////////////////
// important:   This is an optional method when uploading. It is purely used
//              to help calculate the percent completed.
//
//              If this method is missing, then the send size defaults to LONG_MAX
//              or about 2 gig.
////////////////////////////////////////////////////////////////////////////////
- (long)requestDataSendSize:(id<GRDataExchangeRequestProtocol>)request
{
    // user returns the total size of data to send. Used ONLY for percentComplete
    return [_currentUploadData length];
}

////////////////////////////////////////////////////////////////////////////////
// description:	requestDataToSend is designed to hand off the BR the next block
//              of data to upload to the FTP server. It continues to call this
//              method for more data until nil is returned.
//
// important:   This is a required method for uploading data to an FTP server.
//              If this method is missing, it you will get a runtime error indicating
//              this method is missing.
////////////////////////////////////////////////////////////////////////////////
- (NSData *)requestDataToSend:(id<GRDataExchangeRequestProtocol>)request
{
    // returns data object or nil when complete
    // basically, first time we return the pointer to the NSData.
    // and BR will upload the data.
    // Second time we return nil which means no more data to send
    NSData *temp = _currentUploadData;       // this is a shallow copy of the pointer, not a deep copy
    _currentUploadData = nil;                // next time around, return nil...
    return temp;
}

#pragma mark - Private Methods

- (id<GRRequestProtocol>)_addRequestOfType:(Class)clazz withPath:(NSString *)filePath
{
    id<GRRequestProtocol> request = [[clazz alloc] initWithDelegate:self datasource:self];
    request.path = filePath;
    
    [self _enqueueRequest:request];
    return request;
}

- (id<GRDataExchangeRequestProtocol>)_addDataExchangeRequestOfType:(Class)clazz withLocalPath:(NSString *)localPath remotePath:(NSString *)remotePath
{
    id<GRDataExchangeRequestProtocol> request = [[clazz alloc] initWithDelegate:self datasource:self];
    request.path = remotePath;
    request.localFilePath = localPath;
    
    [self _enqueueRequest:request];
    return request;
}

- (void)_enqueueRequest:(id<GRRequestProtocol>)request
{
    [self.requestQueue enqueue:request];
}

- (void)_processNextRequest
{
    self.currentRequest = [self.requestQueue dequeue];
    
    if (self.currentRequest == nil) {
        [self stopAndCancelAllRequests];
        return;
    }
    
    if ([self.currentRequest isKindOfClass:[GRDownloadRequest class]]) {
        _currentDownloadData = [NSMutableData dataWithCapacity:4096];
    }
    if ([self.currentRequest isKindOfClass:[GRUploadRequest class]]) {
        NSString *localFilepath = ((GRUploadRequest *)self.currentRequest).localFilePath;
        _currentUploadData = [NSData dataWithContentsOfFile:localFilepath];
    }
    
    [self.currentRequest start];
    [self.delegate requestsManager:self didStartRequest:self.currentRequest];
}

@end
