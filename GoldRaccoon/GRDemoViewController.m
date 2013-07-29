//
//  GRDemoViewController.m
//  GoldRaccoon
//
//  Created by Alberto De Bortoli on 02/07/2013.
//  Copyright (c) 2013 Alberto De Bortoli. All rights reserved.
//

#import "GRDemoViewController.h"
#import "GRRequestsManager.h"

@interface GRDemoViewController () <GRRequestsManagerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) GRRequestsManager *requestsManager;
@property (nonatomic, strong) IBOutlet UITextField *hostnameTextField;
@property (nonatomic, strong) IBOutlet UITextField *usernameTextField;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;

- (IBAction)listingButton:(id)sender;
- (IBAction)createDirectoryButton:(id)sender;
- (IBAction)deleteDirectoryButton:(id)sender;
- (IBAction)deleteFileButton:(id)sender;
- (IBAction)uploadFileButton:(id)sender;
- (IBAction)downloadFileButton:(id)sender;

@end

@implementation GRDemoViewController

- (IBAction)listingButton:(id)sender
{
    [self _setupManager];
    [self.requestsManager addRequestForListDirectoryAtPath:@"/"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)createDirectoryButton:(id)sender
{
    [self _setupManager];
    [self.requestsManager addRequestForCreateDirectoryAtPath:@"dir/"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)deleteDirectoryButton:(id)sender
{
    [self _setupManager];
    [self.requestsManager addRequestForDeleteDirectoryAtPath:@"dir/"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)deleteFileButton:(id)sender
{
    [self _setupManager];
    [self.requestsManager addRequestForDeleteFileAtPath:@"dir/file.txt"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)uploadFileButton:(id)sender
{
    [self _setupManager];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"TestFile" ofType:@"txt"];
    [self.requestsManager addRequestForUploadFileAtLocalPath:bundlePath toRemotePath:@"dir/file.txt"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)downloadFileButton:(id)sender
{
    [self _setupManager];
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *localFilePath = [documentsDirectoryPath stringByAppendingPathComponent:@"DownloadedFile.txt"];

    [self.requestsManager addRequestForDownloadFileAtRemotePath:@"dir/file.txt" toLocalPath:localFilePath];
    [self.requestsManager startProcessingRequests];
}

#pragma mark - Private Methods

- (void)_setupManager
{
    self.requestsManager = [[GRRequestsManager alloc] initWithHostname:[self.hostnameTextField text]
                                                                  user:[self.usernameTextField text]
                                                              password:[self.passwordTextField text]];
    self.requestsManager.delegate = self;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - GRRequestsManagerDelegate

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didStartRequest:(id<GRRequestProtocol>)request
{
    NSLog(@"requestsManager:didStartRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteListingRequest:(id<GRRequestProtocol>)request listing:(NSArray *)listing
{
    NSLog(@"requestsManager:didCompleteListingRequest:listing: \n%@", listing);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteCreateDirectoryRequest:(id<GRRequestProtocol>)request
{
    NSLog(@"requestsManager:didCompleteCreateDirectoryRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDeleteRequest:(id<GRRequestProtocol>)request
{
    NSLog(@"requestsManager:didCompleteDeleteRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(id<GRRequestProtocol>)request
{
    NSLog(@"requestsManager:didCompletePercent:forRequest: %f", percent);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteUploadRequest:(id<GRDataExchangeRequestProtocol>)request
{
    NSLog(@"requestsManager:didCompleteUploadRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDownloadRequest:(id<GRDataExchangeRequestProtocol>)request
{
    NSLog(@"requestsManager:didCompleteDownloadRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(id<GRDataExchangeRequestProtocol>)request error:(NSError *)error
{
    NSLog(@"requestsManager:didFailWritingFileAtPath:forRequest:error: \n %@", error);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(id<GRRequestProtocol>)request withError:(NSError *)error
{
    NSLog(@"requestsManager:didFailRequest:withError: \n %@", error);
}

@end
