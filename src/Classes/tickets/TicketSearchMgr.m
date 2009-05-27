//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TicketSearchMgr.h"

@interface TicketSearchMgr (Private)

- (void)cancelSelected;
- (void)updateNavigationBarForNotSearching:(BOOL)animated;
- (void)initDarkTransparentView;
- (void)searchCurrentText;
- (void)forceQueryRefresh;

@end

@implementation TicketSearchMgr

@synthesize delegate;

- (void)dealloc
{
    [searchField release];
    [addButton release];
    [cancelButton release];
    [refreshButton release];
    [navigationItem release];
    [binViewController release];
    [parentView release];
    [dataSourceTarget release];
    
    [darkTransparentView release];

    [super dealloc];
}

- (id)initWithSearchField:(UITextField *)aSearchField
    addButton:(UIBarButtonItem *)anAddButton
    navigationItem:(UINavigationItem *)aNavigationItem
    ticketBinViewController:(TicketBinViewController *)aBinViewController
    parentView:(UIView *)aParentView dataSourceTarget:(id)aDataSourceTarget
    dataSourceAction:(SEL)aDataSourceAction
{
    if (self = [super init]) {
        searchField = [aSearchField retain];
        addButton = [anAddButton retain];
        navigationItem = [aNavigationItem retain];
        binViewController = [aBinViewController retain];
        parentView = [aParentView retain];
        dataSourceTarget = [aDataSourceTarget retain];
        dataSourceAction = aDataSourceAction;

        cancelButton = [[UIBarButtonItem alloc] init];
        cancelButton.title = @"Cancel";
        cancelButton.target = self;
        cancelButton.action = @selector(cancelSelected);
        
        refreshButton =
            [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
            target:self action:@selector(forceQueryRefresh)];

        searchField.delegate = self;
        // Can't be set in IB, so setting it here
        CGRect frame = searchField.frame;
        frame.size.height = 28;
        searchField.frame = frame;
        searchField.clearButtonMode = UITextFieldViewModeWhileEditing;

        [navigationItem setLeftBarButtonItem:nil];
        [self updateNavigationBarForNotSearching:NO];
        
        [self initDarkTransparentView];
    }

    return self;
}

- (void)initDarkTransparentView
{
    CGRect darkTransparentViewFrame = CGRectMake(0, 44, 320, 480);
    darkTransparentView =
        [[UIView alloc] initWithFrame:darkTransparentViewFrame];
    
    CGRect transparentViewFrame = CGRectMake(0, 0, 320, 480);
    UIView * transparentView =
        [[[UIView alloc] initWithFrame:transparentViewFrame] autorelease];
    transparentView.backgroundColor = [UIColor blackColor];
    transparentView.alpha = 0.8;
    [darkTransparentView addSubview:transparentView];
    
    CGRect activityIndicatorFrame = CGRectMake(142, 45, 37, 37);
    UIActivityIndicatorView * activityIndicator =
        [[UIActivityIndicatorView alloc] initWithFrame:activityIndicatorFrame];
    activityIndicator.activityIndicatorViewStyle =
        UIActivityIndicatorViewStyleWhiteLarge;
    [activityIndicator startAnimating];
    [darkTransparentView addSubview:activityIndicator];
    
    CGRect loadingLabelFrame = CGRectMake(21, 80, 280, 65);
    UILabel * loadingLabel =
        [[[UILabel alloc] initWithFrame:loadingLabelFrame] autorelease];
    loadingLabel.text = @"Loading ticket bins...";
    loadingLabel.textAlignment = UITextAlignmentCenter;
    loadingLabel.font = [UIFont boldSystemFontOfSize:20];
    loadingLabel.textColor = [UIColor whiteColor];
    loadingLabel.backgroundColor = [UIColor clearColor];
    [darkTransparentView addSubview:loadingLabel];
}

- (void)cancelSelected
{
    [self updateNavigationBarForNotSearching:YES];
    [searchField resignFirstResponder];
    [darkTransparentView removeFromSuperview];
    [binViewController.view removeFromSuperview];
}

- (void)updateNavigationBarForNotSearching:(BOOL)animated
{
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone
            forView:searchField cache:YES];
    }
    
    CGRect frame = searchField.frame;
    frame.size.width = 250;
    searchField.frame = frame;
    
    if (animated)
        [UIView commitAnimations];

    [navigationItem setRightBarButtonItem:refreshButton animated:animated];
    [navigationItem setLeftBarButtonItem:addButton animated:animated];
}

#pragma mark UITextFieldDelegate implementation

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // This improves a funky animation where it seems the text field text is
    // scaled larger and then shrunk back to it's desired size
    // The solution is simply to hide the text during the animation
    [searchField performSelector:@selector(setText:) withObject:searchField.text
        afterDelay:0.3];
    searchField.text = @"";

    [navigationItem setLeftBarButtonItem:nil animated:NO];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:searchField cache:YES];

    CGRect frame = searchField.frame;
    frame.size.width = 252;
    searchField.frame = frame;

    [UIView commitAnimations];

    [navigationItem setRightBarButtonItem:cancelButton animated:YES];

    darkTransparentView.alpha = 0;
    [parentView addSubview:darkTransparentView];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:darkTransparentView cache:YES];
    darkTransparentView.alpha = 1;
    [UIView commitAnimations];
    
    [dataSourceTarget performSelector:dataSourceAction withObject:nil
        afterDelay:0.6];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"Ticket search text field returning...");
    [self searchCurrentText];

    return YES;
}

#pragma mark TicketBinDataSourceDelegate implementation

- (void)receivedTicketBinsFromDataSource:(NSArray *)someTicketBins
{
    [binViewController setTicketBins:someTicketBins];
    [parentView addSubview:binViewController.view];
    [binViewController viewWillAppear:NO];
}

#pragma mark TicketBinViewControllerDelegate implementation

- (void)ticketBinSelectedWithQuery:(NSString *)query
{
    [delegate ticketsFilteredByFilterString:query];
    [self cancelSelected];
    searchField.text = query;
}

#pragma mark Private helper methods

- (void)searchCurrentText
{
    [delegate ticketsFilteredByFilterString:searchField.text];
    [self cancelSelected];
}

- (void)forceQueryRefresh
{
    [delegate forceQueryRefresh];
}

@end
