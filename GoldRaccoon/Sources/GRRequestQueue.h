//
//  GRRequestQueue.h
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

#import "GRGlobal.h"
#import "GRRequest.h"
#import "GRRequestQueue.h"

@class GRRequestQueue;
@protocol BRQueueDelegate  <GRRequestDelegate>

@required
- (void)queueCompleted:(GRRequestQueue *)queue;
@end

@interface GRRequestQueue : GRRequest <GRRequestDelegate>
{
    
@private
    GRRequest *headRequest;
    GRRequest *tailRequest;
}

@property id <BRQueueDelegate> queueDelegate;

- (void)addRequest:(GRRequest *)request;
- (void)addRequestInFront:(GRRequest *)request;
- (void)addRequestsFromArray:(NSArray *)array;
- (void)removeRequestFromQueue:(GRRequest *)request;

@end
