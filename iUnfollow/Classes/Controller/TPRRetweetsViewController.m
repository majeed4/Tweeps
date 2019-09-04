//
//  TPRRetweetsViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 04/06/2013.
//
//

#import "TPRRetweetsViewController.h"
#import "TPRTweetTableCell.h"
#import "UserTweet.h"
#import "TPRRetweetDetailsViewController.h"
#import "TPRAppDelegate.h"

@interface TPRRetweetsViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign, getter = isModernTableViewCache) BOOL modernTableViewCache;

@end

@implementation TPRRetweetsViewController

static NSString *cellIdentifier = @"retweetsTableCell";

- (void)loadView
{
    [super loadView];
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Top retweets", nil);

    self.tableView.backgroundColor = [UIColor TPRBackgroundColor];
    self.tableView.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"section-divider"]];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)])
    {
        [self setModernTableViewCache:YES];
        [self.tableView registerClass:[TPRTweetTableCell class] forCellReuseIdentifier:cellIdentifier];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND retweetCount > 0 AND retweetedFrom = nil", [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"retweetCount" ascending:NO]];
    fetchRequest.fetchLimit = 50;
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:[DataManager sharedInstance].mainThreadContext
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil];
    self.fetchedResultsController = frc;
}

- (void)reloadData
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    
    [self.tableView reloadData];

    BOOL isEmptyTable = ([self tableView:self.tableView numberOfRowsInSection:0] == 0);

    self.emptyLabel.alpha = (isEmptyTable) ? 1.0 : 0.0;

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)setDataNeedsReload
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];

	[self performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter == nil)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"E dd MMM Y HH:mm";
        _dateFormatter = dateFormatter;
    }
    return _dateFormatter;
}

- (void)viewWillAppear:(BOOL)animated
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [super viewWillAppear:animated];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didFetchUserTweetsNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didUpdateFrienshipStatusNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didFetchUserDetailsNotifcation object:nil];
	[notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:deleteUsersFinished object:nil];
    [notificationCenter addObserver:self selector:@selector(setDataNeedsReload) name:didSwitchAccountNotification object:nil];

    [self reloadData];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)viewDidAppear:(BOOL)animated
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [super viewDidAppear:animated];

    if ([UserLoadingRoutine sharedRoutine].lastSelectedUserIdentifier)
    {
//        [[NetworkManager sharedInstance] updateUserTweets];
        [[NetworkManager sharedInstance] updateUserTweetsWithCompletionHandler:nil];
    }
    else
    {
        [Utils showPrevUserChangedAlert];
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (void)viewWillDisappear:(BOOL)animated
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [super viewWillDisappear:animated];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:didFetchUserTweetsNotification object:nil];
    [notificationCenter removeObserver:self name:didUpdateFrienshipStatusNotification object:nil];
    [notificationCenter removeObserver:self name:didFetchUserDetailsNotifcation object:nil];
	[notificationCenter removeObserver:self name:deleteUsersFinished object:nil];
    [notificationCenter removeObserver:self name:didSwitchAccountNotification object:nil];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return [[self.fetchedResultsController sections] count];
}

- (UIView *)tableView:(UITableView *)tableView
viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserTweet *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *text = [tweet.text stringByDecodingHTMLEntities];
    return [TPRTweetTableCell heightWithText:text hasMedia:NO showRetweets:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TPRTweetTableCell *cell = nil;
    if ([self isModernTableViewCache])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell)
        {
            cell = [[TPRTweetTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
    }

    DataManager *dataManager = [DataManager sharedInstance];
    
    UserTweet *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [tweet.text stringByDecodingHTMLEntities];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:tweet.createdAt];
    if (!cell.accessoryView)
    {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure-indicator"]];
    }
    cell.showRetweets = YES;
    cell.retweetsLabel.text = [NSString stringWithFormat:@"%ld", (long)tweet.retweetCount];
    
    __weak typeof(cell) wcell = cell;
    User *user = [dataManager getUserInfoInContext:[dataManager mainThreadContext]];
    NSString *authorURL = user.profileImageUrl;
    cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", user.userName];
    [cell.userImageView sd_setImageWithURL:[NSURL URLWithString:authorURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        wcell.userImageView.image = [UIImage tpr_maskedImageWithImage:image];
        if (cacheType == SDImageCacheTypeNone) {
            wcell.imageView.alpha = 0.0;
            [UIView animateWithDuration:0.5 animations:^{
                wcell.imageView.alpha = 1.0;
            }];
        }
        [wcell setNeedsLayout];
    }];
//    [cell.userImageView setImageWithURL:[NSURL URLWithString:authorURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        wcell.userImageView.image = [UIImage tpr_maskedImageWithImage:image];
//        if (cacheType == SDImageCacheTypeNone) {
//            wcell.imageView.alpha = 0.0;
//            [UIView animateWithDuration:0.5 animations:^{
//                wcell.imageView.alpha = 1.0;
//            }];
//        }
//        [wcell setNeedsLayout];
//    }];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UserTweet *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    TPRAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    TPRRetweetDetailsViewController *vc = [delegate.storyboard instantiateViewControllerWithIdentifier:@"TPRRetweetDetailsViewController"];
    vc.tweet = tweet;
        
    [self.navigationController pushViewController:vc animated:YES];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

@end
