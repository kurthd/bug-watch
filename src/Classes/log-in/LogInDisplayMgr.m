//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "LogInDisplayMgr.h"
#import "LogInViewController.h"
#import "LighthouseAccountAuthenticator.h"
#import "LighthouseCredentials.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface LogInDisplayMgr ()

- (void)beginLogIn;
- (void)beginLogOut;

- (void)promptForLogOutConfirmation;

- (void)sendCredentialsChangedNotification;

@property (nonatomic, copy) LighthouseCredentials * credentials;
@property (nonatomic, retain) LogInViewController * logInViewController;
@property (nonatomic, retain) UIViewController * rootViewController;

@property (nonatomic, copy) NSString * lighthouseDomain;
@property (nonatomic, copy) NSString * lighthouseScheme;

@end

@implementation LogInDisplayMgr

@synthesize credentials, logInViewController, rootViewController;
@synthesize lighthouseDomain, lighthouseScheme;

- (void)dealloc
{
    self.credentials = nil;
    self.logInViewController = nil;
    self.rootViewController = nil;
    self.lighthouseDomain = nil;
    self.lighthouseScheme = nil;
    [super dealloc];
}

- (id)initWithCredentials:(LighthouseCredentials *)someCredentials
       rootViewController:(UIViewController *)aRootViewController
         lighthouseDomain:(NSString *)aLighthouseDomain
         lighthouseScheme:(NSString *)aLighthouseScheme
{
    if (self = [super init]) {
        self.credentials = someCredentials;

        self.rootViewController = aRootViewController;

        self.lighthouseDomain = aLighthouseDomain;
        self.lighthouseScheme = aLighthouseScheme;
    }

    return self;
}

- (void)logIn
{
    if (self.credentials)
        [self beginLogOut];
    else
        [self beginLogIn];
}

- (void)beginLogIn
{
    [rootViewController presentModalViewController:self.logInViewController
                                          animated:YES];
    [self.logInViewController promptForLogIn];
}

- (void)beginLogOut
{
    [self promptForLogOutConfirmation];
}

#pragma mark LogInViewController delegate implementation

- (void)userDidProvideAccount:(NSString *)account
                     username:(NSString *)username
                     password:(NSString *)password
{
    NSLog(@"User provided account: '%@', username: '%@', password: '********'.",
        account, username);

    LighthouseAccountAuthenticator * authenticator =
        [[LighthouseAccountAuthenticator alloc]
        initWithLighthouseDomain:lighthouseDomain scheme:lighthouseScheme];
    authenticator.delegate = self;

    LighthouseCredentials * attemptedCredentials =
        [[LighthouseCredentials alloc] initWithAccount:account
                                              username:username
                                              password:password];

    [authenticator authenticateCredentials:attemptedCredentials];
}

- (void)userDidCancel
{
    [rootViewController dismissModalViewControllerAnimated:YES];

    // notify delegate that log in was cancelled.
}

- (void)promptForLogOutConfirmation
{
    NSString * title = NSLocalizedString(@"logout.confirm.title", @"");
    NSString * cancel = NSLocalizedString(@"logout.confirm.cancel.text", @"");
    NSString * confirm = NSLocalizedString(@"logout.confirm.logout.text", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc] initWithTitle:title
                                    delegate:self
                           cancelButtonTitle:cancel
                      destructiveButtonTitle:confirm
                           otherButtonTitles:nil];
    [sheet showInView:rootViewController.view];
}

#pragma mark UIAlertSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)sheet
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"User clicked button at index: %d.", buttonIndex);

    if (buttonIndex == 0) {  // user really wants to log out
        self.credentials = nil;
        [self sendCredentialsChangedNotification];
    }

    [sheet autorelease];
}

#pragma mark LighthouseAccountAuthenticatorDelegate implementation

- (void)authenticatedAccount:(LighthouseCredentials *)someCredentials
{
    NSLog(@"User successfully authenticated credentials: '%@'.",
        someCredentials);

    [rootViewController dismissModalViewControllerAnimated:YES];

    self.credentials = someCredentials;
    [self sendCredentialsChangedNotification];
}

- (void)failedToAuthenticateAccount:(LighthouseCredentials *)someCredentials
                             errors:(NSArray *)errors
{
    NSLog(@"Failed to authenticate user with credentials: '%@', errors: '%@'.",
        someCredentials, errors);

    [self.logInViewController promptForLogIn];

    NSString * title = NSLocalizedString(@"login.failed.alert.title", @"");
    NSString * message = [[errors lastObject] localizedDescription];
    
    UIAlertView * alert = [UIAlertView simpleAlertViewWithTitle:title
                                                        message:message];
    [alert show];
}

- (void)sendCredentialsChangedNotification
{
    // notify the system that the 'logged in' credentials have changed
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
    if (self.credentials)
        [userInfo setObject:self.credentials forKey:@"credentials"];
    NSString * notificationName =
        [[self class] credentialsChangedNotificationName];
    [nc postNotificationName:notificationName object:self userInfo:userInfo];
}

#pragma mark Accessors

- (LogInViewController *)logInViewController
{
    if (!logInViewController) {
        logInViewController =
            [[LogInViewController alloc] initWithNibName:@"LogInView"
                                                  bundle:nil];
        logInViewController.delegate = self;
        logInViewController.lighthouseDomain = lighthouseDomain;
        logInViewController.lighthouseScheme = lighthouseScheme;
    }

    return logInViewController;
}

#pragma mark Notification names

+ (NSString *)credentialsChangedNotificationName
{
    return @"CredentialsChangedNotification";
}

@end
