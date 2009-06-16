//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "BugWatchAppController.h"
#import "TicketDetailsViewController.h"
#import "NewsFeedViewController.h"
#import "LighthouseNewsFeedService.h"
#import "NetworkAwareViewController.h"
#import "TicketComment.h"
#import "MilestoneDetailsDataSource.h"
#import "MilestoneDetailsDisplayMgr.h"
#import "LighthouseApiService.h"
#import "MilestoneDataSource.h"
#import "MessageDisplayMgr.h"
#import "TicketsViewController.h"
#import "TicketDataSource.h"
#import "TicketSearchMgr.h"
#import "MessageResponseCache.h"
#import "AccountLevelTicketBinDataSource.h"
#import "TicketPersistenceStore.h"
#import "MilestoneUpdatePublisher.h"
#import "UIStatePersistenceStore.h"
#import "UIState.h"
#import "ProjectUpdatePublisher.h"
#import "UserSetAggregator.h"
#import "TicketDispMgrUserSetter.h"
#import "NewsFeedPersistenceStore.h"
#import "MilestonePersistenceStore.h"
#import "ProjectPersistenceStore.h"
#import "UserPersistenceStore.h"
#import "AllUserUpdatePublisher.h"
#import "ProjectDispMgrProjectSetter.h"
#import "ProjectSpecificTicketBinDSAdapter.h"
#import "MessagePersistenceStore.h"
#import "LogInDisplayMgr.h"
#import "LogInState.h"
#import "InfoPlistConfigReader.h"

@interface BugWatchAppController ()

- (void)initTicketsTab;
- (TicketDisplayMgr *)createTicketDispMgr:(TicketCache *)ticketCache
    addButton:(UIBarButtonItem *)addButton
    searchField:(UITextField *)searchField
    wrapperController:(NetworkAwareViewController *)wrapperController
    parentView:(UIView *)parentView
    ticketBinDataSource:(id)ticketBinDataSource;
- (TicketCache *)loadTicketsFromPersistence:(NSString *)plist;

- (void)initProjectsTab;
- (void)initMessagesTab;
- (void)initNewsFeedTab;
- (void)initMilestonesTab;

- (void)initSharedStateListeners;
+ (void)loadSharedStatesFromPersistence;
+ (void)broadcastMilestoneCache:(MilestoneCache *)cache;
+ (void)broadcastProjectCache:(ProjectCache *)cache;
+ (void)broadcastUserCache:(UserCache *)cache;

+ (NSString *)lighthouseDomain;
+ (NSString *)lighthouseScheme;

+ (NSString *)newsFeedCachePlist;
+ (NSString *)ticketCachePlist;
+ (NSString *)projectLevelTicketCachePlist;
+ (NSString *)projectCachePlist;
+ (NSString *)milestoneCachePlist;
+ (NSString *)messageCachePlist;
+ (NSString *)userCachePlist;

@property (nonatomic, copy) LighthouseCredentials * credentials;

@end

@implementation BugWatchAppController

@synthesize credentials;

- (void)dealloc
{
    [newsFeedNetworkAwareViewController release];
    [ticketsNetAwareViewController release];
    [projectsNetAwareViewController release];
    [milestonesNetworkAwareViewController release];
    [messagesNetAwareViewController release];
    [pagesViewController release];

    [newsFeedDisplayMgr release];
    [newsFeedDataSource release];

    [ticketDisplayMgrFactory release];
    [ticketDisplayMgr release];
    [projectLevelTicketDisplayMgr release];
    [ticketSearchMgrFactory release];

    [projectDisplayMgr release];
    [projectCacheSetter release];

    [milestoneDisplayMgr release];
    [milestoneCacheSetter release];

    [messageDisplayMgrFactory release];
    [messageDisplayMgr release];
    [projectLevelMessageDisplayMgr release];

    [userCacheSetter release];

    [lighthouseApiFactory release];

    [credentials release];
    [credentialsUpdatePublisher release];

    [super dealloc];
}

#pragma mark Public interface implementation

- (void)start
{
    NSString * domain = [[self class] lighthouseDomain];
    NSString * scheme = [[self class] lighthouseScheme];

    credentialsUpdatePublisher =
        [[CredentialsUpdatePublisher alloc]
        initWithListener:self action:@selector(credentialsChanged:)];

    lighthouseApiFactory =
        [[LighthouseApiServiceFactory alloc]
        initWithLighthouseDomain:domain scheme:scheme];
    ticketSearchMgrFactory =
        [[TicketSearchMgrFactory alloc] init];
    ticketDisplayMgrFactory =
        [[TicketDisplayMgrFactory alloc]
        initWithLighthouseApiFactory:lighthouseApiFactory];
    messageDisplayMgrFactory =
        [[MessageDisplayMgrFactory alloc]
        initWithLighthouseApiFactory:lighthouseApiFactory];

    [self initSharedStateListeners];

    // load single-session, global data (milestones, projects, users)
    LighthouseApiService * service =
        [[lighthouseApiFactory createLighthouseApiService] retain];

    [service fetchMilestonesForAllProjects];
    [service fetchAllProjects];

    [self initTicketsTab];
    [self initProjectsTab];
    [self initMessagesTab];
    [self initNewsFeedTab];
    [self initMilestonesTab];

    [[self class] loadSharedStatesFromPersistence];

    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];
    UIState * uiState = [uiStatePersistenceStore load];
    tabBarController.selectedIndex = uiState.selectedTab;
    if (uiState.selectedProject != 0) {
        NSNumber * selectedProjectKey =
            [NSNumber numberWithInt:uiState.selectedProject];
        projectDisplayMgr.selectedProjectKey = selectedProjectKey;
        [projectDisplayMgr presentSelectedProjectKey:selectedProjectKey
            animated:NO];
            
        if (uiState.selectedProjectTab != PROJECT_TAB_UNSELECTED)
            [projectDisplayMgr presentSelectedTab:uiState.selectedProjectTab
                animated:NO];
    }
}

- (void)persistState
{
    NSLog(@"Persisting state...");

    NewsFeedPersistenceStore * newsFeedPersistenceStore =
        [[[NewsFeedPersistenceStore alloc] init] autorelease];
    [newsFeedPersistenceStore saveNewsItems:newsFeedDataSource.cache
        toPlist:[[self class] newsFeedCachePlist]];

    TicketCache * ticketCache = ticketDisplayMgr.ticketCache;
    TicketPersistenceStore * ticketPersistenceStore =
        [[[TicketPersistenceStore alloc] init] autorelease];
    [ticketPersistenceStore saveTicketCache:ticketCache
        toPlist:[[self class] ticketCachePlist]];

    TicketCache * projectLevelTicketCache =
        projectLevelTicketDisplayMgr.ticketCache;
    [ticketPersistenceStore saveTicketCache:projectLevelTicketCache
        toPlist:[[self class] projectLevelTicketCachePlist]];

    MilestonePersistenceStore * milestonePersistenceStore =
        [[[MilestonePersistenceStore alloc] init] autorelease];
    [milestonePersistenceStore save:milestoneCacheSetter.cache
        toPlist:[[self class] milestoneCachePlist]];
        
    ProjectPersistenceStore * projectPersistenceStore =
        [[[ProjectPersistenceStore alloc] init] autorelease];
    [projectPersistenceStore saveProjectCache:projectCacheSetter.cache
        toPlist:[[self class] projectCachePlist]];
    
    MessageCache * messageCache = messageDisplayMgr.messageCache;
    MessagePersistenceStore * messagePersistenceStore =
        [[[MessagePersistenceStore alloc] init] autorelease];
    [messagePersistenceStore saveMessageCache:messageCache
        toPlist:[[self class] messageCachePlist]];

    UserPersistenceStore * userPersistenceStore =
        [[[UserPersistenceStore alloc] init] autorelease];
    [userPersistenceStore saveUserCache:userCacheSetter.cache
        toPlist:[[self class] userCachePlist]];

    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];
    UIState * uiState = [[[UIState alloc] init] autorelease];
    uiState.selectedTab = tabBarController.selectedIndex;
    uiState.selectedProject = [projectDisplayMgr.selectedProjectKey intValue];
    uiState.selectedProjectTab = projectDisplayMgr.selectedTab;
    [uiStatePersistenceStore save:uiState];
}

- (void)initSharedStateListeners
{
    milestoneCacheSetter = [[MilestoneCacheSetter alloc] init];
    [[MilestoneUpdatePublisher alloc]
        initWithListener:milestoneCacheSetter
        action:
        @selector(milestonesReceivedForAllProjects:milestoneKeys:projectKeys:)];

    projectCacheSetter = [[ProjectCacheSetter alloc] init];
    [[ProjectUpdatePublisher alloc]
        initWithListener:projectCacheSetter
        action:
        @selector(fetchedAllProjects:projectKeys:)];
        
    userCacheSetter = [[UserCacheSetter alloc] init];
    [[AllUserUpdatePublisher alloc]
        initWithListener:userCacheSetter
        action:@selector(fetchedAllUsers:)];
}

+ (void)loadSharedStatesFromPersistence
{
    MilestonePersistenceStore * milestonePersistenceStore =
        [[[MilestonePersistenceStore alloc] init] autorelease];
    MilestoneCache * milestoneCache =
        [milestonePersistenceStore
        loadFromPlist:[[self class] milestoneCachePlist]];
    [[self class] broadcastMilestoneCache:milestoneCache];

    ProjectPersistenceStore * projectPersistenceStore =
        [[[ProjectPersistenceStore alloc] init] autorelease];
    ProjectCache * projectCache =
        [projectPersistenceStore
        loadWithPlist:[[self class] projectCachePlist]];
    [[self class] broadcastProjectCache:projectCache];
    
    UserPersistenceStore * userPersistenceStore =
        [[[UserPersistenceStore alloc] init] autorelease];
    UserCache * userCache =
        [userPersistenceStore
        loadWithPlist:[[self class] userCachePlist]];
    [[self class] broadcastUserCache:userCache];
}

+ (void)broadcastProjectCache:(ProjectCache *)projectCache
{
    NSDictionary * projectDict = [projectCache allProjects];

    NSArray * projectKeys = [projectDict allKeys];
    NSMutableArray * projects = [NSMutableArray array];

    for (int i = 0; i < [projectKeys count]; i++) {
        id key = [projectKeys objectAtIndex:i];
        Project * project = [projectDict objectForKey:key];
        [projects insertObject:project atIndex:i];
    }

    // post general notification
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        projects, @"projects",
        projectKeys, @"projectKeys",
        nil];
    NSString * notificationName =
        [LighthouseApiService allProjectsReceivedNotificationName];
    [nc postNotificationName:notificationName object:self userInfo:userInfo];
}

+ (void)broadcastMilestoneCache:(MilestoneCache *)milestoneCache
{
    NSDictionary * milestoneDict = [milestoneCache allMilestones];
    NSDictionary * projectKeyDict = [milestoneCache allProjectMappings];

    NSArray * milestoneIds = [milestoneDict allKeys];
    NSMutableArray * milestones = [NSMutableArray array];
    NSMutableArray * projectIds = [NSMutableArray array];

    for (int i = 0; i < [milestoneIds count]; i++) {
        id key = [milestoneIds objectAtIndex:i];
        Milestone * milestone = [milestoneDict objectForKey:key];
        id projectKey = [projectKeyDict objectForKey:key];
        [milestones insertObject:milestone atIndex:i];
        [projectIds insertObject:projectKey atIndex:i];
    }

    // post general notification
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        milestones, @"milestones",
        milestoneIds, @"milestoneKeys",
        projectIds, @"projectKeys",
        nil];
    NSString * notificationName =
        [LighthouseApiService milestonesReceivedForAllProjectsNotificationName];
    [nc postNotificationName:notificationName object:self userInfo:userInfo];
}

+ (void)broadcastUserCache:(UserCache *)cache
{
    NSArray * userKeys = [[cache allUsers] allKeys];
    NSMutableArray * userArray = [NSMutableArray array];

    for (int i = 0; i < [userKeys count]; i++) {
        id key = [userKeys objectAtIndex:i];
        User * user = [cache userForKey:key];
        [userArray insertObject:user atIndex:i];
    }

    // post general notification
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        userArray, @"users",
        userKeys, @"userKeys",
        nil];
    NSString * notificationName =
        [UserSetAggregator allUsersReceivedNotificationName];
    [nc postNotificationName:notificationName object:self
        userInfo:userInfo];
}

#pragma mark Ticket tab initialization

- (void)initTicketsTab
{
    TicketCache * ticketCache =
        [self loadTicketsFromPersistence:[[self class] ticketCachePlist]];

    UIBarButtonItem * addButton =
        ticketsNetAwareViewController.navigationItem.rightBarButtonItem;
    UITextField * searchField =
        (UITextField *)
        ticketsNetAwareViewController.navigationItem.titleView;
    
    AccountLevelTicketBinDataSource * ticketBinDataSource = 
        [[[AccountLevelTicketBinDataSource alloc] init] autorelease];

    ticketDisplayMgr =
        [self createTicketDispMgr:ticketCache addButton:addButton
        searchField:searchField
        wrapperController:ticketsNetAwareViewController
        parentView:ticketsNetAwareViewController.navigationController.view
        ticketBinDataSource:ticketBinDataSource];
}

- (TicketDisplayMgr *)createTicketDispMgr:(TicketCache *)ticketCache
    addButton:(UIBarButtonItem *)addButton
    searchField:(UITextField *)searchField
    wrapperController:(NetworkAwareViewController *)wrapperController
    parentView:(UIView *)parentView ticketBinDataSource:(id)ticketBinDataSource
{
    TicketSearchMgr * ticketSearchMgr =
        [ticketSearchMgrFactory createTicketSearchMgrWithButton:addButton
        searchText:ticketCache.query searchField:searchField
        wrapperController:wrapperController parentView:parentView
        ticketBinDataSource:ticketBinDataSource];
    ((NSObject<TicketBinDataSourceProtocol> *)ticketBinDataSource).delegate =
        ticketSearchMgr;

    TicketDisplayMgr * aTicketDisplayMgr =
        [ticketDisplayMgrFactory createTicketDisplayMgrWithCache:ticketCache
        wrapperController:wrapperController ticketSearchMgr:ticketSearchMgr];
    addButton.target = aTicketDisplayMgr;
    addButton.action = @selector(addSelected);

    return aTicketDisplayMgr;
}

- (TicketCache *)loadTicketsFromPersistence:(NSString *)plist
{
    NSLog(@"Loading ticket cache from persistence...");
    TicketPersistenceStore * ticketPersistenceStore =
        [[[TicketPersistenceStore alloc] init] autorelease];
    TicketCache * ticketCache =
        [ticketPersistenceStore loadWithPlist:plist];
    NSLog(@"Loaded ticket cache from persistence.");
    
    return ticketCache;
}

#pragma mark Project tab initialization

- (void)initProjectsTab
{
    TicketCache * ticketCache =
        [self loadTicketsFromPersistence:
        [[self class] projectLevelTicketCachePlist]];
    UIBarButtonItem * addButton =
        [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil
        action:nil]
        autorelease];
    UITextField * searchField = [[[UITextField alloc] init] autorelease];
    static const CGFloat FONT_SIZE = 17.0;
    searchField.font = [UIFont systemFontOfSize:FONT_SIZE];
    searchField.minimumFontSize = FONT_SIZE;
    searchField.borderStyle = UITextBorderStyleRoundedRect;
    searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    searchField.placeholder = @"Filter tickets";
    searchField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchField.returnKeyType = UIReturnKeyGo;
    searchField.contentVerticalAlignment =
        UIControlContentVerticalAlignmentCenter;

    NetworkAwareViewController * wrapperController =
        [[[NetworkAwareViewController alloc] init] autorelease];
    wrapperController.navigationItem.title = @"Tickets";
    wrapperController.navigationItem.titleView = searchField;

    UIView * parentView =
        projectsNetAwareViewController.navigationController.view;

    LighthouseApiService * ticketBinService =
        [lighthouseApiFactory createLighthouseApiService];
    TicketBinDataSource * ticketBinDataSource =
        [[TicketBinDataSource alloc] initWithService:ticketBinService];
    ticketBinService.delegate = ticketBinDataSource;
    ProjectSpecificTicketBinDSAdapter * projSpecificTicketBinDS =
        [[ProjectSpecificTicketBinDSAdapter alloc]
        initWithTicketBinDataSource:ticketBinDataSource];
    ticketBinDataSource.delegate = projSpecificTicketBinDS;

    projectLevelTicketDisplayMgr =
        [self createTicketDispMgr:ticketCache addButton:addButton
        searchField:searchField wrapperController:wrapperController
        parentView:parentView ticketBinDataSource:projSpecificTicketBinDS];
    projectLevelTicketDisplayMgr.selectProject = NO;
    projSpecificTicketBinDS.ticketDisplayMgr = projectLevelTicketDisplayMgr;
    
    NetworkAwareViewController * messagesWrapperController =
        [[[NetworkAwareViewController alloc] init] autorelease];
    messagesWrapperController.navigationItem.title = @"Messages";
    projectLevelMessageDisplayMgr =
        [messageDisplayMgrFactory createMessageDisplayMgrWithCache:nil
        wrapperController:messagesWrapperController];
    projectLevelMessageDisplayMgr.selectProject = NO;

    UIBarButtonItem * composeMessageButton =
        [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:nil
        action:nil]
        autorelease];
    composeMessageButton.target = projectLevelMessageDisplayMgr;
    composeMessageButton.action = @selector(createNewMessage);
    messagesWrapperController.navigationItem.rightBarButtonItem =
        composeMessageButton;

    ProjectsViewController * projectsViewController =
        [[[ProjectsViewController alloc]
        initWithNibName:@"ProjectsView" bundle:nil] autorelease];
    projectsNetAwareViewController.targetViewController =
        projectsViewController;

    projectDisplayMgr =
        [[[ProjectDisplayMgr alloc]
        initWithProjectsViewController:projectsViewController
        networkAwareViewController:projectsNetAwareViewController
        ticketDisplayMgr:projectLevelTicketDisplayMgr
        messageDisplayMgr:projectLevelMessageDisplayMgr]
        autorelease];
    projectsViewController.delegate = projectDisplayMgr;
    
    ProjectDispMgrProjectSetter * projectSetter =
        [[ProjectDispMgrProjectSetter alloc]
        initWithProjectDisplayMgr:projectDisplayMgr];
    [[ProjectUpdatePublisher alloc]
        initWithListener:projectSetter
        action:@selector(fetchedAllProjects:projectKeys:)];
}

#pragma mark Message tab initialization

- (void)initMessagesTab
{
    MessagePersistenceStore * persistenceStore =
        [[[MessagePersistenceStore alloc] init] autorelease];
    MessageCache * messageCache =
        [persistenceStore loadMessageCacheWithPlist:
        [[self class] messageCachePlist]];

    messageDisplayMgr =
        [messageDisplayMgrFactory createMessageDisplayMgrWithCache:messageCache
        wrapperController:messagesNetAwareViewController];

    UIBarButtonItem * addButton =
        messagesNetAwareViewController.navigationItem.rightBarButtonItem;
    addButton.target = messageDisplayMgr;
    addButton.action = @selector(createNewMessage);
}

#pragma mark News feed tab initialization

- (void)initNewsFeedTab
{
    NSString * domain = [[self class] lighthouseDomain];
    NSString * scheme = [[self class] lighthouseScheme];
    // TEMPORARY
    NSString * account = @"highorderbit";
    NSString * token = @"6998f7ed27ced7a323b256d83bd7fec98167b1b3";
    // TEMPORARY

    // temporary instantiation of the log in state
    LogInState * logInState = nil;
    LogInDisplayMgr * logInDisplayMgr =
        [[LogInDisplayMgr alloc] initWithLogInState:logInState
                                 rootViewController:tabBarController
                                   lighthouseDomain:domain
                                   lighthouseScheme:scheme];

    UIBarButtonItem * logInButton =
        [[[UIBarButtonItem alloc]
        initWithTitle:NSLocalizedString(@"login.button.title", @"")
                style:UIBarButtonItemStylePlain
               target:logInDisplayMgr
               action:@selector(logIn)] autorelease];

    LighthouseUrlBuilder * builder =
        [LighthouseUrlBuilder builderWithLighthouseDomain:domain
                                                   scheme:scheme];
    LighthouseCredentials * cdtls =
        [[LighthouseCredentials alloc] initWithAccount:account
                                                 token:token];

    LighthouseNewsFeedService * newsFeedService =
        [[LighthouseNewsFeedService alloc] initWithUrlBuilder:builder
                                                  credentials:cdtls];
    NewsFeedPersistenceStore * newsFeedPersistenceStore =
        [[[NewsFeedPersistenceStore alloc] init] autorelease];
    NSArray * newsItemCache =
        [newsFeedPersistenceStore
        loadWithPlist:[[self class] newsFeedCachePlist]];
    newsFeedDataSource =
        [[NewsFeedDataSource alloc]
        initWithNewsFeedService:newsFeedService cache:newsItemCache];

    [newsFeedService release];

    newsFeedDisplayMgr =
        [[NewsFeedDisplayMgr alloc]
        initWithNetworkAwareViewController:newsFeedNetworkAwareViewController
                        newsFeedDataSource:newsFeedDataSource
                         leftBarButtonItem:logInButton];

    [newsFeedDataSource release];
}

#pragma mark Milestone tab initialization

- (void)initMilestonesTab
{
    MilestoneCache * milestoneCache =
        [[[MilestoneCache alloc] init] autorelease];

    LighthouseApiService * milestoneDetailsService =
        [lighthouseApiFactory createLighthouseApiService];

    MilestoneDetailsDataSource * milestoneDetailsDataSource =
        [[[MilestoneDetailsDataSource alloc]
        initWithLighthouseApiService:milestoneDetailsService
                         ticketCache:ticketDisplayMgr.ticketCache
                      milestoneCache:milestoneCache] autorelease];
    MilestoneDetailsDisplayMgr * milestoneDetailsDisplayMgr =
        [[[MilestoneDetailsDisplayMgr alloc]
        initWithMilestoneDetailsDataSource:milestoneDetailsDataSource]
        autorelease];

    LighthouseApiService * milestoneService =
        [lighthouseApiFactory createLighthouseApiService];
    MilestoneDataSource * milestoneDataSource =
        [[[MilestoneDataSource alloc]
        initWithLighthouseApiService:milestoneService
                      milestoneCache:milestoneCache] autorelease];
    milestoneDisplayMgr =
        [[MilestoneDisplayMgr alloc]
        initWithNetworkAwareViewController:milestonesNetworkAwareViewController
        milestoneDataSource:milestoneDataSource
        milestoneDetailsDisplayMgr:milestoneDetailsDisplayMgr];
}

#pragma mark Log in/log out notifications

- (void)credentialsChanged:(LighthouseCredentials *)someCredentials
{
    self.credentials = someCredentials;
}

#pragma mark Configuration values

+ (NSString *)lighthouseDomain
{
    InfoPlistConfigReader * configReader = [InfoPlistConfigReader reader];
    return [configReader valueForKey:@"LighthouseDomain"];
}

+ (NSString *)lighthouseScheme
{
    InfoPlistConfigReader * configReader = [InfoPlistConfigReader reader];
    return [configReader valueForKey:@"LighthouseScheme"];
}

#pragma mark String constants

+ (NSString *)newsFeedCachePlist
{
    return @"NewsFeedCache";
}

+ (NSString *)ticketCachePlist
{
    return @"TicketCache";
}

+ (NSString *)projectLevelTicketCachePlist
{
    return @"ProjectLevelTicketCache";
}

+ (NSString *)projectCachePlist
{
    return @"ProjectCache";
}

+ (NSString *)milestoneCachePlist
{
    return @"MilestoneCache";
}

+ (NSString *)messageCachePlist
{
    return @"MessageCache";
}

+ (NSString *)userCachePlist
{
    return @"UserCache";
}

@end
