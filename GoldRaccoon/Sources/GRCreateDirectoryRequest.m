//
//  GRCreateDirectoryRequest.m
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

#import "GRCreateDirectoryRequest.h"

@interface GRCreateDirectoryRequest () <GRRequestDelegate, GRRequestDataSource>

@property GRListingRequest *listrequest;

@end

@implementation GRCreateDirectoryRequest

@synthesize listrequest;

/**
 
 */
- (NSString *)path
{
    // the path will always point to a directory, so we add the final slash to it (if there was one before escaping/standardizing, it's *gone* now)
    NSString * directoryPath = [super path];
    if (![directoryPath hasSuffix: @"/"])
    {
        directoryPath = [directoryPath stringByAppendingString:@"/"];
    }
    return directoryPath;
}

/**
 
 */
- (void)start
{
    if (self.hostname == nil) {
        InfoLog(@"The host name is nil!");
        self.error = [[GRError alloc] init];
        self.error.errorCode = kGRFTPClientHostnameIsNil;
        [self.delegate requestFailed:self];
        return;
    }
    
    // we first list the directory to see if our folder is up already
    self.listrequest = [[GRListingRequest alloc] initWithDelegate:self datasource:self];
    self.listrequest.path = [self.path stringByDeletingLastPathComponent];
    [self.listrequest start];
}

#pragma mark - GRRequestDelegate

/**
 
 */
- (void)requestCompleted:(GRRequest *)request
{
    NSString *directoryName = [[self.path lastPathComponent] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

    if ([self.listrequest fileExists: directoryName]) {
        InfoLog(@"Unfortunately, at this point, the library doesn't support directory overwriting.");
        [self.streamInfo streamError:self errorCode:kGRFTPClientCantOverwriteDirectory];
    }
    else {
        // open the write stream and check for errors calling delegate methods
        // if things fail. This encapsulates the streamInfo object and cleans up our code.
        [self.streamInfo openWrite:self];
    }
}

/**
 
 */
- (void)requestFailed:(GRRequest *)request
{
    [self.delegate requestFailed:request];
}

/**
 
 */
- (BOOL)shouldOverwriteFileWithRequest:(GRRequest *)request
{
    return NO;
}

#pragma mark - GRRequestDataSource

- (NSString *)hostname
{
    return [self.dataSource hostname];
}

- (NSString *)username
{
    return [self.dataSource username];
}

- (NSString *)password
{
    return [self.dataSource password];
}

#pragma mark - NSStreamDelegate

/**
 
 */
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent) {
        // XCode whines about this missing - which is why it is here
        case NSStreamEventNone:
            break;
            
        case NSStreamEventOpenCompleted: {
            self.didOpenStream = YES;
        }
            break;
            
        case NSStreamEventHasBytesAvailable: {
        }
            break;
            
        case NSStreamEventHasSpaceAvailable: {
        }
            break;
            
        case NSStreamEventErrorOccurred: {
            // perform callbacks and close out streams
            [self.streamInfo streamError:self errorCode: [GRError errorCodeWithError: [theStream streamError]]];
            InfoLog(@"%@", self.error.message);
        }
            break;
            
        case NSStreamEventEndEncountered: {
            // perform callbacks and close out streams
            [self.streamInfo streamComplete:self];
        }
            break;

        default:
            break;
    }
}

@end
