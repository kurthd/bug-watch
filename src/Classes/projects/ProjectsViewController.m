//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ProjectsViewController.h"
#import "TextWithCountTableViewCell.h"

@implementation ProjectsViewController

@synthesize delegate;

- (void)dealloc
{
    [delegate release];
    [super dealloc];
}

#pragma mark UITableViewDataSource implementationp

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return 1; // TEMPORARY
}

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"TextWithCountTableViewCell";
    
    TextWithCountTableViewCell * cell =
        (TextWithCountTableViewCell *)
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray * nib =
            [[NSBundle mainBundle] loadNibNamed:@"TextWithCountTableViewCell"
            owner:self options:nil];

        cell = [nib objectAtIndex:0];
    }

    [cell setText:@"Code Watch"];
    [cell setCount:14];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [delegate selectedProjectKey:nil];
}

@end
