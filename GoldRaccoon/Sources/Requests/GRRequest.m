//
//  GRRequest.m
//  GoldRaccoon
//  v1.0.0
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

#import "GRRequest.h"

@implementation GRRequest

@synthesize passiveMode;
@synthesize uuid;
@synthesize error;
@synthesize streamInfo;
@synthesize maximumSize;
@synthesize percentCompleted;
@synthesize delegate;
@synthesize didOpenStream;
@synthesize path = _path;

- (instancetype)initWithDelegate:(id<GRRequestDelegate>)aDelegate datasource:(id<GRRequestDataSource>)aDatasource
{
    self = [super init];
    if (self) {
		self.passiveMode = YES;
        self.uuid        = [[NSUUID UUID] UUIDString];
        self.path        = nil;
        
        self.streamInfo = [[GRStreamInfo alloc] init];
        self.streamInfo.readStream = nil;
        self.streamInfo.writeStream = nil;
        self.streamInfo.bytesThisIteration = 0;
        self.streamInfo.bytesTotal = 0;
        self.streamInfo.timeout = 30;
        
        self.delegate   = aDelegate;
        self.dataSource = aDatasource;
    }
    return self;
}

#pragma mark - GRRequestProtocol

- (NSURL *)fullURL
{
    NSString *hostname = [self.dataSource hostnameForRequest:self];
    NSString *ftpPrefix = @"ftp://";
    if (hostname.length >= 6 && [[hostname substringToIndex:6] isEqualToString:ftpPrefix]) {
        hostname = [hostname substringFromIndex:6];
    }
    NSString *fullURLString = [NSString stringWithFormat:@"%@%@%@", ftpPrefix, hostname, self.path];
    return [NSURL URLWithString:fullURLString];
    
}

- (NSURL *)fullURLWithEscape
{
    NSString *escapedUsername = [self encodeString:[self.dataSource usernameForRequest:self]];
    NSString *escapedPassword = [self encodeString:[self.dataSource passwordForRequest:self]];
    NSString *cred;
    
    if (escapedUsername != nil) {
        if (escapedPassword != nil) {
            cred = [NSString stringWithFormat:@"%@:%@@", escapedUsername, escapedPassword];
        }
        else {
            cred = [NSString stringWithFormat:@"%@@", escapedUsername];
        }
    }
    else {
        cred = @"";
    }
    cred = [cred stringByStandardizingPath];
    
    NSString *hostname = [self.dataSource hostnameForRequest:self];
    NSString *ftpPrefix = @"ftp://";
    if (hostname.length >= 6 && [[hostname substringToIndex:6] isEqualToString:ftpPrefix]) {
        hostname = [hostname substringFromIndex:6];
    }
    
    NSString *fullURLString = [NSString stringWithFormat:@"ftp://%@%@%@", cred, hostname, self.path];
    return [NSURL URLWithString:fullURLString];
}

- (NSString *)path
{
    // we remove all the extra slashes from the directory path, including the last one (if there is one)
    // we also escape it
    NSString * escapedPath = [_path stringByStandardizingPath];
    
    // we need the path to be absolute, if it's not, we *make* it
    if ([escapedPath isAbsolutePath] == NO) {
        escapedPath = [@"/" stringByAppendingString:escapedPath];
    }
    
    // now make sure that we have escaped all special characters
    escapedPath = [self encodeString:escapedPath];
    
    return escapedPath;
}

- (void)setPath:(NSString *)directoryPathLocal
{
    _path = directoryPathLocal;
}

- (NSString *)encodeString:(NSString *)string;
{
    NSString *urlEncoded = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                                 NULL,
                                                                                                 (__bridge CFStringRef) string,
                                                                                                 NULL,
                                                                                                 (CFStringRef)@"!*'\"();:@&=+$,?%#[]% ",
                                                                                                 kCFStringEncodingUTF8);
    return urlEncoded;
}  

- (void)start
{
    // override in subclasses
}

- (long)bytesSent
{
    return self.streamInfo.bytesThisIteration;
}

- (long)totalBytesSent
{
    return self.streamInfo.bytesTotal;
}

- (long)timeout
{
    return self.streamInfo.timeout;
}

- (void)setTimeout:(long)timeout
{
    self.streamInfo.timeout = timeout;
}

- (void)cancelRequest
{
    self.streamInfo.cancelRequestFlag = TRUE;
}

- (BOOL)cancelDoesNotCallDelegate
{
    return self.streamInfo.cancelDoesNotCallDelegate;
}

- (void)setCancelDoesNotCallDelegate:(BOOL)cancelDoesNotCallDelegate
{
    self.streamInfo.cancelDoesNotCallDelegate = cancelDoesNotCallDelegate;
}

@end
