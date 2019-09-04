//
//  UserLoadingRoutine.m
//  Tweepr
//

#import "UserLoadingRoutine.h"
#import "UserDetailsRoutine.h"
#import "NetworkManager.h"
#import "Utils.h"
#import "DataManager.h"
#import "Constants.h"

#import <SimpleAuth/SimpleAuth.h>

#import "TPRWebViewcontroller.h"
#import "TPRNavigationController.h"

#define kMultipleUsersAlertTag									123
#define kNoUsers                                                456


@interface UserLoadingRoutine () {
	
}

@property BOOL inProgress;

@property (strong, nonatomic) NSMutableArray *availableAccountsIdentifiers;
@property (strong, nonatomic) NSArray *availableUsers;

@property (copy, nonatomic) void (^requestBlock)(NSURL *url, NSString *oauthToken);

- (void)addNotifications;
- (void)getAccountsIdentifiersFromDevice;
- (void)createAndShowMultipleAccountsAlert;

- (BOOL)multiplePresentationMessageUsersAlertWasShown;
- (BOOL)lastUserSelectedIsStillAvailable; 
- (void)autoSelectUser;
- (void)createAndShowMultiplePresentationMessageUsersAlert;
- (void)setLastSelecteduserIdentifier:(NSString *)userIdentifier;
- (void)resetLastUserIdentifier;

@end

@implementation UserLoadingRoutine

@synthesize inProgress,availableAccountsIdentifiers;

+ (UserLoadingRoutine *)sharedRoutine {
	static UserLoadingRoutine *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[UserLoadingRoutine alloc] init];
	});
	return sharedInstance;
}

- (id)init {
	self = [super init];
	if (self) {
		self.availableAccountsIdentifiers = [[NSMutableArray alloc] init];
        self.availableUsers = [[NSUserDefaults standardUserDefaults] arrayForKey:@"availableUsers"] ?: [[NSArray alloc] init];
        self.userDict = [[NSDictionary alloc] init];
	}
	return self;
}

- (ACAccountStore *)accountStore {
    if (!self->_accountStore) {
        self->_accountStore = [[ACAccountStore alloc] init];
    }
    return self->_accountStore;
}
- (ACAccount *)account {
    
    return _account;
}

#pragma public

- (BOOL)hasCredentials {
    return self.lastSelectedUserIdentifier && self.account;
}

- (void)addUser:(NSDictionary *)userInfo
{
    NSMutableArray *usersArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"availableUsers"] mutableCopy] ?: [[NSMutableArray alloc] init];
    [usersArray addObject:userInfo];
    self.availableUsers = [usersArray copy];
    [[NSUserDefaults standardUserDefaults] setObject:usersArray forKey:@"availableUsers"];
}

- (void)startRoutineWithRequest:(void (^)(NSURL *url, NSString *oauthToken))requestBlock
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	if (self.inProgress)
    {
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Already in progress", self, __PRETTY_FUNCTION__);
		return;
	}
	[self stopRoutine];
	self.inProgress = YES;
	[self addNotifications];
    [self getAccountIdentifiers];
	//[self getAccountsIdentifiersFromDevice];
    [self getAvailableAccountsWithRequest:^(NSURL *url, NSString *oauthToken) {
        requestBlock(url, oauthToken);
    }];
	[Utils cancelAllRequests];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)stopRoutine
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	[[UserDetailsRoutine sharedRoutine] stop];
	self.inProgress = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma private

- (void)addNotifications {
	
}

- (void)getAccountIdentifiers {
    NSArray *availableUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"availableUsers"];
    if (availableUsers.count > 1 && ![self multiplePresentationMessageUsersAlertWasShown]) {
        [self createAndShowMultiplePresentationMessageUsersAlert];
    }
}

- (void)newUser2
{
    [SimpleAuth authorize:@"twitter-web" completion:^(id responseObject, NSError *error) {
        if (responseObject) {
            NSDictionary *credentials = responseObject[@"credentials"];
            NSDictionary *info = responseObject[@"info"];
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            
            dict[@"nickname"] = info[@"nickname"];
            dict[@"token"] = credentials[@"token"];
            dict[@"secret"] = credentials[@"secret"];
            dict[@"user_id"] = responseObject[@"uid"];
            self.userDict = dict;
            NSMutableArray *users = [self.availableUsers mutableCopy];
            if (![users containsObject:dict]) {
                [users addObject:dict];
            }
            self.availableUsers = [users copy];
            [[NSUserDefaults standardUserDefaults] setObject:self.availableUsers forKey:@"availableUsers"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self selectUserWithIdentifier:dict[@"nickname"]];
        }
    }];
}

- (void)newUser
{
    [[NetworkManager sharedInstance] resetTwitterAPI];
//    [[[NetworkManager sharedInstance] twitterAPI] postTokenRequest:^(NSURL *url, NSString *oauthToken) {
//        NSString *newURLString = [url absoluteString];
//        NSURL *newURL = [NSURL URLWithString:[newURLString stringByAppendingString:@"&force_login=TRUE"]];
//        [[UIApplication sharedApplication] openURL:newURL];
//        self.loginViewController.url = [newURL absoluteString];
//        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.loginViewController];
//        [self.callingViewController presentViewController:navigationController animated:YES completion:NULL];
//    } oauthCallback:@"tweepr://twitter_access_token" errorBlock:^(NSError *error) {
//        NSLog(@"Error %s", __PRETTY_FUNCTION__);
//    }];
    [[[NetworkManager sharedInstance] twitterAPI] postTokenRequest:^(NSURL *url, NSString *oauthToken) {
        self.requestBlock(url, oauthToken);
    } authenticateInsteadOfAuthorize:YES forceLogin:@YES screenName:nil oauthCallback:@"tweepr://twitter_access_token" errorBlock:^(NSError *error) {
        NSLog(@"Error %s", __PRETTY_FUNCTION__);
    }];
}

- (void)setOAuthToken:(NSString *)token verifier:(NSString *)verifier
{
    [[[NetworkManager sharedInstance] twitterAPI] postAccessTokenRequestWithPIN:verifier successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        dict[@"nickname"] = screenName;
        dict[@"token"] = oauthToken;
        dict[@"secret"] = oauthTokenSecret;
        dict[@"user_id"] = userID;
        self.userDict = dict;
        NSMutableArray *users = [self.availableUsers mutableCopy];
        if (![users containsObject:dict]) {
            [users addObject:dict];
        }
        self.availableUsers = [users copy];
        [[NSUserDefaults standardUserDefaults] setObject:self.availableUsers forKey:@"availableUsers"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self selectUserWithIdentifier:dict[@"nickname"]];
    } errorBlock:^(NSError *error) {
        NSLog(@"Error");
    }];
}

- (void)getAvailableAccounts
{
    if ([self.availableUsers count] == 0) {
        [self newUser];
    } else {
        if (![self lastSelectedUserIdentifier]) // first install
        {
            if ([self.availableUsers count] == 1)
            {
                [self selectUserWithIdentifier:[self.availableUsers firstObject][@"nickname"]];
            }
            else
            {
                [self createAndShowMultipleAccountsAlert];
            }
        }
        else // not first install
        {
            if ([self lastUserSelectedIsStillAvailable])
            {
                [self selectUserWithIdentifier:[self lastSelectedUserIdentifier]];
            }
            else
            {
                if ([self multiplePresentationMessageUsersAlertWasShown])
                {
                    [self autoSelectUser];
                }
                else
                {
                    if ([self.availableUsers count] > 1)
                    {
                        [self createAndShowMultiplePresentationMessageUsersAlert];
                    }
                    else
                    {
                        [self autoSelectUser];
                    }
                }
            }
        }

    }
}

- (void)getAccountsIdentifiersFromDevice {
	if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
		ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
		[self.accountStore requestAccessToAccountsWithType:accountType options:nil completion: ^(BOOL granted, NSError *error) {
             if (granted == YES) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                                    NSArray *arrayOfAccounts = [self.accountStore accountsWithAccountType:accountType];
                                    if ([arrayOfAccounts count] > 0)
                                    {
                                        [self.availableAccountsIdentifiers removeAllObjects];
                                        
                                        for (ACAccount *acount in arrayOfAccounts)
                                        {
                                            [self.availableAccountsIdentifiers addObject:[acount identifier]];
                                        }
                                        
                                        if (![self lastSelectedUserIdentifier]) // first install
                                        {
                                            if (self.availableAccountsIdentifiers.count == 1)
                                            {
                                                [self selectUserWithIdentifier:(self.availableAccountsIdentifiers)[0]];
                                            }
                                            else
                                            {
                                                [self createAndShowMultipleAccountsAlert];
                                            }
                                        }
                                        else // not first install
                                        {
                                            if ([self lastUserSelectedIsStillAvailable])
                                            {
                                                [self selectUserWithIdentifier:[self lastSelectedUserIdentifier]];
                                            }
                                            else
                                            {
                                                if ([self multiplePresentationMessageUsersAlertWasShown])
                                                {
                                                    [self autoSelectUser];
                                                }
                                                else
                                                {
                                                    if (self.availableAccountsIdentifiers.count > 1)
                                                    {
                                                        [self createAndShowMultiplePresentationMessageUsersAlert];
                                                    }
                                                    else
                                                    {
                                                        [self autoSelectUser];
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    else
                                    {
                                        [self forceTwitterSettingsAlert];
                                    }
                                });
             }
         }];
        
	} else {
		[self forceTwitterSettingsAlert];
    }
}

- (void)autoSelectUser {
	if ([self.availableUsers count] == 0) {
		//[self forceTwitterSettingsAlert];
	} else {
		[self selectUserWithIdentifier:[self.availableUsers firstObject][@"nickname"]];
	}
}

- (void)autoSelectUser2 {
	if (self.availableAccountsIdentifiers.count == 0) {
		[self forceTwitterSettingsAlert];
	} else {
		[self selectUserWithIdentifier:(self.availableAccountsIdentifiers)[0]];
	}
}

- (BOOL)lastUserSelectedIsStillAvailable {
	NSString *lastSelectedUser = [self lastSelectedUserIdentifier];
	for (NSDictionary *dict in self.availableUsers) {
        if ([dict[@"nickname"] isEqual:lastSelectedUser]) {
            return YES;
        }
    }
	return NO;
}

- (BOOL)lastUserSelectedIsStillAvailable2 {
	NSString *lastSelectedUser = [self lastSelectedUserIdentifier];
	if ([self.availableAccountsIdentifiers containsObject:lastSelectedUser]) {
		return YES;
	}
	return NO;
}

- (void)createAndShowMultipleAccountsAlert {
	UIAlertView *al = [[UIAlertView alloc] initWithTitle:nil
												 message:NSLocalizedString(@"Please select the twitter account you want to sign in with. You can use the app to manage multiple accounts from the profile screen", nil)
												delegate:self
									   cancelButtonTitle:nil
									   otherButtonTitles:nil];
	for (NSDictionary *dict in self.availableUsers) {
		[al addButtonWithTitle:[NSString stringWithFormat:@"@%@",dict[@"nickname"]]];
	}
	al.delegate = self;
	[al addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	[al setCancelButtonIndex:[self.availableUsers count]];
	[al show];
}

- (void)createAndShowMultipleAccountsAlert2 {
	UIAlertView *al = [[UIAlertView alloc] initWithTitle:nil
												 message:NSLocalizedString(@"Please select the twitter account you want to sign in with. You can use the app to manage multiple accounts from the profile screen", nil)
												delegate:self
									   cancelButtonTitle:nil
									   otherButtonTitles:nil];
	for (NSString *identif in self.availableAccountsIdentifiers) {
		ACAccount *acount = [self.accountStore accountWithIdentifier:identif];
		[al addButtonWithTitle:[NSString stringWithFormat:@"@%@",acount.username]];
	}
	al.delegate = self;
	[al addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	[al setCancelButtonIndex:self.availableAccountsIdentifiers.count];
	[al show];
}

- (NSDate *)initialLoadDateForCurrentUser {
    NSString *userId = self.lastSelectedUserIdentifier;
    if (!userId)
        return nil;
    NSString *key = [NSString stringWithFormat:@"%@_%@", applicationDidLoadData, userId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)setInitialLoadDateForCurrentUser:(NSDate *)date {
    NSString *userId = self.lastSelectedUserIdentifier;
    if (!userId)
        return;
    NSString *key = [NSString stringWithFormat:@"%@_%@", applicationDidLoadData, userId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:key];
    [defaults synchronize];
}


- (NSDate *)lastUpdateDateForCurrentUser {
    NSString *userId = self.lastSelectedUserIdentifier;
    if (!userId)
        return nil;
    NSString *key = [NSString stringWithFormat:@"last_update_%@", userId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)setLastUpdateDateForCurrentUser:(NSDate *)date {
    NSString *userId = self.lastSelectedUserIdentifier;
    if (!userId)
        return;
    NSString *key = [NSString stringWithFormat:@"last_update_%@", userId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:key];
    [defaults synchronize];
}

- (NSDate *)lastUnfollowTweetDateForCurrentUser {
    NSString *key = [NSString stringWithFormat:@"unfollow_tweet_%@", self.lastSelectedUserIdentifier];
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)setLastUnfollowTweetDateForCurrentUser:(NSDate *)date {
    NSString *key = [NSString stringWithFormat:@"unfollow_tweet_%@", self.lastSelectedUserIdentifier];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:key];
    [defaults synchronize];
}

- (NSDate *)lastTimelineUpdateForCurrentUser {
    NSString *key = [NSString stringWithFormat:@"timeline_update_%@", self.lastSelectedUserIdentifier];
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)setLastTimelineUpdateForCurrentUser:(NSDate *)date {
    NSString *key = [NSString stringWithFormat:@"timeline_update_%@", self.lastSelectedUserIdentifier];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:key];
    [defaults synchronize];
}

- (void)selectUserWithIdentifier:(NSString *)userIdentifier
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	[self setLastSelecteduserIdentifier:userIdentifier];
	[self stopRoutine];
	[[UserDetailsRoutine sharedRoutine] stop];
	[[UserDetailsRoutine sharedRoutine] start];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)forceTwitterSettingsAlert {
	[self resetLastUserIdentifier];
	
    SLComposeViewController *viewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
	viewController.view.hidden = YES;
	viewController.completionHandler = ^(TWTweetComposeViewControllerResult result) {
		if (result == TWTweetComposeViewControllerResultCancelled) {
            [self.callingViewController dismissViewControllerAnimated:YES completion:NULL];
		}
	};
    [self.callingViewController presentViewController:viewController animated:NO completion:NULL];
	[viewController.view endEditing:YES];
}

- (NSString *)lastSelectedUserIdentifier {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"lastSelectedUseridentifier"]) {
    }
	return [defaults objectForKey:@"lastSelectedUseridentifier"];
}

- (void)setLastSelecteduserIdentifier:(NSString *)userIdentifier
{
	if (![[self lastSelectedUserIdentifier] isEqualToString:userIdentifier])
    {
    // reload unfollow manager
    }
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (userIdentifier && userIdentifier.length > 0) {
		[defaults setObject:userIdentifier forKey:@"lastSelectedUseridentifier"];
	}
	[defaults synchronize];
    for (NSDictionary *dict in self.availableUsers) {
        if ([dict[@"nickname"] isEqual:userIdentifier]) {
            self.userDict = dict;
            [[NetworkManager sharedInstance] startWithUserDict:dict];
            return;
        }
    }
    
}

- (BOOL)didFollowTweeprForCurrentUser {
    NSString *key = [NSString stringWithFormat:@"followed_%@", self.lastSelectedUserIdentifier];
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

- (void)setDidFollowTweeprForCurrentUser:(BOOL)value {
    NSString *key = [NSString stringWithFormat:@"followed_%@", self.lastSelectedUserIdentifier];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

- (BOOL)multiplePresentationMessageUsersAlertWasShown {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:@"multiplePresentationMessageUsersAlertWasShown"];
}

- (void)setMultiplePresentationMessageUsersAlertWasShown {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:YES forKey:@"multiplePresentationMessageUsersAlertWasShown"];
	[defaults synchronize];
}

- (void)createAndShowMultiplePresentationMessageUsersAlert {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
													message:NSLocalizedString(@"Did you know you can manage multiple twitter accounts? Simply access the \"Accounts\" option on the profile screen!", nil)
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
										  otherButtonTitles:nil];
	alert.tag = kMultipleUsersAlertTag;
	alert.delegate = self;
	[alert show];
	[self setMultiplePresentationMessageUsersAlertWasShown];
}

- (void)resetLastUserIdentifier {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:@"lastSelectedUseridentifier"];
	[defaults synchronize];
}

- (BOOL)notificationsEnabled {
    NSNumber *enabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"tweetNotificationsEnabled"];
    if (!enabled)
        return YES;
    return enabled.boolValue;
}

- (void)setNotificationsEnabled:(BOOL)notificationsEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:notificationsEnabled forKey:@"tweetNotificationsEnabled"];
    [defaults synchronize];
}

#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == kMultipleUsersAlertTag) {
		[self autoSelectUser];
		return;
	}
	if (buttonIndex < self.availableAccountsIdentifiers.count) {
		NSString *selectedUserIdentifier = (self.availableAccountsIdentifiers)[buttonIndex];
		[self selectUserWithIdentifier:selectedUserIdentifier];
	} else {
		[self resetLastUserIdentifier];
	}
}

@end
