//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MessageDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface MessageDisplayMgr (Private)

- (void)initDarkTransparentView;
- (void)displayCachedMessages;
- (void)displayMessageDetails:(LighthouseKey *)key;
- (void)disableEditViewWithText:(NSString *)text;
- (void)enableEditView:(BOOL)dismiss;
- (void)updateDisplayIfDirty;
- (void)displayErrorWithTitle:(NSString *)title errors:(NSArray *)errors;

@end

@implementation MessageDisplayMgr

@synthesize messageCache, userDict, projectDict, activeProjectKey,
    selectProject, wrapperController;

- (void)dealloc
{
    [messageCache release];
    [recentHistoryResponseCache release];
    [dataSource release];
    [messagesViewController release];
    [wrapperController release];

    [newMessageViewController release];
    [detailsViewController release];
    [detailsNetAwareViewController release];

    [userDict release];
    [projectDict release];

    [darkTransparentView release];
    [loadingLabel release];

    [activeProjectKey release];

    [super dealloc];
}

- (id)initWithMessageCache:(MessageCache *)aMessageCache
    dataSource:(MessageDataSource *)aDataSource
    networkAwareViewController:(NetworkAwareViewController *)aWrapperController
    messagesViewController:(MessagesViewController *)aMessagesViewController
{
    if (self = [super init]) {
        messageCache = [aMessageCache retain];
        dataSource = [aDataSource retain];
        wrapperController = [aWrapperController retain];
        messagesViewController = [aMessagesViewController retain];

        self.activeProjectKey = nil;
        wrapperController.cachedDataAvailable = NO;
        self.selectProject = YES;
        displayDirty = YES;

        [self initDarkTransparentView];

        recentHistoryResponseCache =
            [[RecentHistoryCache alloc] initWithCacheLimit:20];
    }

    return self;
}

- (void)initDarkTransparentView
{
    CGRect darkTransparentViewFrame = CGRectMake(0, 0, 320, 480);
    darkTransparentView =
        [[UIView alloc] initWithFrame:darkTransparentViewFrame];

    CGRect transparentViewFrame = CGRectMake(0, 0, 320, 480);
    UIView * transparentView =
        [[[UIView alloc] initWithFrame:transparentViewFrame] autorelease];
    transparentView.backgroundColor = [UIColor blackColor];
    transparentView.alpha = 0.8;
    [darkTransparentView addSubview:transparentView];
    
    CGRect activityIndicatorFrame = CGRectMake(142, 85, 37, 37);
    UIActivityIndicatorView * activityIndicator =
        [[UIActivityIndicatorView alloc] initWithFrame:activityIndicatorFrame];
    activityIndicator.activityIndicatorViewStyle =
        UIActivityIndicatorViewStyleWhiteLarge;
    [activityIndicator startAnimating];
    [darkTransparentView addSubview:activityIndicator];
    
    CGRect loadingLabelFrame = CGRectMake(21, 120, 280, 65);
    loadingLabel = [[UILabel alloc] initWithFrame:loadingLabelFrame];
    loadingLabel.text =
        NSLocalizedString(@"messagedisplaymgr.creatingmessage", @"");
    loadingLabel.textAlignment = UITextAlignmentCenter;
    loadingLabel.font = [UIFont boldSystemFontOfSize:20];
    loadingLabel.textColor = [UIColor whiteColor];
    loadingLabel.backgroundColor = [UIColor clearColor];
    [darkTransparentView addSubview:loadingLabel];
}

#pragma mark MessagesViewControllerDelegate implementation

- (void)showAllMessages
{
    NSLog(@"Showing messages...");
    // Make sure we've received a project dictionary already, otherwise wait
    // and show all messages after it has arrived
    if (self.activeProjectKey || self.projectDict) {
        wrapperController.cachedDataAvailable = !!messageCache;

        if (messageCache) 
            [self displayCachedMessages];

        resetCache = YES;
        [wrapperController setUpdatingState:kConnectedAndUpdating];
        if (selectProject) {
            for (id projectKey in [self.projectDict allKeys])
                [dataSource fetchMessagesForProject:projectKey];
        } else
            [dataSource fetchMessagesForProject:self.activeProjectKey];
    }
}

- (void)updateDisplayIfDirty
{
    if (displayDirty) {
        [self showAllMessages];
        displayDirty = NO;
    }
}

- (void)displayCachedMessages
{
    if (messageCache) {
        NSMutableDictionary * postedByDict = [NSMutableDictionary dictionary];
        NSMutableDictionary * msgProjectDict = [NSMutableDictionary dictionary];

        NSArray * allMessageKeys = [[messageCache allMessages] allKeys];
        for (id key in allMessageKeys) {
            id postedByKey = [messageCache postedByKeyForKey:key];
            NSString * postedByName = [userDict objectForKey:postedByKey];
            if (postedByName)
                [postedByDict setObject:postedByName forKey:key];
        
            id projectKey = [messageCache projectKeyForKey:key];
            NSString * projectName = [projectDict objectForKey:projectKey];
            if (projectName)
                [msgProjectDict setObject:projectName forKey:key];
        }

        [messagesViewController setMessages:[messageCache allMessages]
            postedByDict:postedByDict projectDict:msgProjectDict];

        wrapperController.cachedDataAvailable = YES;
    }
}

- (void)selectedMessageKey:(LighthouseKey *)key
{
    NSLog(@"Message %@ selected", key);
    [self.navController pushViewController:self.detailsNetAwareViewController
        animated:YES];

    MessageResponseCache * responseCache =
        [recentHistoryResponseCache objectForKey:key];

    if (responseCache)
        [self displayMessageDetails:key];

    [dataSource fetchCommentsForMessage:key];
    self.detailsNetAwareViewController.cachedDataAvailable = !!responseCache;
    [self.detailsNetAwareViewController setUpdatingState:kConnectedAndUpdating];
}

- (void)displayMessageDetails:(LighthouseKey *)key
{
    [self.detailsNetAwareViewController
        setUpdatingState:kConnectedAndNotUpdating];        
    self.detailsNetAwareViewController.cachedDataAvailable = YES;

    MessageResponseCache * responseCache =
        [recentHistoryResponseCache objectForKey:key];

    Message * message = [messageCache messageForKey:key];
    NSString * postedBy =
        [userDict objectForKey:[messageCache postedByKeyForKey:key]];
    NSString * project =
        [projectDict objectForKey:[messageCache projectKeyForKey:key]];
    NSArray * responseKeys = [[responseCache allResponses] allKeys];
    NSMutableDictionary * responses = [NSMutableDictionary dictionary];
    NSMutableDictionary * responseAuthors = [NSMutableDictionary dictionary];
    for (id key in responseKeys) {
        MessageResponse * response = [responseCache responseForKey:key];
        [responses setObject:response forKey:key];
        id authorKey = [responseCache authorKeyForKey:key];
        NSString * authorName = [userDict objectForKey:authorKey];
        [responseAuthors setObject:authorName forKey:key];
    }

    [self.detailsViewController setAuthorName:postedBy date:message.postedDate
        projectName:project title:message.title comment:message.message
        responses:responses responseAuthors:responseAuthors link:message.link];
}

#pragma mark NetworkAwareViewControllerDelegate

- (void)networkAwareViewWillAppear
{
    [self updateDisplayIfDirty];
}

#pragma mark MessageDataSourceDelegate implementation

- (void)receivedMessagesFromDataSource:(MessageCache *)aMessageCache
{
    NSLog(@"Received messages from data source: %@", aMessageCache);
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    if (resetCache)
        self.messageCache = aMessageCache;
    else
        [self.messageCache merge:aMessageCache];
    [self displayCachedMessages];
    resetCache = NO;
}

- (void)failedToFetchMessages:(NSArray *)errors
{
    NSString * title =
        NSLocalizedString(@"messagedisplaymgr.error.messagesfetch.title", @"");

    [self displayErrorWithTitle:title errors:errors];
}

- (void)receivedComments:(MessageResponseCache *)cache
    forMessage:(LighthouseKey *)messageKey
{
    NSLog(@"Received comments for message %@: %@", messageKey, cache);
    
    [recentHistoryResponseCache setObject:cache forKey:messageKey];
    [self displayMessageDetails:messageKey];
}

- (void)failedToFetchCommentsForMessage:(LighthouseKey *)messageKey
    errors:(NSArray *)errors
{
    NSString * title =
        NSLocalizedString(@"messagedisplaymgr.error.detailsfetch.title", @"");

    [self displayErrorWithTitle:title errors:errors];
}

- (void)createdMessageWithKey:(LighthouseKey *)key
{
    [self enableEditView:YES];
    [self showAllMessages];
}

- (void)failedToCreateMessage:(NSArray *)errors
{
    [self enableEditView:NO];

    NSString * title =
        NSLocalizedString(@"messagedisplaymgr.error.create.title", @"");

    [self displayErrorWithTitle:title errors:errors];
}

- (void)displayErrorWithTitle:(NSString *)title errors:(NSArray *)errors
{
    NSLog(@"Failed to update messages view: %@.", errors);

    NSError * firstError = [errors objectAtIndex:0];
    NSString * message =
        firstError ? firstError.localizedDescription : @"";

    UIAlertView * alertView =
        [UIAlertView simpleAlertViewWithTitle:title message:message];
    [alertView show];

    [wrapperController setUpdatingState:kDisconnected];
    [detailsNetAwareViewController setUpdatingState:kDisconnected];
}

#pragma mark NewMessageViewControllerDelegate implementation

- (void)postNewMessage:(NSString *)message withTitle:(NSString *)title
{
    NSLog(@"Posting message to server: %@", title);
    [self disableEditViewWithText:@"Posting message..."];
    NewMessageDescription * description = [NewMessageDescription description];
    description.title = title;
    description.body = message;
    [dataSource createMessageWithDescription:description
        forProject:self.activeProjectKey];
}

#pragma mark MessageDisplayMgr implementation

- (void)createNewMessage
{
    NSLog(@"Presenting 'create message' view");

    UIViewController * rootViewController;

    if (selectProject) {
        rootViewController = self.projectSelectionViewController;
        self.projectSelectionViewController.projects = projectDict;
    } else
        rootViewController = self.newMessageViewController;

    UINavigationController * tempNavController =
        [[[UINavigationController alloc]
        initWithRootViewController:rootViewController]
        autorelease];

    [self.navController presentModalViewController:tempNavController
        animated:YES];
}

- (void)userDidSelectActiveProjectKey:(NSNumber *)key
{
    NSLog(@"User selected project %@ for message editing", key);
    self.activeProjectKey = key;
    [self.projectSelectionViewController.navigationController
        pushViewController:self.newMessageViewController animated:YES];
}

- (void)disableEditViewWithText:(NSString *)text
{
    loadingLabel.text = text;
    [self.newMessageViewController.view.superview
        addSubview:darkTransparentView];
    self.newMessageViewController.cancelButton.enabled = NO;
    self.newMessageViewController.postButton.enabled = NO;
}

- (void)enableEditView:(BOOL)dismiss
{
    [darkTransparentView removeFromSuperview];
    if (dismiss)
        [self.newMessageViewController dismissModalViewControllerAnimated:YES];
    self.newMessageViewController.cancelButton.enabled = YES;
    self.newMessageViewController.postButton.enabled = YES;
}

#pragma mark API credential management

- (void)credentialsChanged:(LighthouseCredentials *)credentials
{
    [dataSource setCredentials:credentials];
    self.messageCache = nil;
    [self.wrapperController.navigationController
        popToRootViewControllerAnimated:NO];
}

#pragma mark Accessors

- (NewMessageViewController *)newMessageViewController
{
    if (!newMessageViewController) {
        newMessageViewController =
            [[NewMessageViewController alloc]
            initWithNibName:@"NewMessageView" bundle:nil];
    }
    newMessageViewController.navigationItem.hidesBackButton = YES;
    newMessageViewController.delegate = self;

    return newMessageViewController;
}

- (ProjectSelectionViewController *)projectSelectionViewController
{
    if (!projectSelectionViewController) {
        projectSelectionViewController =
            [[ProjectSelectionViewController alloc]
            initWithNibName:@"ProjectSelectionView" bundle:nil];
        projectSelectionViewController.target = self;
        projectSelectionViewController.action =
            @selector(userDidSelectActiveProjectKey:);
    }

    return projectSelectionViewController;
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

- (NetworkAwareViewController *)detailsNetAwareViewController
{
    if (!detailsNetAwareViewController) {
        detailsNetAwareViewController =
            [[NetworkAwareViewController alloc]
            initWithTargetViewController:self.detailsViewController];
        detailsNetAwareViewController.navigationItem.title = @"Message Details";
    }

    return detailsNetAwareViewController;
}

- (UINavigationController *)navController
{
    return wrapperController.navigationController;
}

- (void)setProjectDict:(NSDictionary *)aProjectDict
{
    NSDictionary * tempProjectDict = [aProjectDict copy];
    [projectDict release];
    projectDict = tempProjectDict;
    [self displayCachedMessages];
}

- (void)setUserDict:(NSDictionary *)aUserDict
{
    NSDictionary * tempUserDict = [aUserDict copy];
    [userDict release];
    userDict = tempUserDict;
    [self displayCachedMessages];
}

- (void)setActiveProjectKey:(NSNumber *)anActiveProjectKey
{
    [anActiveProjectKey retain];
    [activeProjectKey release];
    activeProjectKey = anActiveProjectKey;
    displayDirty = YES;
}

@end
