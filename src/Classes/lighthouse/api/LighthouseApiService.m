//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "LighthouseApiService.h"
#import "LighthouseApi.h"
#import "LighthouseApiParser.h"
#import "TicketNumber.h"

@interface LighthouseApiService ()

- (void)notifyDelegate:(SEL)selector;
- (void)notifyDelegate:(SEL)selector withObject:(id)obj;
- (void)notifyDelegate:(SEL)selector withObject:(id)obj1 withObject:(id)obj2;

- (NSArray *)parseTickets:(NSData *)xml;
- (NSArray *)parseTicketMetaData:(NSData *)xml;
- (NSArray *)parseTicketNumbers:(NSData *)xml;
- (NSArray *)parseMilestones:(NSData *)xml;

@end

@implementation LighthouseApiService

@synthesize delegate;

- (void)dealloc
{
    [api release];
    [parser release];

    [super dealloc];
}

#pragma mark Initialization

- (id)initWithBaseUrlString:(NSString *)aBaseUrlString
{
    if (self = [super init]) {
        api = [[LighthouseApi alloc] initWithBaseUrlString:aBaseUrlString];
        api.delegate = self;

        parser = [[LighthouseApiParser alloc] init];
    }

    return self;
}

#pragma mark Fetching tickets

- (void)fetchTicketsForAllProjects:(NSString *)token
{
    [api fetchTicketsForAllProjects:token];
}

#pragma mark Fetching milestones

- (void)fetchMilestonesForAllProjects:(NSString *)token
{
    [api fetchMilestonesForAllProjects:token];
}

#pragma mark LighthouseApiDelegate implementation

- (void)tickets:(NSData *)data
    fetchedForAllProjectsWithToken:(NSString *)token
{
    NSArray * ticketNumbers = [self parseTicketNumbers:data];
    NSArray * tickets = [self parseTickets:data];
    NSArray * metadata = [self parseTicketMetaData:data];

    SEL sel =
        @selector(tickets:fetchedForAllProjectsWithMetadata:ticketNumbers:);
    if ([delegate respondsToSelector:sel])
        [delegate tickets:tickets fetchedForAllProjectsWithMetadata:metadata
            ticketNumbers:ticketNumbers];
}

- (void)failedToFetchTicketsForAllProjects:(NSString *)token
                                     error:(NSError *)error
{
    SEL sel = @selector(failedToFetchTicketsForAllProjects:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchTicketsForAllProjects:error];
}

- (void)milestones:(NSData *)data
    fetchedForAllProjectsWithToken:(NSString *)token
{
    NSArray * milestones = [self parseMilestones:data];

    SEL sel = @selector(milestonesFetchedForAllProjects:);
    if ([delegate respondsToSelector:sel])
        [delegate milestonesFetchedForAllProjects:milestones];
}

- (void)failedToFetchMilestonesForAllProjects:(NSString *)token
                                        error:(NSError *)error
{
    [delegate failedToFetchMilestonesForAllProjects:error];
}

#pragma mark Helper functions for invoking delegate methods

- (void)notifyDelegate:(SEL)selector
{
    if ([delegate respondsToSelector:selector])
        [delegate performSelector:selector];
}

- (void)notifyDelegate:(SEL)selector withObject:(id)obj
{
    if ([delegate respondsToSelector:selector])
        [delegate performSelector:selector withObject:obj];
}

- (void)notifyDelegate:(SEL)selector withObject:(id)obj1 withObject:(id)obj2
{
    if ([delegate respondsToSelector:selector])
        [delegate performSelector:selector withObject:obj1 withObject:obj2];
}

#pragma mark Parsing XML

- (NSArray *)parseTickets:(NSData *)xml
{
    parser.className = @"Ticket";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"description", @"title",
            @"creationDate", @"created-at", nil];

    return [parser parse:xml];
}

- (NSArray *)parseTicketMetaData:(NSData *)xml
{
    parser.className = @"TicketMetaData";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"tags", @"tag",
            @"state", @"state",
            @"lastModifiedDate", @"updated-at", nil];

    return [parser parse:xml];
}

- (NSArray *)parseTicketNumbers:(NSData *)xml
{
    parser.className = @"TicketNumber";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"ticketNumber", @"number",
            nil];

    NSArray * parsedNumbers = [parser parse:xml];
    NSMutableArray * numbers =
        [NSMutableArray arrayWithCapacity:parsedNumbers.count];

    // extract NSNumbers
    for (TicketNumber * n in parsedNumbers)
        [numbers addObject:n.ticketNumber];

    return numbers;
}

- (NSArray *)parseMilestones:(NSData *)xml
{
    parser.className = @"Milestone";
    parser.classElementType = @"milestone";
    parser.classElementCollection = @"milestones";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"name", @"title",
            @"dueDate", @"due-on",
            @"numOpenTickets", @"open-tickets-count",
            @"numTickets", @"tickets-count",
            nil];

    return [parser parse:xml];
}

@end