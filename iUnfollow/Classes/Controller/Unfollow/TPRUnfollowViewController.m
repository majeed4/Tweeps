//
//  TPRUnfollowViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

#import "TPRUnfollowViewController.h"
#import "TPRTableCell.h"
#import "TPRAppDelegate.h"

#import "TPRFollowingViewController.h"
#import "TPRNonFollowersViewController.h"
#import "TPRFansViewController.h"
#import "TPRInactiveViewController.h"
#import "TPRFriendsViewController.h"
#import "TPREggsViewController.h"

@interface TPRUnfollowViewController ()

@property (nonatomic, strong) TPRUsersViewController *followingVC, *nonFollowersVC, *fansVC, *friendsVC, *inactiveVC, *eggsVC;
@property (nonatomic, assign) NSInteger followingCount, nonFollowersCount, friendsCount, fansCount, inactiveCount, eggsCount;

@end

@implementation TPRUnfollowViewController


-(void)awakeFromNib
{
	self.title = NSLocalizedString(@"Unfollow", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDataNeedsReload) name:didUpdateFrienshipStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDataNeedsReload) name:didFetchUserDetailsNotifcation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDataNeedsReload) name:unfollowUsersFinished object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDataNeedsReload) name:deleteUsersFinished object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDataNeedsReload) name:didSwitchAccountNotification object:nil];

    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier) {
        [Utils showPrevUserChangedAlert];
        return;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:didUpdateFrienshipStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didFetchUserDetailsNotifcation object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:unfollowUsersFinished object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:deleteUsersFinished object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didSwitchAccountNotification object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (TPRUsersViewController *)followingVC {
    if (!_followingVC) {
        _followingVC = [[TPRFollowingViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _followingVC;
}

- (TPRUsersViewController *)nonFollowersVC {
    if (!_nonFollowersVC) {
        _nonFollowersVC = [[TPRNonFollowersViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _nonFollowersVC;
}

- (TPRUsersViewController *)fansVC {
    if (!_fansVC) {
        _fansVC = [[TPRFansViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _fansVC;
}

- (TPRUsersViewController *)inactiveVC {
    if (!_inactiveVC) {
        _inactiveVC = [[TPRInactiveViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _inactiveVC;
}

- (TPRUsersViewController *)friendsVC {
    if (!_friendsVC) {
        _friendsVC = [[TPRFriendsViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _friendsVC;
}

- (TPRUsersViewController *)eggsVC {
    if (!_eggsVC) {
        _eggsVC = [[TPREggsViewController alloc] initWithNibName:nil bundle:nil];
    }
    return _eggsVC;
}

- (void)setDataNeedsReload {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];
	[self performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
}

- (void)reloadData {
    DataManager *dataManager = [DataManager sharedInstance];
    
    self.followingCount = [dataManager countForFollowing];
    self.nonFollowersCount = [dataManager countForNonFollowers];
    self.friendsCount = [dataManager countForFriends];
    self.fansCount = [dataManager countForFans];
    self.inactiveCount = [dataManager countForInactive];
    self.eggsCount = [dataManager countForEggs];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58 + 8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 6;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"unfollowTableCellIdentifier";
    TPRTableCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    NSInteger count = 0;
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Following", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Users who you follow", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_blue"]];
        count = self.followingCount;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"Non-Followers", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Users who don't follow you back", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_orange"]];
        count = self.nonFollowersCount;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"Friends", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Users you follow and they follow back", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_red"]];
        count = self.friendsCount;
    } else if (indexPath.row == 3) {
        cell.textLabel.text = NSLocalizedString(@"Fans", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Users who follow you but you don't follow them", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_turq"]];
        count = self.fansCount;
    } else if (indexPath.row == 4) {
        cell.textLabel.text = NSLocalizedString(@"Inactive", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Following who haven't tweeted for 20 days", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_violet"]];
        count = self.inactiveCount;
    } else if (indexPath.row == 5) {
        cell.textLabel.text = NSLocalizedString(@"Eggs", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"No profile image", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_green"]];
        count = self.eggsCount;
    }
    cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (![UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier) {
        [Utils showPrevUserChangedAlert];
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return;
    }
    
    TPRUsersViewController *nextViewController = nil;
    if (indexPath.row == 0)
    {
        nextViewController = self.followingVC;
    }
    else if (indexPath.row == 1)
    {
        nextViewController = self.nonFollowersVC;
    }
    else if (indexPath.row == 2)
    {
        nextViewController = self.friendsVC;
    }
    else if (indexPath.row == 3)
    {
        nextViewController = self.fansVC;
    }
    else if (indexPath.row == 4)
    {
        nextViewController = self.inactiveVC;
    }
    else
    {
        nextViewController = self.eggsVC;
    }
    
    [self.navigationController pushViewController:nextViewController animated:YES];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}


#pragma mark - IBActions


@end
