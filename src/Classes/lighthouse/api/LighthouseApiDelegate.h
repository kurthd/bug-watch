//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LighthouseApiDelegate

#pragma mark Tickets -- searching

- (void)tickets:(NSData *)xml fetchedForAllProjectsWithToken:(NSString *)token;
- (void)failedToFetchTicketsForAllProjects:(NSString *)token
                                     error:(NSError *)error;

- (void)details:(NSData *)xml fetchedForTicket:(id)ticketKey
    inProject:(id)projectKey token:(NSString *)token;
- (void)failedToFetchTicketDetailsForTicket:(id)ticketKey
    inProject:(id)projectKey token:(NSString *)token error:(NSError *)error;

- (void)searchResults:(NSData *)xml
    fetchedForAllProjectsWithSearchString:(NSString *)searchString
    token:(NSString *)token;
- (void)failedToSearchTicketsForAllProjects:(NSString *)searchString
    token:(NSString *)token error:(NSError *)error;

- (void)searchResults:(NSData *)xml fetchedForProject:(id)projectKey
    searchString:(NSString *)searchString object:(id)object
    token:(NSString *)token;
- (void)failedToSearchTicketsForProject:(id)projectKey
    searchString:(NSString *)searchString object:(id)object
    token:(NSString *)token error:(NSError *)error;

#pragma mark Tickets -- creating

- (void)ticketCreationDidBegin:(NSData *)xml forProject:(id)projectKey
    object:(id)object token:(NSString *)token;
- (void)failedToBeginTicketCreationForProject:(id)projectKey
    object:(id)object token:(NSString *)token error:(NSError *)error;

- (void)ticketCreated:(NSData *)xml description:(NSString *)description
    forProject:(id)projectKey object:(id)object token:(NSString *)token;
- (void)failedToCompleteTicketCreation:(NSString *)description
    forProject:(id)projectKey object:(id)object token:(NSString *)token
    error:(NSError *)error;

#pragma mark Tickets -- editing

- (void)editedTicket:(id)ticketKey forProject:(id)projectKey
    withDescription:(NSString *)description object:(id)requestId
    response:(NSData *)xml token:(NSString *)token;
- (void)failedToEditTicket:(id)ticketKey forProject:(id)projectKey
    description:(NSString *)desc object:(id)object token:(NSString *)token
    error:(NSError *)error;

#pragma mark Tickets -- deleting

- (void)deletedTicket:(id)ticketKey forProject:(id)projectKey
    token:(NSString *)token response:(NSData *)response;
- (void)failedToDeleteTicket:(id)ticketKey forProject:(id)projectKey
    token:(NSString *)token error:(NSError *)response;

#pragma mark Ticket bins

- (void)ticketBins:(NSData *)xml fetchedForProject:(id)projectKey
    token:(NSString *)token;
- (void)failedToFetchTicketBinsForProject:(id)projectKey
    token:(NSString *)token error:(NSError *)error;

#pragma mark Users

- (void)allUsers:(NSData *)xml fetchedForProject:(id)projectKey
    token:(NSString *)token;
- (void)failedToFetchAllUsersForProject:(id)projectKey token:(NSString *)token
    error:(NSError *)error;

#pragma mark Projects

- (void)projects:(NSData *)xml fetchedForAllProjects:(NSString *)token;
- (void)failedToFetchAllProjects:(NSString *)token error:(NSError *)error;

#pragma mark Milestones

- (void)milestones:(NSData *)xml
    fetchedForAllProjectsWithToken:(NSString *)token;
- (void)failedToFetchMilestonesForAllProjects:(NSString *)token
    error:(NSError *)error;

@end
