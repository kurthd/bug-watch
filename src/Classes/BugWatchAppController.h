//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TicketsViewController.h"
#import "TicketCache.h"
#import "TicketDisplayMgr.h"
#import "ProjectsViewController.h"
#import "MessageCache.h"
#import "MessagesViewController.h"

@class NetworkAwareViewController;
@class NewsFeedDisplayMgr, MilestoneDisplayMgr;

@interface BugWatchAppController : NSObject
{
    IBOutlet NetworkAwareViewController * newsFeedNetworkAwareViewController;

    IBOutlet TicketsViewController * ticketsViewController;
    IBOutlet UINavigationController * ticketsNavController;

    IBOutlet ProjectsViewController * projectsViewController;
    IBOutlet UINavigationController * projectsNavController;

    IBOutlet NetworkAwareViewController * milestonesNetworkAwareViewController;

    IBOutlet MessagesViewController * messagesViewController;
    IBOutlet UINavigationController * messagesNavController;

    IBOutlet UIViewController * pagesViewController;
    IBOutlet UINavigationController * pagesNavController;

    TicketCache * ticketCache;
    MessageCache * messageCache;

    NewsFeedDisplayMgr * newsFeedDisplayMgr;
    MilestoneDisplayMgr * milestoneDisplayMgr;
}

- (void)start;

@end
