//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "LighthouseApiService.h"
#import "LighthouseApi.h"
#import "LighthouseApiParser.h"
#import "RandomNumber.h"
#import "RegexKitLite.h"

@interface LighthouseApiService ()

- (NSArray *)parseTickets:(NSData *)xml;
- (NSArray *)parseTicketMetaData:(NSData *)xml;
- (NSArray *)parseTicketNumbers:(NSData *)xml;
- (NSArray *)parseTicketMilestoneIds:(NSData *)xml;
- (NSArray *)parseTicketProjectIds:(NSData *)xml;

- (NSArray *)parseProjects:(NSData *)xml;
- (NSArray *)parseProjectKeys:(NSData *)xml;

- (NSArray *)parseUsers:(NSData *)xml;
- (NSArray *)parseUserKeys:(NSData *)xml;
- (NSArray *)parseUserIds:(NSData *)xml;

- (NSArray *)parseCreatorIds:(NSData *)xml;

- (NSArray *)parseTicketComments:(NSData *)xml;
- (NSArray *)parseTicketCommentAuthors:(NSData *)xml;
- (NSArray *)parseTicketUrls:(NSData *)xml;

- (NSArray *)parseMilestones:(NSData *)xml;
- (NSArray *)parseMilestoneIds:(NSData *)xml;
- (NSArray *)parseMilestoneProjectIds:(NSData *)xml;

- (NSArray *)parseTicketBins:(NSData *)xml;

- (BOOL)invokeSelector:(SEL)selector withTarget:(id)target
    args:(id)firstArg, ... NS_REQUIRES_NIL_TERMINATION;

+ (id)uniqueTicketKey;

@end

@implementation LighthouseApiService

@synthesize delegate;

- (void)dealloc
{
    [api release];
    [parser release];

    [newTicketRequests release];

    [super dealloc];
}

#pragma mark Initialization

- (id)initWithBaseUrlString:(NSString *)aBaseUrlString
{
    if (self = [super init]) {
        api = [[LighthouseApi alloc] initWithBaseUrlString:aBaseUrlString];
        api.delegate = self;

        parser = [[LighthouseApiParser alloc] init];

        newTicketRequests = [[NSMutableDictionary alloc] init];
    }

    return self;
}

#pragma mark Tickets -- searching

- (void)fetchTicketsForAllProjects:(NSString *)token
{
    [api fetchTicketsForAllProjects:token];
}

- (void)fetchDetailsForTicket:(id)ticketKey inProject:(id)projectKey
    token:(NSString *)token
{
    [api fetchDetailsForTicket:ticketKey
                     inProject:(id)projectKey
                         token:token];
}

- (void)searchTicketsForAllProjects:(NSString *)searchString
                              token:(NSString *)token
{
    [api searchTicketsForAllProjects:searchString token:token];
}

- (void)searchTicketsForProject:(id)projectKey
    withSearchString:(NSString *)searchString object:(id)object
    token:(NSString *)token
{
    [api searchTicketsForProject:projectKey withSearchString:searchString
        object:object token:token];
}

#pragma mark Tickets -- creating

- (void)createNewTicket:(NewTicketDescription *)desc forProject:(id)projectKey
    token:(NSString *)token
{
    id requestId = [[self class] uniqueTicketKey];
    [newTicketRequests setObject:[[desc copy] autorelease] forKey:requestId];

    [api beginTicketCreationForProject:projectKey object:requestId token:token];
}

#pragma mark Tickets -- editing

- (void)editTicket:(id)ticketKey forProject:(id)projectKey
    withDescription:(NewTicketDescription *)desc token:(NSString *)token
{
    id requestId = [[self class] uniqueTicketKey];
    [newTicketRequests setObject:[[desc copy] autorelease] forKey:requestId]; 

    NSString * xmlDescription = [desc xmlDescriptionForProject:projectKey];
    [api editTicket:ticketKey forProject:projectKey description:xmlDescription
        object:requestId token:token];
}

#pragma mark Ticket bins

- (void)fetchTicketBins:(NSString *)token
{
    [api fetchTicketBinsForProject:27400 token:token];
}

#pragma mark Users

- (void)fetchAllUsersForProject:(id)projectKey token:(NSString *)token
{
    [api fetchAllUsersForProject:projectKey token:token];
}

#pragma mark Projects

- (void)fetchAllProjects:(NSString *)token
{
    [api fetchAllProjects:token];
}

#pragma mark Milestones

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
    NSArray * milestoneIds = [self parseTicketMilestoneIds:data];
    NSArray * projectIds = [self parseTicketProjectIds:data];
    NSArray * userIds = [self parseUserIds:data];
    NSArray * creatorIds = [self parseCreatorIds:data];

    SEL sel =
        @selector(tickets:fetchedForAllProjectsWithMetadata:ticketNumbers:\
             milestoneIds:projectIds:userIds:creatorIds:);

    [self invokeSelector:sel withTarget:delegate args:tickets, metadata,
        ticketNumbers, milestoneIds, projectIds, userIds, creatorIds, nil];
}

- (void)failedToFetchTicketsForAllProjects:(NSString *)token
                                     error:(NSError *)error
{
    SEL sel = @selector(failedToFetchTicketsForAllProjects:);
    [self invokeSelector:sel withTarget:delegate args:error, nil];
}

- (void)details:(NSData *)xml fetchedForTicket:(id)ticketKey
    inProject:(id)projectKey token:(NSString *)token
{
    NSArray * ticketComments = [self parseTicketComments:xml];
    NSArray * authors = [self parseTicketCommentAuthors:xml];

    SEL sel = @selector(details:authors:fetchedForTicket:inProject:);
    [self invokeSelector:sel withTarget:delegate args:ticketComments,
        authors, ticketKey, projectKey, nil];
}

- (void)failedToFetchTicketDetailsForTicket:(id)ticketKey
    inProject:(id)projectKey token:(NSString *)token error:(NSError *)error
{
    SEL sel =
        @selector(failedToFetchTicketDetailsForTicket:inProject:token:error:);
    [self invokeSelector:sel withTarget:delegate args:ticketKey, projectKey,
        error, nil];
}

- (void)searchResults:(NSData *)data
    fetchedForAllProjectsWithSearchString:(NSString *)searchString
    token:(NSString *)token
{
    NSArray * ticketNumbers = [self parseTicketNumbers:data];
    NSArray * tickets = [self parseTickets:data];
    NSArray * metadata = [self parseTicketMetaData:data];
    NSArray * milestoneIds = [self parseTicketMilestoneIds:data];
    NSArray * projectIds = [self parseTicketProjectIds:data];
    NSArray * userIds = [self parseUserIds:data];
    NSArray * creatorIds = [self parseCreatorIds:data];

    SEL sel = @selector(tickets:fetchedForSearchString:metadata:ticketNumbers:\
        milestoneIds:projectIds:userIds:creatorIds:);

    [self invokeSelector:sel withTarget:delegate
        args:tickets, searchString, metadata, ticketNumbers, milestoneIds,
        projectIds, userIds, creatorIds, nil];
}

- (void)failedToSearchTicketsForAllProjects:(NSString *)searchString
    token:(NSString *)token error:(NSError *)error
{
    SEL sel = @selector(failedToSearchTicketsForAllProjects:error:);
    [self invokeSelector:sel withTarget:delegate args:searchString, error, nil];
}

- (void)searchResults:(NSData *)data fetchedForProject:(id)projectKey
    searchString:(NSString *)searchString object:(id)object
    token:(NSString *)token
{
    NSArray * ticketNumbers = [self parseTicketNumbers:data];
    NSArray * tickets = [self parseTickets:data];
    NSArray * metadata = [self parseTicketMetaData:data];
    NSArray * milestoneIds = [self parseTicketMilestoneIds:data];
    NSArray * projectIds = [self parseTicketProjectIds:data];
    NSArray * userIds = [self parseUserIds:data];
    NSArray * creatorIds = [self parseCreatorIds:data];

    // call delegate method manually since object might be nil
    SEL sel = @selector(tickets:fetchedForProject:searchString:object:\
        metadata:ticketNumbers:milestoneIds:projectIds:userIds:creatorIds:);
    if ([delegate respondsToSelector:sel])
        [delegate tickets:tickets fetchedForProject:projectKey
            searchString:searchString object:object metadata:metadata
            ticketNumbers:ticketNumbers milestoneIds:milestoneIds
            projectIds:projectIds userIds:userIds creatorIds:creatorIds];
}

- (void)failedToSearchTicketsForProject:(id)projectKey
    searchString:(NSString *)searchString object:(id)object
    token:(NSString *)token error:(NSError *)error
{
    SEL sel =
        @selector(failedToSearchTicketsForProject:searchString:object:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToSearchTicketsForProject:projectKey
            searchString:searchString object:object error:error];
}

#pragma mark -- Tickets -- creating

- (void)ticketCreationDidBegin:(NSData *)xml forProject:(id)projectKey
    object:(id)object token:(NSString *)token
{
    NewTicketDescription * desc = [newTicketRequests objectForKey:object];
    NSAssert1(desc, @"Did not find a pending ticket request for key: '%@'.",
        object);

    NSString * creationXml = [desc xmlDescriptionForProject:projectKey];
    [api completeTicketCreationForProject:projectKey
                              description:creationXml
                                   object:object
                                    token:token];
}

- (void)failedToBeginTicketCreationForProject:(id)projectKey
    object:(id)object token:(NSString *)token error:(NSError *)error
{
    NewTicketDescription * desc = [newTicketRequests objectForKey:object];
    NSAssert1(desc, @"Did not find a pending ticket request for key: '%@'.",
        object);

    SEL sel = @selector(failedToCreateTicket:forProject:error:);
    [self invokeSelector:sel withTarget:delegate args:desc, projectKey, error];

    [newTicketRequests removeObjectForKey:object];
}

- (void)ticketCreated:(NSData *)data description:(NSString *)description
    forProject:(id)projectKey object:(id)object token:(NSString *)token
{
    NewTicketDescription * newTicketDescription =
        [newTicketRequests objectForKey:object];
    NSAssert1(newTicketDescription, @"Did not find a pending ticket request "
        "for key: '%@'.", object);

    NSArray * ticketUrls = [self parseTicketUrls:data];
    NSAssert1(ticketUrls.count == 1, @"Expected 1 url, but got %d.",
        ticketUrls.count);

    NSString * url = [ticketUrls lastObject];
    id ticketKey = [url stringByMatching:@".*/(\\d+)$" capture:1];

    SEL sel = @selector(ticket:describedBy:createdForProject:);
    [self invokeSelector:sel withTarget:delegate args:ticketKey,
        newTicketDescription, projectKey, nil];

    [newTicketRequests removeObjectForKey:object];
}

- (void)failedToCompleteTicketCreation:(NSString *)description
    forProject:(id)projectKey object:(id)object token:(NSString *)token
    error:(NSError *)error
{
    NewTicketDescription * newTicketDescription =
        [newTicketRequests objectForKey:object];
    NSAssert1(newTicketDescription, @"Did not find a pending ticket request "
        "for key: '%@'.", object);

    SEL sel = @selector(failedToCreateNewTicketDescribedBy:forProject:error:);
    [self invokeSelector:sel withTarget:delegate args:newTicketDescription,
        projectKey, error, nil];

    [newTicketRequests removeObjectForKey:object];
}

#pragma mark -- Tickets -- editing

- (void)editedTicket:(id)ticketKey forProject:(id)projectKey
    withDescription:(NSString *)description object:(id)requestId
    response:(NSData *)xml token:(NSString *)token
{
    NewTicketDescription * newTicketDescription =
        [newTicketRequests objectForKey:requestId];
    NSAssert1(newTicketDescription, @"Did not find a pending ticket request "
        "for key: '%@'.", requestId);

    NSLog(@"Data returned: '%@'.", [[[NSString alloc] initWithData:xml encoding:4] autorelease]);

    SEL sel = @selector(editedTicket:forProject:describedBy:);
    [self invokeSelector:sel withTarget:delegate args:ticketKey, projectKey,
        newTicketDescription, nil];

    [newTicketRequests removeObjectForKey:requestId];
}

- (void)failedToEditTicket:(id)ticketKey forProject:(id)projectKey
    description:(NSString *)description object:(id)requestId
    token:(NSString *)token error:(NSError *)error
{
    NewTicketDescription * newTicketDescription =
        [newTicketRequests objectForKey:requestId];
    NSAssert1(newTicketDescription, @"Did not find a pending ticket request "
        "for key: '%@'.", requestId);

    SEL sel = @selector(failedToEditTicket:forProject:describedBy:error:);
    [self invokeSelector:sel withTarget:delegate args:ticketKey, projectKey,
        newTicketDescription, error, nil];

    [newTicketRequests removeObjectForKey:requestId];
}

#pragma mark -- Ticket bins

- (void)ticketBins:(NSData *)xml
    fetchedForProject:(NSUInteger)projectId token:(NSString *)token
{
    NSArray * ticketBins = [self parseTicketBins:xml];

    SEL sel = @selector(fetchedTicketBins:token:);
    [self invokeSelector:sel withTarget:delegate args:ticketBins, token, nil];
}

- (void)failedToFetchTicketBinsForProject:(NSUInteger)projectId
    token:(NSString *)token error:(NSError *)error
{
    SEL sel = @selector(failedToFetchTicketBins:error:);
    [self invokeSelector:sel withTarget:delegate args:token, error, nil];
}

#pragma mark -- Users

- (void)allUsers:(NSData *)xml fetchedForProject:(id)projectKey
    token:(NSString *)token
{
    NSArray * users = [self parseUsers:xml];
    NSArray * userKeys = [self parseUserKeys:xml];

    NSDictionary * allUsers =
        [NSDictionary dictionaryWithObjects:users forKeys:userKeys];

    SEL sel = @selector(allUsers:fetchedForProject:);
    [self
        invokeSelector:sel withTarget:delegate args:allUsers, projectKey, nil];

    // post general notification
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        allUsers, @"users",
        projectKey, @"projectKey",
        nil];
    NSString * notificationName =
        [[self class] usersRecevedForProjectNotificationName];
    [nc postNotificationName:notificationName
                      object:self
                    userInfo:userInfo];
}

- (void)failedToFetchAllUsersForProject:(id)projectKey token:(NSString *)token
    error:(NSError *)error
{
    SEL sel = @selector(failedToFetchAllUsersForProject:error:);
    [self invokeSelector:sel withTarget:delegate args:projectKey, error, nil];
}

#pragma mark -- Projects

- (void)projects:(NSData *)xml fetchedForAllProjects:(NSString *)token
{
    NSArray * projects = [self parseProjects:xml];
    NSArray * projectKeys = [self parseProjectKeys:xml];

    SEL sel = @selector(fetchedAllProjects:projectKeys:);
    [self
        invokeSelector:sel withTarget:delegate args:projects, projectKeys, nil];
}

- (void)failedToFetchAllProjects:(NSString *)token error:(NSError *)error
{
    SEL sel = @selector(failedToFetchAllProjects:);
    [self invokeSelector:sel withTarget:delegate args:error, nil];
}

#pragma mark -- Milestones

- (void)milestones:(NSData *)data
    fetchedForAllProjectsWithToken:(NSString *)token
{
    NSArray * milestones = [self parseMilestones:data];
    NSArray * milestoneIds = [self parseMilestoneIds:data];
    NSArray * projectIds = [self parseMilestoneProjectIds:data];

    SEL sel =
        @selector(milestonesFetchedForAllProjects:milestoneIds:projectIds:);
    [self invokeSelector:sel withTarget:delegate args:milestones, milestoneIds,
       projectIds, nil];

    // post general notification
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        milestones, @"milestones",
        milestoneIds, @"milestoneKeys",
        projectIds, @"projectKeys",
        nil];
    NSString * notificationName =
        [[self class] milestonesReceivedForAllProjectsNotificationName];
    [nc postNotificationName:notificationName
                      object:self
                    userInfo:userInfo];
}

- (void)failedToFetchMilestonesForAllProjects:(NSString *)token
                                        error:(NSError *)error
{
    SEL sel = @selector(failedToFetchMilestonesForAllProjects:);
    [self invokeSelector:sel withTarget:delegate args:error, nil];
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
    parser.className = @"NSNumber";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"number", nil];

    return [parser parse:xml];
}

- (NSArray *)parseTicketMilestoneIds:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"milestone-id", nil];

    return [parser parse:xml];
}

- (NSArray *)parseTicketProjectIds:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"project-id", nil];

    return [parser parse:xml];
}

- (NSArray *)parseUserIds:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"user-id", nil];

    return [parser parse:xml];
}

- (NSArray *)parseCreatorIds:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"creator-id", nil];

    return [parser parse:xml];
}

- (NSArray *)parseTicketComments:(NSData *)xml
{
    parser.className = @"TicketComment";
    parser.classElementType = @"version";
    parser.classElementCollection = @"versions";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"date", @"created-at",
            @"text", @"body",
            @"stateChangeDescription", @"diffable-attributes",
            nil];

    return [parser parse:xml];
}

- (NSArray *)parseTicketCommentAuthors:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"version";
    parser.classElementCollection = @"versions";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"creator-id", nil];

    return [parser parse:xml];
}

- (NSArray *)parseTicketUrls:(NSData *)xml
{
    parser.className = @"NSString";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"string", @"url", nil];

    return [parser parse:xml];
}

- (NSArray *)parseProjects:(NSData *)xml
{
    parser.className = @"Project";
    parser.classElementType = @"project";
    parser.classElementCollection = @"projects";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"name", @"name",
            nil];

    return [parser parse:xml];
}

- (NSArray *)parseProjectKeys:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"project";
    parser.classElementCollection = @"projects";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"", @"id",
            nil];

    return [parser parse:xml];
}

- (NSArray *)parseUsers:(NSData *)xml
{
    parser.className = @"User";
    parser.classElementType = @"user";
    parser.classElementCollection = @"memberships";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"name", @"name",
            @"job", @"job",
            @"websiteLink", @"website",
            @"avatarLink", @"avatar-url",
            nil];

    return [parser parse:xml];
}

- (NSArray *)parseUserKeys:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"membership";
    parser.classElementCollection = @"memberships";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"user-id", nil];

    return [parser parse:xml];
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
            @"goals", @"goals",
            nil];

    return [parser parse:xml];
}

- (NSArray *)parseMilestoneIds:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"milestone";
    parser.classElementCollection = @"milestones";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"id", nil];

    return [parser parse:xml];
}

- (NSArray *)parseMilestoneProjectIds:(NSData *)xml
{
    parser.className = @"NSNumber";
    parser.classElementType = @"milestone";
    parser.classElementCollection = @"milestones";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"number", @"project-id", nil];

    return [parser parse:xml];
}

- (NSArray *)parseTicketBins:(NSData *)xml
{
    parser.className = @"TicketBin";
    parser.classElementType = @"ticket-bin";
    parser.classElementCollection = @"ticket-bins";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"name", @"name",
            @"searchString", @"query",
            @"ticketCount", @"tickets-count",
            nil];

    return [parser parse:xml];
}

#pragma mark Delegate helpers

- (BOOL)invokeSelector:(SEL)selector withTarget:(id)target
    args:(id)firstArg, ...
{
    if ([target respondsToSelector:selector]) {
        NSMethodSignature * sig = [target methodSignatureForSelector:selector];
        NSInvocation * inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:target];
        [inv setSelector:selector];

        va_list args;
        va_start(args, firstArg);
        NSInteger argIdx = 2;

        for (id arg = firstArg; arg != nil; arg = va_arg(args, id), ++argIdx)
            [inv setArgument:&arg atIndex:argIdx];

        [inv invoke];

        return YES;
    }

    return NO;
}

#pragma mark Notification names

+ (NSString *)milestonesReceivedForAllProjectsNotificationName
{
    return @"BugWatchMilestonesReceivedNotification";
}

+ (NSString *)usersRecevedForProjectNotificationName
{
    return @"BugWatchUsersReceivedForProjectNotification";
}

#pragma mark General helpers

+ (id)uniqueTicketKey
{
    return [RandomNumber randomNumber];
}

@end
