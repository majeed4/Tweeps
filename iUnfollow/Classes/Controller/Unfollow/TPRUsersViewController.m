//
//  TPRUsersViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

#import "TPRUsersViewController.h"
#import "TPRProfileViewController.h"
#import "TPRUsersTableCell.h"
#import "TPRAppDelegate.h"

@interface TPRUsersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIBarButtonItem *selectAllButton;
@property (nonatomic, strong) UIBarButtonItem *deselectAllButton;
@property (nonatomic, strong) UIView *unfollowView;
@property (nonatomic, strong) UILabel *emptyLabel;

@property (nonatomic, assign) BOOL hasSelectedUsers;

@end

@implementation TPRUsersViewController

static NSString *cellIdentifier = @"TPRUsersTableViewCell";

#pragma mark - View lifecycle

typedef NS_ENUM(NSInteger, TPRAlertViewType) {
    TPRAlertViewTypeUnblock = 0x1111,
    TPRAlertViewTypeUnfollow = 0x2222
};

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor TPRBackgroundColor];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, CGRectGetHeight(self.view.bounds) - 50 - 44)];
    self.tableView = tableView;
    tableView.delegate = self;
    tableView.dataSource = self;
    
    
    [tableView registerClass:[TPRUsersTableCell class] forCellReuseIdentifier:cellIdentifier];
    
    [self.view addSubview:tableView];
    
    tableView.backgroundColor = [UIColor TPRBackgroundColor];
    tableView.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"section-divider"]];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    if (self.unfollowEnabled || self.unblockEnabled) {
        UIView *unfollowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        UIImageView *separatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_wide"]];
        separatorView.frame = CGRectMake(0, 43, 320, 1);
        [unfollowView addSubview:separatorView];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
        
        if (self.unfollowEnabled)
        {
            NSString *title = [NSString stringWithFormat:@"> %@ <", NSLocalizedString(@"Unfollow selected", nil)];
            [button setTitle:title forState:UIControlStateNormal];
            [button addTarget:self action:@selector(unfollowPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        else if (self.unblockEnabled)
        {
            NSString *title = [NSString stringWithFormat:@"> %@ <", NSLocalizedString(@"Unblock selected", nil)];
            [button setTitle:title forState:UIControlStateNormal];
            [button addTarget:self action:@selector(unblockPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        button.center = unfollowView.center;
        button.titleLabel.font = [UIFont TPRFontWithSize:14];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [unfollowView addSubview:button];
        [self.view addSubview:unfollowView];
        self.unfollowView = unfollowView;
        unfollowView.transform = CGAffineTransformMakeTranslation(0, -44);
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 40)];
    self.emptyLabel = label;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont TPRFontWithSize:18];
    label.text = NSLocalizedString(@"There is currently no history to show.", nil);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.alpha = 0.0;

    [self.view addSubview:label];
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = NSLocalizedString(@"Unfollow", nil);
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:nil tag:1];
    [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tab-unfollow-selected"] withFinishedUnselectedImage:[UIImage imageNamed:@"tab-unfollow"]];
    [self.tabBarItem setImageInsets:UIEdgeInsetsMake(2, 0, 0, 0)];
    
    if (self.unfollowEnabled || self.unblockEnabled) {
        self.selectAllButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select 100", nil)
                                                                style:UIBarButtonItemStyleBordered
                                                               target:self
                                                               action:@selector(selectAllPressed:)];
        self.deselectAllButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Deselect all", nil)
                                                                  style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(deselectAllPressed:)];
        [self.navigationItem setRightBarButtonItem:self.selectAllButton animated:NO];
        [self updateUnfollowButton];
    }
    
    [self reloadDataSource];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(reloadDataSource)
                               name:didUpdateFrienshipStatusNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(reloadData)
                               name:didFetchUserDetailsNotifcation
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(reloadDataSource)
                               name:didSwitchAccountNotification
                             object:nil];
	[notificationCenter addObserver:self
                           selector:@selector(unfollowUserFinish)
                               name:unfollowUsersFinished
                             object:nil];
	[notificationCenter addObserver:self
                           selector:@selector(deleteUsersFinish:)
                               name:deleteUsersFinished
                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
    
    if (!self.hasSelectedUsers) {
        self.tableView.frame = self.view.bounds;
    }

//	if (![UserLoadingRoutine sharedRoutine].hasCredentials) {
//		[Utils showPrevUserChangedAlert];
//        self.items = nil;
//		[self.tableView reloadData];
//		return;
//	}

	if (![UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier) {
		[Utils showPrevUserChangedAlert];
        self.items = nil;
		[self.tableView reloadData];
		return;
	}
    
    
	[self reloadDataSource];
}

- (void)updateDataSource {
    NSMutableArray *identifiers = [NSMutableArray array];
    
    for (TwitterUser *user in self.items)
    {
        if (!user.hasDetails && identifiers.count < 100)
        {
            [identifiers addObject:user.identifier];
        }
    }
    
    if ([identifiers count] > 0)
    {
        [[NetworkManager sharedInstance] fetchDetailsForUserIds:identifiers];
    }

    BOOL isEmpty = ([self.items count] == 0);

    self.emptyLabel.alpha = (isEmpty) ? 1.0 : 0.0;
}

- (void)reloadData {
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	[super viewWillDisappear:animated];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:didUpdateFrienshipStatusNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:didFetchUserDetailsNotifcation
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:didSwitchAccountNotification
                                object:nil];
	[notificationCenter removeObserver:self
                                  name:unfollowUsersFinished
                                object:nil];
	[notificationCenter removeObserver:self
                                  name:deleteUsersFinished
                                object:nil];
//	[notificationCenter removeObserver:self
//                                  name:@"gotTwitterUsersWithDetails"
//                                object:nil];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - private

- (BOOL)allUsersAreSelected
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    BOOL result = YES;
    self.hasSelectedUsers = NO;
    for (TwitterUser *user in self.items)
    {
        if (!user.selected.boolValue)
        {
            result = NO;
        }
        else
        {
            self.hasSelectedUsers = YES;
        }
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return result;
}

- (void)updateUnfollowButton
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    if (!self.unfollowEnabled && !self.unblockEnabled)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - Unfollow and unblock are not enabled", self, __PRETTY_FUNCTION__);
        return;
	}
    
    if ([self allUsersAreSelected])
    {
        [self.navigationItem setRightBarButtonItem:self.deselectAllButton animated:YES];
    }
	else
    {
        [self.navigationItem setRightBarButtonItem:self.selectAllButton animated:YES];
    }

    if (self.hasSelectedUsers)
    {
        [UIView animateWithDuration:0.3 animations:^{
            self.unfollowView.transform = CGAffineTransformIdentity;
            self.tableView.frame = CGRectMake(0, 44, 320, CGRectGetHeight(self.view.bounds) - 44);
		}];
    }
    else
    {
        [UIView animateWithDuration:0.3 animations:^{
            self.unfollowView.transform = CGAffineTransformMakeTranslation(0, -44);
            self.tableView.frame = CGRectMake(0, 0, 320, CGRectGetHeight(self.view.bounds));
		}];
    }    

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)reloadDataSource
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [self updateDataSource];
    [self updateUnfollowButton];
    
    [self.tableView reloadData];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)unfollowUsers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	NSMutableArray *selectedUsers = [NSMutableArray array];
    
    for (TwitterUser *user in self.items)
    {
        if (user.selected.boolValue)
        {
            [selectedUsers addObject:user];
        }
    }
    
    if (selectedUsers.count > 0) {
        [self.tableView beginUpdates];
        [[NetworkManager sharedInstance] unfollowUsersWithIds:selectedUsers];
    }
	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)unblockUsers
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSMutableArray *selectedUsers = [NSMutableArray array];
    
    for (TwitterUser *user in self.items)
    {
        if (user.selected.boolValue)
        {
            [selectedUsers addObject:user];
        }
    }
    
    if (selectedUsers.count > 0) {
        [self.tableView beginUpdates];
        [[NetworkManager sharedInstance] unblockUsersWithIds:selectedUsers];
    }
	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - notifications

- (void)unfollowUserFinish
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [self.tableView endUpdates];
	[self reloadDataSource];
	[self updateUnfollowButton];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)deleteUsersFinish:(NSNotification *)notification
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);
    [self.tableView endUpdates];
	[self reloadDataSource];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - table view delegate and data source

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"%@", self.items);
    return self.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 83;
}

- (UITableViewCell *)tableView:(UITableView *)tableVieww cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TPRUsersTableCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    TwitterUser *user = (self.items)[indexPath.row];
    cell.loaded = user.hasDetails;
    cell.showRetweetCount = NO;
    cell.showDisclosureIndicator = YES;
    
    __weak TPRUsersTableCell *weakCell = cell;
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.profileImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        weakCell.imageView.image = [UIImage tpr_maskedImageWithImage:image];
        if (cacheType == SDImageCacheTypeNone)
        {
            weakCell.imageView.alpha = 0.0;
            [UIView animateWithDuration:0.5
                             animations:^{
                                 
                                 weakCell.imageView.alpha = 1.0;
                                 
                             }];
        }
        [weakCell setNeedsLayout];
    }];
//	[cell.imageView setImageWithURL:[NSURL URLWithString:user.profileImageUrl]
//                          completed:
//     ^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//         weakCell.imageView.image = [UIImage tpr_maskedImageWithImage:image];
//         if (cacheType == SDImageCacheTypeNone)
//         {
//             weakCell.imageView.alpha = 0.0;
//             [UIView animateWithDuration:0.5
//                              animations:^{
//                                  
//                 weakCell.imageView.alpha = 1.0;
//                                  
//             }];
//         }
//         [weakCell setNeedsLayout];
//
//    }];
    
    if (self.unfollowEnabled || self.unblockEnabled)
    {
        cell.showCheckbox = YES;
        cell.checkBox.tag = indexPath.row;
        NSString *imageName = user.selected.boolValue ? @"unf_checked_btn" : @"unf_unchecked_btn";
        [cell.checkBox setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [cell.checkBox removeTarget:self action:@selector(checkButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.checkBox addTarget:self action:@selector(checkButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        cell.showCheckbox = NO;
    }
    
    cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", user.screenName];
    cell.nameLabel.text = user.fullName;
    
    NSString *followingStr = [Utils numberToKStringNotation:@(user.numFollowing)];
    NSString *followersStr = [Utils numberToKStringNotation:@(user.numFollowers)];
    cell.followingLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Following", nil), followingStr];
    cell.followersLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Followers", nil), followersStr];
    
	return cell;
}

#pragma mark - actions


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TwitterUser *user = (self.items)[indexPath.row];
    if (!user.hasDetails)
	{
		BTITrackingLog(@"<<< Leaving  <%p> %s >>> EARLY - <reason not specified>", self, __PRETTY_FUNCTION__);
        return;
	}
    
    
    TPRAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    TPRProfileViewController *vc = [delegate.storyboard instantiateViewControllerWithIdentifier:@"TPRProfileViewController"];
    vc.user = user;
    [self.navigationController pushViewController:vc animated:YES];
//
	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)checkButtonPressed:(UIButton *)sender
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSInteger index = sender.tag;
	TwitterUser *user = (self.items)[index];
	if ([user.selected boolValue])
    {
		user.selected = @NO;
		for (TwitterUser *user in self.items)
        {
			if ([user.selected boolValue])
            {
				break;
			}
		}
	}
    else
    {
		user.selected = @YES;
	}
	[self updateUnfollowButton];
	
	[[DataManager sharedInstance] saveMainThreadContext];
    
	[self.tableView reloadData];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (IBAction)deselectAllPressed:(id)sender {
//    [Flurry logEvent:@"Unfollow screen - deselectAll button pressed"];
//	if (![UserLoadingRoutine sharedRoutine].hasCredentials) {
//		[Utils showPrevUserChangedAlert];
//		return;
//	}

    if (![UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier) {
		[Utils showPrevUserChangedAlert];
		return;
	}

    
    for (TwitterUser *user in self.items) {
        user.selected = @NO;
    }
    
	[self updateUnfollowButton];
    
	[self.tableView reloadData];
	
	[[DataManager sharedInstance] saveMainThreadContext];
}

- (IBAction)selectAllPressed:(id)sender {
//    [Flurry logEvent:@"Unfollow screen - selectAll button pressed"];
	
//	if (![UserLoadingRoutine sharedRoutine].hasCredentials) {
//		[Utils showPrevUserChangedAlert];
//		return;
//	}

    if (![UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier) {
		[Utils showPrevUserChangedAlert];
		return;
	}

    
    for (TwitterUser *user in self.items) {
        user.selected = @YES;
    }
    
	[self updateUnfollowButton];
    
	[self.tableView reloadData];
	
	[[DataManager sharedInstance] saveMainThreadContext];
}

- (IBAction)unfollowPressed:(id)sender {
    
    BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    if (![Utils tweeprProEnabled]) {
        [Utils showTweeprProAlert];
        return;
    }

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"shouldShowConfirmationAlert"]) {
		[self unfollowUsers];
	}
    else
    {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to unfollow those users?", nil)
														message:@""
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  otherButtonTitles:NSLocalizedString(@"Unfollow", nil),NSLocalizedString(@"Don't ask me again", nil), nil];
        alert.tag = TPRAlertViewTypeUnfollow;
        [alert show];
	}

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)unblockPressed:(id)sender
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    if (![Utils tweeprProEnabled]) {
        [Utils showTweeprProAlert];
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"shouldShowConfirmationAlert"])
    {
		[self unblockUsers];
	}
    else
    {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to unblock those users?", nil)
														message:@""
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
											  otherButtonTitles:NSLocalizedString(@"Unblock", nil),NSLocalizedString(@"Don't ask me again", nil), nil];
        alert.tag = TPRAlertViewTypeUnblock;
        [alert show];
	}

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - alert View Delegate

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    if (alertView.tag == TPRAlertViewTypeUnblock)
    {
        if (buttonIndex == 1)
        {
            [self unblockUsers];
        }
        else if (buttonIndex == 2)
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shouldShowConfirmationAlert"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self unblockUsers];
        }
    }
    else if (alertView.tag == TPRAlertViewTypeUnfollow)
    {
        if (buttonIndex == 1)
        {
            [self unfollowUsers];
        }
        else if (buttonIndex == 2)
        {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shouldShowConfirmationAlert"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self unfollowUsers];
        }
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}


@end
