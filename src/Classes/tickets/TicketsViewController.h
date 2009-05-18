//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TicketsViewControllerDelegate.h"

@interface TicketsViewController : UITableViewController
{
    NSObject<TicketsViewControllerDelegate> * delegate;

    NSDictionary * tickets;
    NSDictionary * metaData;
    NSDictionary * assignedToDict;
    NSDictionary * milestoneDict;

    UIView * headerView;
}

@property (nonatomic, retain)
    NSObject<TicketsViewControllerDelegate> * delegate;
@property (nonatomic, retain) UIView * headerView;

- (void)setTickets:(NSDictionary *)someTickets
    metaData:(NSDictionary *)someMetaData
    assignedToDict:(NSDictionary *)anAssignedToDict
    milestoneDict:(NSDictionary *)aMilestoneDict;

@end
