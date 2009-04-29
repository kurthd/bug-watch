//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TicketsViewController.h"

@interface TicketsViewController (Private)

- (void)updateNavigationBarForNotSearching:(BOOL)animated;

@end

@implementation TicketsViewController

- (void)dealloc
{
    [searchTextField release];
    [cancelButton release];
    [addButton release];
    [super dealloc];
}

#pragma mark UIViewController implementation

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Can't be set in IB, so setting it here
    CGRect frame = searchTextField.frame;
    frame.size.height = 29;
    searchTextField.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavigationBarForNotSearching:animated];
}

#pragma mark UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView
    numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell * cell =
        [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell =
            [[[UITableViewCell alloc] initWithFrame:CGRectZero
            reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...

    return cell;
}

- (void)tableView:(UITableView *)aTableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark UITextFieldDelegate implementation

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:searchTextField cache:YES];

    CGRect frame = searchTextField.frame;
    frame.size.width = 245;
    searchTextField.frame = frame;

    [UIView commitAnimations];

    [self.navigationItem setRightBarButtonItem:cancelButton animated:YES];
}

#pragma mark TicketsViewController implementation

- (IBAction)cancelSelected:(id)sender
{
    [searchTextField resignFirstResponder];
    [self updateNavigationBarForNotSearching:YES];
}

- (IBAction)addSelected:(id)sender
{}

- (void)updateNavigationBarForNotSearching:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone
            forView:searchTextField cache:YES];
    }

    CGRect frame = searchTextField.frame;
    frame.size.width = 270;
    searchTextField.frame = frame;
    
    if (animated)
        [UIView commitAnimations];
    
    [self.navigationItem setRightBarButtonItem:addButton animated:animated];
}

@end

