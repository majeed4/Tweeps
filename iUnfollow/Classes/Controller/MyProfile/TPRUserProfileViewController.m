//
//  TPRUserProfileViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 06/07/2013.
//
//

#import "TPRUserProfileViewController.h"
#import "TPRTableCell.h"
#import "TPRWebViewController.h"
#import "TPRNavigationController.h"

#import "TPRRecentFollowersViewController.h"
#import "TPRRecentUnfollowersViewController.h"
#import "TPRBlockedViewController.h"
#import "TPRAppDelegate.h"

#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>

@interface TPRUserProfileViewController ()<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, TPRWebViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong, readonly) User *user;
@property (nonatomic, assign) NSInteger unfollowingCount, followersCount, blockedCount;
@property (nonatomic, strong) NSMutableArray *accountIdentifiers;
@property (nonatomic, strong) IBOutlet UIImageView *profileBackgroundView, *avatarImageView, *backgroundImageView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel, *handleLabel, *websiteLabel, *descriptionLabel;
@property (nonatomic, strong) IBOutlet UILabel *numTweetsLabel, *numFollowersLabel, *numFollowingLabel;

@property (nonatomic, strong) TPRWebViewController *loginViewController;

- (IBAction)showTwitterAccounts;

@end

@implementation TPRUserProfileViewController

static NSString *cellIdentifier = @"TPRUserProfileCellIdentifier";

-(void)awakeFromNib
{
    self.title = NSLocalizedString(@"My profile", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [UserLoadingRoutine sharedRoutine].callingViewController = self;
	[[UserLoadingRoutine sharedRoutine] startRoutineWithRequest:^(NSURL *url, NSString *oathToken) {
        self.loginViewController.url = [url absoluteString];
        self.loginViewController.pageTitle = @"Twitter Login";
        TPRNavigationController *navigationController = [[TPRNavigationController alloc]initWithRootViewController:self.loginViewController];
        [self presentViewController:navigationController animated:YES completion:NULL];
    }];
    [self updateProfileView];
    
    if (![Utils isIphoneFive]) {
        
        UIScrollView *sv = (UIScrollView *)self.view;
        sv.scrollEnabled = YES;
        sv.bounces = YES;
        sv.contentSize = CGSizeMake(320, CGRectGetMaxY(self.tableView.frame) + 40);
        sv.contentOffset = CGPointMake(0, 88);
        
        CGRect frame = self.tableView.frame;
        frame.size.height = 300;
        self.tableView.frame = frame;
    
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDetailsFinish) name:userDetailsFinished object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:didFetchUserDetailsNotifcation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:didUpdateFrienshipStatusNotification object:nil];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:userDetailsFinished object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didFetchUserDetailsNotifcation object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didUpdateFrienshipStatusNotification object:nil];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (User *)user {
    DataManager *dataManager = [DataManager sharedInstance];
    User *user = [dataManager getUserInfoInContext:[dataManager mainThreadContext]];
    return user;
}

- (void)reloadData {
    DataManager *dataManager = [DataManager sharedInstance];
    self.followersCount = [dataManager countForFollowers:YES];
    self.unfollowingCount = [dataManager countForFollowers:NO];
    self.blockedCount = [dataManager countForBlocked];    
    [self.tableView reloadData];
}

- (void)userDetailsFinish {
    [self updateProfileView];
    [self reloadData];
}

- (void)updateProfileView {
    User *user = self.user;
    NSURL *backgroundURL = [NSURL URLWithString:user.profileBackgroundUrl];
    if (backgroundURL) {
        __weak typeof(self) wself = self;
        
        [self.profileBackgroundView sd_setImageWithURL:backgroundURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (cacheType == SDImageCacheTypeNone) {
                wself.profileBackgroundView.alpha = 0.0;
                [UIView animateWithDuration:0.4 animations:^{
                    wself.profileBackgroundView.alpha = 1.0;
                }];
            }
            wself.backgroundImageView.image = [image applyLightEffect];
        }];
//        [self.profileBackgroundView setImageWithURL:backgroundURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//            if (cacheType == SDImageCacheTypeNone) {
//                wself.profileBackgroundView.alpha = 0.0;
//                [UIView animateWithDuration:0.4 animations:^{
//                    wself.profileBackgroundView.alpha = 1.0;
//                }];
//            }
//            wself.backgroundImageView.image = [image applyLightEffect];
//        }];
    } else {
        self.profileBackgroundView.image = [UIImage imageNamed:@"grey_header"];
        self.backgroundImageView.image = [self.profileBackgroundView.image applyLightEffect];
    }
    
    NSURL *avatarURL = [NSURL URLWithString:user.profileImageUrl];
    [self.avatarImageView TPRSetImageWithURL:avatarURL];
    
    
    

    self.nameLabel.text = user.fullName;
    if (user.userName)
        self.handleLabel.text = [NSString stringWithFormat:@"@%@", user.userName];
    self.websiteLabel.text = user.userPageUrl.length ? user.userPageUrl : NSLocalizedString(@"No website", nil);
    self.descriptionLabel.text = user.biography;
    
    self.numTweetsLabel.text = user.tweetsNo.stringValue;
    self.numFollowersLabel.text = user.followersNo.stringValue;
    self.numFollowingLabel.text = user.followingNo.stringValue;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (void)showUserWebsite {
    User *user = self.user;
	if (user.userPageUrl) {
		TPRWebViewController *wvc = [[TPRWebViewController alloc] init];
		wvc.url = user.userPageUrl;
        wvc.pageTitle = user.userName;
		UINavigationController *wnc = [[UINavigationController alloc] initWithRootViewController:wvc];
		[self.navigationController presentViewController:wnc animated:YES completion:NULL];
	}
}

- (void)showUnfollowersAnimated:(BOOL)isAnimated {
    TPRRecentUnfollowersViewController *nextViewController = [[TPRRecentUnfollowersViewController alloc] init];
    [[self navigationController] pushViewController:nextViewController animated:isAnimated];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    if (buttonIndex != actionSheet.cancelButtonIndex && buttonIndex != actionSheet.cancelButtonIndex - 1) {
        NSArray *availableUsers = [[NSUserDefaults standardUserDefaults] arrayForKey:@"availableUsers"];
		NSString *newIdentifier = availableUsers[buttonIndex][@"nickname"];
		if (![newIdentifier isEqualToString:[[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier]]) {
			[[UserLoadingRoutine sharedRoutine] selectUserWithIdentifier:newIdentifier];
            [self.tableView reloadData];
		}
	} else if (buttonIndex == actionSheet.cancelButtonIndex - 1) {
        [[UserLoadingRoutine sharedRoutine] newUserWithRequest:^(NSURL *url, NSString *oauthToken) {
            self.loginViewController.url = [url absoluteString];
            self.loginViewController.pageTitle = @"Twitter Login";
            TPRNavigationController *navigationController = [[TPRNavigationController alloc]initWithRootViewController:self.loginViewController];
            [self presentViewController:navigationController animated:YES completion:NULL];
        }];
    }
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58 + 8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TPRTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];;
    NSString *title;
    NSInteger number;
    if (indexPath.row == 0) {
        cell.imageView.image = [UIImage imageNamed:@"cell_plus"];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_blue"]];
        title = NSLocalizedString(@"Recently Following", nil);
        number = self.followersCount;
    } else if (indexPath.row == 1) {
        cell.imageView.image = [UIImage imageNamed:@"cell_minus"];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_orange"]];
        title = NSLocalizedString(@"Recently Unfollowing", nil);
        number = self.unfollowingCount;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"cell_cross"];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_red"]];
        title = NSLocalizedString(@"Blocked by you", nil);
        number = self.blockedCount;
    }

    cell.textLabel.text = title;
    cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)number];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *nextViewController = nil;
    if (indexPath.row == 0) {
        nextViewController = [[TPRRecentFollowersViewController alloc] init];
    } else if (indexPath.row == 1) {
        [self showUnfollowersAnimated:YES];
    } else {
        nextViewController = [[TPRBlockedViewController alloc] init];
    }
    if (nextViewController != nil)
        [self.navigationController pushViewController:nextViewController animated:YES];
}


#pragma mark - IBActions

- (IBAction)showTwitterAccounts
{
    self.accountIdentifiers = [[NSMutableArray alloc] init];
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose an account", nil)
                                                    delegate:self
                                           cancelButtonTitle:nil
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:nil];
    NSArray *availableUsers = [[NSUserDefaults standardUserDefaults] arrayForKey:@"availableUsers"];
    for (NSDictionary *dict in availableUsers)
    {
        [self.accountIdentifiers addObject:dict[@"nickname"]];
        [as addButtonWithTitle:[NSString stringWithFormat:@"@%@",dict[@"nickname"]]];
    }
    [as addButtonWithTitle:NSLocalizedString(@"Add New User", nil)];
    [as addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    as.cancelButtonIndex = self.accountIdentifiers.count + 1;
    as.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    NSLog(@"self.acccountIdentifier.count: %lu", self.accountIdentifiers.count);
    if (self.accountIdentifiers.count > 0) {
        //[as showInView:self.view];
        [as showFromTabBar:self.tabBarController.tabBar];
    } else {
        [UserLoadingRoutine sharedRoutine].callingViewController = self;
        [[UserLoadingRoutine sharedRoutine] newUserWithRequest:^(NSURL *url, NSString *oauthToken) {
            self.loginViewController.url = [url absoluteString];
            self.loginViewController.pageTitle = @"Twitter Login";
            TPRNavigationController *navigationController = [[TPRNavigationController alloc]initWithRootViewController:self.loginViewController];
            [self presentViewController:navigationController animated:YES completion:NULL];
        }];
    }

}

- (IBAction)showTwitterAccounts2 {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        ACAccountStore *accountStore = [UserLoadingRoutine sharedRoutine].accountStore;
		ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
            if (granted == YES) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSArray* arrayOfAccounts = [accountStore accountsWithAccountType:accountType];
					if ([arrayOfAccounts count] > 0) {
                        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose an account", nil)
                                                                        delegate:self
                                                               cancelButtonTitle:nil
                                                          destructiveButtonTitle:nil
                                                               otherButtonTitles:nil];
                        self.accountIdentifiers = [NSMutableArray array];
                        for (ACAccount *account in arrayOfAccounts)
                        {
                            [self.accountIdentifiers addObject:[account identifier]];
                            [as addButtonWithTitle:[NSString stringWithFormat:@"@%@",[account username]]];
                        }
                        [as addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                        as.cancelButtonIndex = self.accountIdentifiers.count;
                        as.actionSheetStyle = UIActionSheetStyleBlackOpaque;
                        if (self.accountIdentifiers.count > 0) {
                            //[as showInView:self.view];
                            [as showFromTabBar:self.tabBarController.tabBar];
                        }
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UserLoadingRoutine sharedRoutine] forceTwitterSettingsAlert];
                    NSLog(@"%@", error);
                });
            }
        }];
	} else {
		[[UserLoadingRoutine sharedRoutine] forceTwitterSettingsAlert];
	}
}

- (void)didCloseWebViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
