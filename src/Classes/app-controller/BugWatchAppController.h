//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TicketCache.h"
#import "TicketDisplayMgr.h"
#import "ProjectsViewController.h"
#import "MessageCache.h"
#import "MessagesViewController.h"
#import "MessageResponseCache.h"
#import "NewsFeedDataSource.h"
#import "MilestoneCacheSetter.h"
#import "ProjectCacheSetter.h"
#import "UserCacheSetter.h"
#import "TicketDisplayMgrFactory.h"
#import "TicketSearchMgrFactory.h"
#import "LighthouseApiServiceFactory.h"
#import "NetworkAwareViewController.h"
#import "MilestoneDisplayMgr.h"
#import "NewsFeedDisplayMgr.h"
#import "ProjectDisplayMgr.h"
#import "MilestoneCache.h"
#import "MessageDisplayMgr.h"
#import "MessageDisplayMgrFactory.h"
#import "LogInDisplayMgr.h"
#import "LighthouseCredentials.h"
#import "CredentialsUpdatePublisher.h"

@interface BugWatchAppController : NSObject
{
    IBOutlet NetworkAwareViewController * newsFeedNetworkAwareViewController;
    IBOutlet NetworkAwareViewController * ticketsNetAwareViewController;
    IBOutlet NetworkAwareViewController * projectsNetAwareViewController;
    IBOutlet NetworkAwareViewController * milestonesNetworkAwareViewController;
    IBOutlet NetworkAwareViewController * messagesNetAwareViewController;
    IBOutlet UIViewController * pagesViewController;
    IBOutlet UITabBarController * tabBarController;

    NewsFeedDisplayMgr * newsFeedDisplayMgr;
    NewsFeedDataSource * newsFeedDataSource;

    TicketDisplayMgrFactory * ticketDisplayMgrFactory;
    TicketDisplayMgr * ticketDisplayMgr;
    TicketDisplayMgr * projectLevelTicketDisplayMgr;
    TicketSearchMgrFactory * ticketSearchMgrFactory;

    ProjectDisplayMgr * projectDisplayMgr;
    ProjectCacheSetter * projectCacheSetter;

    MilestoneDisplayMgr * milestoneDisplayMgr;
    MilestoneCacheSetter * milestoneCacheSetter;

    MessageDisplayMgrFactory * messageDisplayMgrFactory;
    MessageDisplayMgr * messageDisplayMgr;
    MessageDisplayMgr * projectLevelMessageDisplayMgr;

    UserCacheSetter * userCacheSetter;

    LighthouseApiServiceFactory * lighthouseApiFactory;

    LogInDisplayMgr * logInDisplayMgr;
    LighthouseCredentials * credentials;
    CredentialsUpdatePublisher * credentialsUpdatePublisher;
}

- (void)start;
- (void)persistState;

@end
