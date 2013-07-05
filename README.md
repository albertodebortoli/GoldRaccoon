# GoldRaccoon

## General Notes

GoldRaccoon is a iOS component that allow you to connect to a FTP service and do the following stuff:

*	Download a file
*	Upload a file
*	Delete a file
*	Create a directory
*	Delete a directory
*	List a directory

## Why another Raccoon? 

First, because the humanity needs for it.

This project started on 29/06/2013 for the Objective-C Hackathon (http://objectivechackathon.appspot.com/).

GoldRaccoon aims to be an evolution of BlackRaccoon, maybe the best third-party component out there for handling FTP operations on iOS.

I forked the public repo of the BlackRaccoon (which is an evolution of WhiteRaccoon) in May 2013 and added some improvements that have been merge into master to BlackRaccoon. Even though BlackRaccoon does what it says, I prefer to clean it a little and use a different and more extensible code structure.

Most of the code is therefore written by Valentin Radu and Lloyd Sargent, my main extensions are:

- Done some deep refactoring for the bloating of the previous code;
- Added missing (and reasonable) code conventions;
- Added GRRequestsManager to manage all the different kind of requests using a FIFO queue;
- Added a demo project.

## Usage

- copy Sources folder into your project
- add CFNetwork framewor
- import `GRRequestsManager.h` in your class
- add a property for the manager

``` objective-c
	@property (nonatomic, strong) GRRequestsManager *requestsManager;
```

- setup the manager somewhere (with hostname, username and password)

``` objective-c
	self.requestsManager = [[GRRequestsManager alloc] initWithHostname:<hostname>
                                                                  user:<username>
                                                              password:<password>];
```

- optionally make your class conform to `GRRequestsManagerDelegate`, implement the delegate methods (basically success, failure and progress callbacks) and set your instance of this class as delegate for the manager

``` objective-c
    self.requestsManager.delegate = self;
```

- add the requests to the manager using the following methods:

``` objective-c
	- addRequestForListDirectoryAtPath:
	- addRequestForCreateDirectoryAtPath:
	- addRequestForDeleteFileAtPath:
	- addRequestForDeleteDirectoryAtPath:
	- addRequestForDownloadFileAtRemotePath:toLocalPath:
	- addRequestForUploadFileAtLocalPath:toRemotePath:
```

- start the manager

``` objective-c
	[self.requestsManager startProcessingRequests];
```