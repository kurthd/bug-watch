//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MessageDataSource.h"

@implementation MessageDataSource

@synthesize delegate, token;

- (void)dealloc
{
    [service release];
    [token release];
    [super dealloc];
}

- (id)initWithService:(LighthouseApiService *)aService
{
    if (self = [super init])
        service = [aService retain];

    return self;
}

- (void)fetchMessagesForProject:(NSNumber *)projectKey
{
    [service fetchMessagesForProject:projectKey token:self.token];
}

- (void)fetchCommentsForMessage:(LighthouseKey *)messageKey
{
    [service fetchCommentsForMessage:[NSNumber numberWithInt:messageKey.key]
        inProject:[NSNumber numberWithInt:messageKey.projectKey] token:token];
}

- (void)createMessageWithDescription:(NewMessageDescription *)desc
    forProject:(NSNumber *)projectKey
{
    [service createMessage:desc forProject:projectKey token:token];
}

#pragma mark LighthouseApiServiceDelegate implementation

- (void)messages:(NSArray *)messages messageKeys:(NSArray *)messageKeys
    authorKeys:(NSArray *)authorKeys fetchedForProject:(id)projectKey
{
    MessageCache * messageCache = [[[MessageCache alloc] init] autorelease];
    for (int i = 0; i < [messages count]; i++) {
        NSNumber * key = [messageKeys objectAtIndex:i];
        LighthouseKey * messageKey =
            [[[LighthouseKey alloc]
            initWithProjectKey:[(NSNumber *)projectKey integerValue]
            key:[key integerValue]]
            autorelease];
        Message * message = [messages objectAtIndex:i];
        NSNumber * authorKey = [authorKeys objectAtIndex:i];
        [messageCache setMessage:message forKey:messageKey];
        [messageCache setProjectKey:projectKey forKey:messageKey];
        [messageCache setPostedByKey:authorKey forKey:messageKey];
    }

    [delegate receivedMessagesFromDataSource:messageCache];
}

- (void)failedToFetchMessagesForProject:(id)projectKey error:(NSError *)error
{}

- (void)message:(id)messageKey describedBy:(NewMessageDescription *)desc
    createdForProject:(id)projectKey
{
    [delegate createdMessageWithKey:nil];
}

- (void)failedToCreateMessageDescribedBy:(NewMessageDescription *)desc
    forProject:(id)projectKey error:(NSError *)error
{}

- (void)comments:(NSArray *)comments commentKeys:(NSArray *)commentKeys
    authorKeys:(NSArray *)authorKeys fetchedForMessage:(id)key
    inProject:(id)projectKey
{
    MessageResponseCache * messageResponseCache =
        [[[MessageResponseCache alloc] init] autorelease];
    for (int i = 0; i < [comments count]; i++) {
        NSNumber * commentKey = [commentKeys objectAtIndex:i];
        MessageResponse * comment = [comments objectAtIndex:i];
        NSNumber * authorKey = [authorKeys objectAtIndex:i];
        [messageResponseCache setResponse:comment forKey:commentKey];
        [messageResponseCache setAuthorKey:authorKey forKey:commentKey];
    }
    LighthouseKey * messageKey =
        [[[LighthouseKey alloc]
        initWithProjectKey:[(NSNumber *)projectKey integerValue]
        key:[key integerValue]]
        autorelease];
    [delegate receivedComments:messageResponseCache forMessage:messageKey];
}

- (void)failedToFetchCommentsForMessage:(id)messageKey inProject:(id)projectKey
    errors:(NSArray *)errors
{}

@end