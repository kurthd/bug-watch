//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MessageDisplayMgr.h"

@implementation MessageDisplayMgr

- (void)dealloc
{
    [messageCache release];
    [messagesViewController release];
    [wrapperController release];

    [newMessageViewController release];
    [detailsViewController release];

    // TEMPORARY
    [userDict release];
    // TEMPORARY
    
    [super dealloc];
}

- (id)initWithMessageCache:(MessageCache *)aMessageCache
    networkAwareViewController:(NetworkAwareViewController *)aWrapperController
    messagesViewController:(MessagesViewController *)aMessagesViewController
{
    if (self = [super init]) {
        messageCache = [aMessageCache retain];
        wrapperController = [aWrapperController retain];
        messagesViewController = [aMessagesViewController retain];
        
        // TEMPORARY
        // this will eventually be read from a user cache of some sort
        userDict = [[NSMutableDictionary dictionary] retain];
        [userDict setObject:@"Doug Kurth" forKey:[NSNumber numberWithInt:0]];
        [userDict setObject:@"John A. Debay" forKey:[NSNumber numberWithInt:1]];
        // TEMPORARY
    }

    return self;
}

#pragma mark MessagesViewControllerDelegate implementation

- (void)showAllMessages
{
    // TEMPORARY
    wrapperController.cachedDataAvailable = YES;
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    // TEMPORARY
    
    NSMutableDictionary * postedByDict = [NSMutableDictionary dictionary];
    NSDictionary * allPostedByKeys = [messageCache allPostedByKeys];
    for (id key in allPostedByKeys) {
        id postedByKey = [allPostedByKeys objectForKey:key];
        NSString * postedByName = [userDict objectForKey:postedByKey];
        [postedByDict setObject:postedByName forKey:key];
    }
    
    NSMutableDictionary * projectDict = [NSMutableDictionary dictionary];

    [messagesViewController setMessages:[messageCache allMessages]
        postedByDict:postedByDict projectDict:projectDict];
}

- (void)selectedMessageKey:(id)key
{
    NSLog(@"Message %@ selected", key);
    [self.navController
        pushViewController:self.detailsViewController animated:YES];

    [self.detailsViewController setAuthorName:nil date:nil projectName:nil
        title:nil comment:nil];
}

#pragma mark NetworkAwareViewControllerDelegate

- (void)networkAwareViewWillAppear
{
    [self showAllMessages];
}

#pragma mark MessageDisplayMgr implementation

- (void)createNewMessage
{
    NSLog(@"Presenting 'create message' view");
    [self.navController presentModalViewController:self.newMessageViewController
        animated:YES];
}

#pragma mark Accessors

- (NewMessageViewController *)newMessageViewController
{
    if (!newMessageViewController) {
        newMessageViewController =
            [[NewMessageViewController alloc]
            initWithNibName:@"NewMessageView" bundle:nil];
    }

    return newMessageViewController;
}

- (MessageDetailsViewController *)detailsViewController
{
    if (!detailsViewController) {
        detailsViewController =
            [[MessageDetailsViewController alloc]
            initWithNibName:@"MessageDetailsView" bundle:nil];
    }

    return detailsViewController;
}

- (UINavigationController *)navController
{
    return wrapperController.navigationController;
}

@end
