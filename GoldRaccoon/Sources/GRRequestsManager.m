//
//  GRRequestsManager.m
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 14/06/2013.
//  Copyright 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRRequestsManager.h"

#import "GRRequestListDirectory.h"
#import "GRRequestCreateDirectory.h"
#import "GRRequestUpload.h"
#import "GRRequestDownload.h"
#import "GRRequestDelete.h"

#import "GRQueue.h"

@interface GRRequestsManager () <GRRequestDelegate>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, strong) GRQueue *requestQueue;
@property (nonatomic, strong) GRRequest *currentRequest;

- (void)_fillRequestWithHostAndCredentials:(GRRequest **)request;
- (void)_enqueueRequest:(GRRequest *)request;
- (void)_processNextRequest;

@end

@implementation GRRequestsManager
{
    NSMutableData *_currentDownloadData;
    NSData *_currentUploadData;
    BOOL _isRunning;
    
@private
    BOOL _delegateRespondsToUploadCompletion;
    BOOL _delegateRespondsToDownloadCompletion;
    BOOL _delegateRespondsToFailure;
    BOOL _delegateRespondsToWritingFailure;
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
        _delegateRespondsToUploadCompletion = NO;
        _delegateRespondsToDownloadCompletion = NO;
        _delegateRespondsToFailure = NO;
        _delegateRespondsToWritingFailure = NO;
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
        _delegateRespondsToUploadCompletion = [_delegate respondsToSelector:@selector(ftpRequestsManager:didCompleteRequestUpload:)];
        _delegateRespondsToDownloadCompletion = [_delegate respondsToSelector:@selector(ftpRequestsManager:didCompleteRequestDownload:)];
        _delegateRespondsToFailure = [_delegate respondsToSelector:@selector(ftpRequestsManager:didFailRequest:withError:)];
        _delegateRespondsToWritingFailure = [_delegate respondsToSelector:@selector(ftpRequestsManager:didFailWritingFileAtPath:forRequest:error:)];
        _delegateRespondsToPercentProgress = [_delegate respondsToSelector:@selector(ftpRequestsManager:didCompletePercent:forRequest:)];
    }
}

#pragma mark - Public Methods

- (void)startProcessingRequests
{
    if (_isRunning == NO) {
        _isRunning = YES;
        [self _processNextRequest];
    }
}

- (void)stopAndCancelAllRequests
{
    [self.requestQueue clear];
    self.currentRequest.cancelDoesNotCallDelegate = TRUE;
    [self.currentRequest cancelRequest];
    self.currentRequest = nil;
    _isRunning = NO;
}

- (BOOL)cancelRequest:(GRRequest *)request
{
    return [self.requestQueue removeObject:request];
}

#pragma mark - FTP Actions

- (GRRequestCreateDirectory *)addRequestForCreateDirectoryAtPath:(NSString *)path
{
    GRRequestCreateDirectory *request = [[GRRequestCreateDirectory alloc] initWithDelegate:self];
    [self _fillRequestWithHostAndCredentials:&request];
    request.path = path;
    
    [self _enqueueRequest:request];
    return request;
}

- (GRRequestDelete *)addRequestForDeleteDirectoryAtPath:(NSString *)path
{
    GRRequestDelete *request = [[GRRequestDelete alloc] initWithDelegate:self];
    [self _fillRequestWithHostAndCredentials:&request];
    request.path = path;
    
    [self _enqueueRequest:request];
    return request;
}

- (GRRequestListDirectory *)addRequestForListDirectoryAtPath:(NSString *)path
{
    GRRequestListDirectory *request = [[GRRequestListDirectory alloc] initWithDelegate:self];
    [self _fillRequestWithHostAndCredentials:&request];
    request.path = path;
    
    [self _enqueueRequest:request];
    return request;
}

- (GRRequestDownload *)addRequestForDownloadFileAtRemotePath:(NSString *)remotePath toLocalPath:(NSString *)localPath
{
    GRRequestDownload *request = [[GRRequestDownload alloc] initWithDelegate:self];
    [self _fillRequestWithHostAndCredentials:&request];
    request.path = remotePath;
    request.localFilepath = localPath;
    
    [self _enqueueRequest:request];
    return request;
}

- (GRRequestUpload *)addRequestForUploadFileAtLocalPath:(NSString *)localPath toRemotePath:(NSString *)remotePath
{
    GRRequestUpload *request = [[GRRequestUpload alloc] initWithDelegate:self];
    [self _fillRequestWithHostAndCredentials:&request];
    request.path = remotePath;
    request.localFilepath = localPath;
    
    [self _enqueueRequest:request];
    return request;
}

- (GRRequestDelete *)addRequestForDeleteFileAtPath:(NSString *)filepath
{
    GRRequestDelete *request = [[GRRequestDelete alloc] initWithDelegate:self];
    [self _fillRequestWithHostAndCredentials:&request];
    request.path = filepath;
    
    [self _enqueueRequest:request];
    return request;
}

#pragma mark - GRRequestDelegate required

- (void)requestCompleted:(GRRequest *)request
{
    if ([request isKindOfClass:[GRRequestUpload class]]) {
        if (_delegateRespondsToUploadCompletion) {
            [self.delegate ftpRequestsManager:self didCompleteRequestUpload:(GRRequestUpload *)request];
        }
        _currentUploadData = nil;
    }
    
    else if ([request isKindOfClass:[GRRequestDownload class]]) {
        NSError *writeError = nil;
        BOOL writeToFileSucceeded = [_currentDownloadData writeToFile:((GRRequestDownload *)request).localFilepath
                                                              options:NSDataWritingAtomic
                                                                error:&writeError];
        
        if (writeToFileSucceeded && !writeError) {
            if (_delegateRespondsToDownloadCompletion) {
                [self.delegate ftpRequestsManager:self didCompleteRequestDownload:(GRRequestDownload *)request];
            }
        }
        else {
            if (_delegateRespondsToWritingFailure) {
                [self.delegate ftpRequestsManager:self
                        didFailWritingFileAtPath:((GRRequestDownload *)request).localFilepath
                                      forRequest:request
                                           error:writeError];
            }
        }
        _currentDownloadData = nil;
    }
    
    // for listing
    // for (NSDictionary *file in (((GRRequestListDirectory *)request).filesInfo)
    // {
    //     NSLog(@"%@", [file objectForKey:(id)kCFFTPResourceName]);
    // }
    
    [self _processNextRequest];
}

- (void)requestFailed:(GRRequest *)request
{
    if (_delegateRespondsToFailure) {
        NSError *error = [NSError errorWithDomain:@"com.ef.e1.classroom.dpw.ftpservice" code:-1000 userInfo:@{@"message": request.error.message}];
        if (_delegateRespondsToFailure) {
            [self.delegate ftpRequestsManager:self didFailRequest:request withError:error];
        }
    }
    
    [self _processNextRequest];
}

- (BOOL)shouldOverwriteFileWithRequest:(GRRequest *)request
{
    // called only with GRRequestUpload requests 
    return YES;
}

#pragma mark - GRRequestDelegate optional

- (void)percentCompleted:(GRRequest *)request
{
    if (_delegateRespondsToPercentProgress) {
        [self.delegate ftpRequestsManager:self didCompletePercent:request.percentCompleted forRequest:request];
    }
    
    //NSLog(@"%f completed...", request.percentCompleted);
    //NSLog(@"%ld bytes this iteration", request.bytesSent);
    //NSLog(@"%ld total bytes", request.totalBytesSent);
}

////////////////////////////////////////////////////////////////////////////////
// important:   This is an optional method when uploading. It is purely used
//              to help calculate the percent completed.
//
//              If this method is missing, then the send size defaults to LONG_MAX
//              or about 2 gig.
////////////////////////////////////////////////////////////////////////////////
- (long)requestDataSendSize:(GRRequestUpload *)request
{
    // user returns the total size of data to send. Used ONLY for percentComplete
    return [_currentUploadData length];
}

////////////////////////////////////////////////////////////////////////////////
// description:	requestDataAvailable is used as part of the file download.
//
// important:   This is required to download data. If this method is missing
//              and you attempt to download, you will get a runtime error.
////////////////////////////////////////////////////////////////////////////////
- (void)requestDataAvailable:(GRRequestDownload *)request;
{
    [_currentDownloadData appendData:request.receivedData];
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
- (NSData *)requestDataToSend:(GRRequestUpload *)request
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

- (void)_fillRequestWithHostAndCredentials:(GRRequest **)request
{
    ((GRRequest *)*request).hostname = self.hostname;
    ((GRRequest *)*request).username = self.username;
    ((GRRequest *)*request).password = self.password;
}

- (void)_enqueueRequest:(GRRequest *)request
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
    
    if ([self.currentRequest isKindOfClass:[GRRequestDownload class]]) {
        _currentDownloadData = [NSMutableData dataWithCapacity:1];
    }
    if ([self.currentRequest isKindOfClass:[GRRequestUpload class]]) {
        NSString *localFilepath = ((GRRequestUpload *)self.currentRequest).localFilepath;
        _currentUploadData = [NSData dataWithContentsOfFile:localFilepath];
    }
    
    [self.currentRequest start];
    [self.delegate ftpRequestsManager:self didStartRequest:self.currentRequest];
}

@end
