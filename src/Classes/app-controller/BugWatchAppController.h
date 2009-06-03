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
#import "MilestoneCache.h"

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
    TicketSearchMgrFactory * ticketSearchMgrFactory;

    ProjectCacheSetter * projectCacheSetter;

    MessageCache * messageCache;
    MessageResponseCache * messageResponseCache;

    MilestoneDisplayMgr * milestoneDisplayMgr;
    MilestoneCacheSetter * milestoneCacheSetter;
    
    UserCacheSetter * userCacheSetter;
    
    LighthouseApiServiceFactory * lighthouseApiFactory;
}

- (void)start;
- (void)persistState;

@end
