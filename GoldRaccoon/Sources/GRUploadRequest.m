//
//  GRUploadRequest.m
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

#import "GRUploadRequest.h"
#import "GRListingRequest.h"

@interface GRUploadRequest () <GRRequestDelegate, GRRequestDataSource>

@property (nonatomic, assign) long bytesIndex;
@property (nonatomic, assign) long bytesRemaining;
@property (nonatomic, strong) NSData *sentData;
@property (nonatomic, strong) GRListingRequest *listingRequest;

@end

@implementation GRUploadRequest

@synthesize listingRequest;
@synthesize localFilePath;
@synthesize fullRemotePath;

/**
 
 */
- (void)start
{
    self.maximumSize = LONG_MAX;
    _bytesIndex = 0;
    _bytesRemaining = 0;
    
    if ([self.dataSource respondsToSelector:@selector(requestDataToSend:)] == NO) {
        [self.streamInfo streamError:self errorCode:kGRFTPClientMissingRequestDataAvailable];
        NSLog(@"%@", self.error.message);
        return;
    }
    
    // we first list the directory to see if our folder is up on the server
    self.listingRequest = [[GRListingRequest alloc] initWithDelegate:self datasource:self];
	self.listingRequest.passiveMode = self.passiveMode;
    self.listingRequest.path = [self.path stringByDeletingLastPathComponent];
    [self.listingRequest start];
}

#pragma mark - GRRequestDelegate

/**
 
 */
- (void)requestCompleted:(GRRequest *)request
{
    NSString * fileName = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
    if ([self.listingRequest fileExists:fileName]) {
        if ([self.delegate shouldOverwriteFile:self.path forRequest:self] == NO) {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode:kGRFTPClientFileAlreadyExists];
            return;
        }
    }
    
    if ([self.dataSource respondsToSelector:@selector(requestDataSendSize:)]) {
        self.maximumSize = [self.dataSource requestDataSendSize:self];
    }
    
    // open the write stream and check for errors calling delegate methods
    // if things fail. This encapsulates the streamInfo object and cleans up our code.
    [self.streamInfo openWrite:self];
}


/**
 
 */
- (void)requestFailed:(GRRequest *)request
{
    [self.delegate requestFailed:request];
}

/**
 
 */
- (BOOL)shouldOverwriteFile:(NSString *)filePath forRequest:(id<GRDataExchangeRequestProtocol>)request
{
    return [self.delegate shouldOverwriteFile:filePath forRequest:request];
}

#pragma mark - GRRequestDataSource

- (NSString *)hostnameForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource hostnameForRequest:request];
}

- (NSString *)usernameForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource usernameForRequest:request];
}

- (NSString *)passwordForRequest:(id<GRRequestProtocol>)request
{
    return [self.dataSource passwordForRequest:request];
}

#pragma mark - NSStreamDelegate

/**
 
 */
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    // see if we have cancelled the runloop
    if ([self.streamInfo checkCancelRequest:self]) {
        return;
    }
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            self.didOpenStream = YES;
            self.streamInfo.bytesTotal = 0;
        } 
        break;
            
        case NSStreamEventHasBytesAvailable: {
        } 
        break;
            
        case NSStreamEventHasSpaceAvailable: {
            if (_bytesRemaining == 0) {
                _sentData = [self.dataSource requestDataToSend:self];
                _bytesRemaining = [_sentData length];
                _bytesIndex = 0;
                
                // we are done
                if (_sentData == nil) {
                    [self.streamInfo streamComplete:self]; // perform callbacks and close out streams
                    return;
                }
            }
            
            NSUInteger nextPackageLength = MIN(kGRDefaultBufferSize, _bytesRemaining);
            NSRange range = NSMakeRange(_bytesIndex, nextPackageLength);
            NSData *packetToSend = [_sentData subdataWithRange: range];

            [self.streamInfo write:self data: packetToSend];
            
            _bytesIndex += self.streamInfo.bytesThisIteration;
            _bytesRemaining -= self.streamInfo.bytesThisIteration;
        }
        break;
            
        case NSStreamEventErrorOccurred: {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode: [GRError errorCodeWithError: [theStream streamError]]];
            NSLog(@"%@", self.error.message);
        }
        break;
            
        case NSStreamEventEndEncountered: {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode:kGRFTPServerAbortedTransfer];
            NSLog(@"%@", self.error.message);
        }
        break;
        
        default:
            break;
    }
}

/**
 
 */
- (NSString *)fullRemotePath
{
    return [[self.dataSource hostnameForRequest:self] stringByAppendingPathComponent:self.path];
}

@end
