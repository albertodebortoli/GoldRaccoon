//
//  GRDownloadRequest.m
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

#import "GRDownloadRequest.h"

@interface GRDownloadRequest ()

@property NSData *receivedData;

@end

@implementation GRDownloadRequest

@synthesize passiveMode;
@synthesize uuid;
@synthesize error;
@synthesize streamInfo;
@synthesize maximumSize;
@synthesize percentCompleted;
@synthesize delegate;
@synthesize didOpenStream;
@synthesize path;

@synthesize receivedData;
@synthesize localFilePath;
@synthesize fullRemotePath;

- (void)start
{
    if ([self.delegate respondsToSelector:@selector(dataAvailable:forRequest:)] == NO) {
        [self.streamInfo streamError:self errorCode:kGRFTPClientMissingRequestDataAvailable];
        NSLog(@"%@", self.error.message);
        return;
    }
    
    // open the read stream and check for errors calling delegate methods
    // if things fail. This encapsulates the streamInfo object and cleans up our code.
    [self.streamInfo openRead:self];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    // see if we have cancelled the runloop
    if ([self.streamInfo checkCancelRequest:self]) {
        return;
    }
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted: {
            self.maximumSize = [[theStream propertyForKey:(id)kCFStreamPropertyFTPResourceSize] integerValue];
            self.didOpenStream = YES;
            self.streamInfo.bytesTotal = 0;
            self.receivedData = [NSMutableData data];
        } 
        break;
            
        case NSStreamEventHasBytesAvailable: {
            self.receivedData = [self.streamInfo read:self];
            
            if (self.receivedData) {
                if ([self.delegate respondsToSelector:@selector(dataAvailable:forRequest:)]) {
                    [self.delegate dataAvailable:self.receivedData forRequest:self];
                }
            }
            else {
                NSLog(@"Stream opened, but failed while trying to read from it.");
                [self.streamInfo streamError:self errorCode:kGRFTPClientCantReadStream];
            }
        } 
        break;
            
        case NSStreamEventHasSpaceAvailable: {
            
        } 
        break;
            
        case NSStreamEventErrorOccurred: {
            [self.streamInfo streamError:self errorCode: [GRError errorCodeWithError: [theStream streamError]]];
            NSLog(@"%@", self.error.message);
        }
        break;
            
        case NSStreamEventEndEncountered: {
            [self.streamInfo streamComplete:self];
        }
        break;

        default:
            break;
    }
}

- (NSString *)fullRemotePath
{
    return [[self.dataSource hostnameForRequest:self] stringByAppendingPathComponent:self.path];
}

@end
