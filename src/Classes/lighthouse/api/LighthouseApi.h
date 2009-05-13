//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LighthouseApiDelegate.h"
#import "WebServiceApiDelegate.h"

@class WebServiceApi, WebServiceResponseDispatcher;

@interface LighthouseApi : NSObject <WebServiceApiDelegate>
{
    id<LighthouseApiDelegate> delegate;

    NSString * baseUrlString;

    WebServiceApi * api;
    WebServiceResponseDispatcher * dispatcher;
}

@property (nonatomic, assign) id<LighthouseApiDelegate> delegate;

#pragma mark Initialization

- (id)initWithBaseUrlString:(NSString *)aBaseUrlString;

#pragma mark Tickets

- (void)fetchTicketsForAllProjects:(NSString *)token;

- (void)searchTicketsForAllProjects:(NSString *)searchString
                              token:(NSString *)token;

#pragma mark Ticket bins

- (void)fetchTicketBinsForProject:(NSUInteger)projectId token:(NSString *)token;

#pragma mark Milestones

- (void)fetchMilestonesForAllProjects:(NSString *)token;

@end
