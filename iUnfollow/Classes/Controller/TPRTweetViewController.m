//
//  TPRTweetViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 11/05/2013.
//
//

#import "TPRTweetViewController.h"
#import "TPRTableCell.h"
#import "TPRAppDelegate.h"
#import "TPRRetweetersViewController.h"
#import "TPRRetweetsViewController.h"
#import "TPRImagesViewController.h"
#import "TPRVideosViewController.h"
#import "TPRRetweetedViewController.h"
#import "TPRMentionedViewController.h"
#import "TPRMentioningViewController.h"
#import "NetworkManager.h"

@interface TPRTweetViewController ()

@property (nonatomic, assign) NSInteger retweetsCount;
@property (nonatomic, assign) NSInteger retweetersCount;
@property (nonatomic, assign) NSInteger retweetedCount;@property (nonatomic, assign) NSInteger videosCount;
@property (nonatomic, assign) NSInteger imagesCount;
@property (nonatomic, assign) NSInteger mentionsCount;
@property (nonatomic, assign) NSInteger mentioningCount;

@end

@implementation TPRTweetViewController

static NSString *cellIdentifier = @"tweetTableCellIdentifier";

-(void)awakeFromNib
{
    self.title = NSLocalizedString(@"Tweet", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didFetchUserTweetsNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didUpdateFrienshipStatusNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didFetchUserDetailsNotifcation object:nil];
	[notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:deleteUsersFinished object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didSwitchAccountNotification object:nil];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [[NetworkManager sharedInstance] updateUserTweetsWithCompletionHandler:nil];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:didFetchUserTweetsNotification object:nil];
    [notificationCenter removeObserver:self name:didUpdateFrienshipStatusNotification object:nil];
    [notificationCenter removeObserver:self name:didFetchUserDetailsNotifcation object:nil];
	[notificationCenter removeObserver:self name:deleteUsersFinished object:nil];
    [notificationCenter removeObserver:self name:didSwitchAccountNotification object:nil];
}

- (void)reloadData {
    DataManager *dataManager = [DataManager sharedInstance];

    self.retweetsCount = [dataManager countForRetweets];
    self.retweetersCount = [dataManager countForRetweeters];
    self.retweetedCount = [dataManager countForRetweeted];
    self.videosCount = [dataManager countForVideos];
    self.imagesCount = [dataManager countForImages];
    self.mentionsCount = [dataManager countForMentions];
    self.mentioningCount = [dataManager countForMentioning];

    [self.tableView reloadData];
}

- (void)setDataNeedsReload {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];
	[self performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 58 + 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 6;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TPRTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];;
    NSInteger row = [indexPath row];
    NSInteger count = 0;
    if (row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Top retweets", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Most retweeted tweets", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_blue"]];
        count = self.retweetsCount;
    } else if (row == 1) {
        cell.textLabel.text = NSLocalizedString(@"Top retweeters", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"People retweeting you the most", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_orange"]];
        count = self.retweetersCount;
    } else if (row == 2) {
        cell.textLabel.text = NSLocalizedString(@"Retweeted by you", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"People you retweet the most", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_red"]];
        count = self.retweetedCount;
    } else if (row == 3) {
        cell.textLabel.text = NSLocalizedString(@"Top mentioned", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"People you mention the most", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_turq"]];
        count = self.mentionsCount;
    } else if (row == 4) {
        cell.textLabel.text = NSLocalizedString(@"Top mentioning", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"People mentioning you the most", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_violet"]];
        count = self.mentioningCount;
    } else if (row == 5) {
        cell.textLabel.text = NSLocalizedString(@"Videos", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Tweets with videos only", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_green"]];
        count = self.videosCount;
    } else if (row == 6) {
        cell.textLabel.text = NSLocalizedString(@"Images", nil);
        cell.detailTextLabel.text = NSLocalizedString(@"Tweets with images only", nil);
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell-bg_blue"]];
        count = self.imagesCount;
    }
    
    cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (![UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier) {
        [Utils showPrevUserChangedAlert];
        return;
    }
    
    if (![Utils tweeprProEnabled]) {
        [Utils showTweeprProAlert];
        return;
    }

    NSInteger row = [indexPath row];
    UIViewController *nextViewController = nil;
    
    if (row == 0) {
        nextViewController = [[TPRRetweetsViewController alloc] initWithNibName:nil bundle:nil];
    } else if (row == 1) {
        nextViewController = [[TPRRetweetersViewController alloc] initWithNibName:nil bundle:nil];
    } else if (row == 2) {
        nextViewController = [[TPRRetweetedViewController alloc] initWithNibName:nil bundle:nil];
    } else if (row == 3) {
        nextViewController = [[TPRMentionedViewController alloc] initWithNibName:nil bundle:nil];
    } else if (row == 4) {
        nextViewController = [[TPRMentioningViewController alloc] initWithNibName:nil bundle:nil];
    } else if (row == 5) {
        nextViewController = [[TPRVideosViewController alloc] initWithNibName:nil bundle:nil];
    } else if (row == 6) {
        nextViewController = [[TPRImagesViewController alloc] initWithNibName:nil bundle:nil];
    }
    
    if (nextViewController != nil) {
        [self.navigationController pushViewController:nextViewController animated:YES];
    }
}

#pragma mark - IBActions



@end
