//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "MilestonesTableViewCell.h"
#import "RoundedRectView.h"
#import "Milestone.h"
#import "NSDate+StringHelpers.h"

@interface MilestonesTableViewCell ()

- (void)setSelectedColors;
- (void)setNonSelectedColors;

@end

@implementation MilestonesTableViewCell

@synthesize milestone;

- (void)dealloc
{
    [nameLabel release];
    [dueDateLabel release];

    [numOpenTicketsView release];
    [numOpenTicketsLabel release];
    [numOpenTicketsTitleLabel release];
    [numOpenTicketsViewBackgroundColor release];

    [progressView release];

    [milestone release];

    [super dealloc];
}

- (void)awakeFromNib
{
    // cache the num tickets view's background color set in the nib
    numOpenTicketsViewBackgroundColor =
        [numOpenTicketsView.backgroundColor retain];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    nameLabel.text = milestone.name;
    if (milestone.dueDate)
        dueDateLabel.text =
            [NSString stringWithFormat:
            NSLocalizedString(@"milestones.due.future.formatstring", @""),
            [milestone.dueDate shortDateDescription]];
    else
        dueDateLabel.text =
            NSLocalizedString(@"milestones.due.never.formatstring", @"");

    numOpenTicketsLabel.text =
        [NSString stringWithFormat:@"%d", milestone.numOpenTickets];
    numOpenTicketsTitleLabel.text =
        milestone.numOpenTickets == 1 ?
        NSLocalizedString(@"milestones.tickets.open.count.label.singular",
        @"") :
        NSLocalizedString(@"milestones.tickets.open.count.label.plural", @"");

    if (milestone.numTickets == 0)
        progressView.progress = 0.0;
    else
        progressView.progress =
            ((float) milestone.numTickets - milestone.numOpenTickets) /
            (float) milestone.numTickets;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    if (selected)
        [self setSelectedColors];
    else
        [self setNonSelectedColors];
}

#pragma mark Setting selection colors

- (void)setSelectedColors
{
    nameLabel.textColor = [UIColor whiteColor];
    dueDateLabel.textColor = [UIColor whiteColor];

    numOpenTicketsView.fillColor = [UIColor whiteColor];
    numOpenTicketsLabel.textColor = [UIColor blackColor];
    numOpenTicketsTitleLabel.textColor = [UIColor blackColor];
}

- (void)setNonSelectedColors
{
    nameLabel.textColor = [UIColor blackColor];
    dueDateLabel.textColor = [UIColor blackColor];

    numOpenTicketsView.fillColor = numOpenTicketsViewBackgroundColor;
    numOpenTicketsLabel.textColor = [UIColor whiteColor];
    numOpenTicketsTitleLabel.textColor = [UIColor whiteColor];
}

@end
