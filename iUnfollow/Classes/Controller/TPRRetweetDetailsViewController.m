//
//  TPRRetweetDetailsViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 08/06/2013.
//
//

#import "TPRRetweetDetailsViewController.h"
#import "TPRUsersTableCell.h"

@interface TPRRetweetDetailsViewController ()

@property (nonatomic, strong) IBOutlet UILabel *textLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *retweetsLabel;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, assign) BOOL didLayoutHeaderView;

@end

@implementation TPRRetweetDetailsViewController

static NSString *cellIdentifier = @"TPRUsersTableViewCell";

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"E dd MMM Y HH:mm";
        _dateFormatter = dateFormatter;
    }
    return _dateFormatter;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Retweets", nil);
    [self.tableView registerClass:[TPRUsersTableCell class] forCellReuseIdentifier:cellIdentifier];

    [[NetworkManager sharedInstance] getRetweetsOfTweet:self.tweet];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!self.didLayoutHeaderView) {
        UIView *headerView = self.tableView.tableHeaderView;
        headerView.frame = CGRectMake(0, 0, 320, CGRectGetHeight(self.textLabel.frame) + 54);
        self.tableView.tableHeaderView = headerView;
        self.didLayoutHeaderView = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:didFetchUserTweetsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:didFetchUserDetailsNotifcation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:didSwitchAccountNotification object:nil];
    
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[self navigationItem] setHidesBackButton:NO animated:YES];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:didFetchUserTweetsNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didFetchUserDetailsNotifcation object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didSwitchAccountNotification object:nil];
}

- (void)reloadData {
    self.items = [self.tweet.retweeters sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"numFollowers" ascending:NO]]];
    if (self.items.count > 20) {
        NSMutableArray *topUsers = [NSMutableArray array];
        for (NSInteger i = 0; i < 20; ++i) {
            [topUsers addObject:self.items[i]];
        }
        self.items = topUsers;
    }
    
    self.textLabel.text = [self.tweet.text stringByDecodingHTMLEntities];
    self.dateLabel.text = [self.dateFormatter stringFromDate:self.tweet.createdAt];
    self.retweetsLabel.text = [NSString stringWithFormat:@"%ld %@", (long)self.tweet.retweetCount, NSLocalizedString(@"retweets", nil)];

    NSMutableArray *ids = [NSMutableArray array];
    for (TwitterUser *user in self.items) {
        if (!user.hasDetails) {
            [ids addObject:user.identifier];
        }
    }
    
    if (ids.count) {
        [[NetworkManager sharedInstance] fetchDetailsForUserIds:ids];
    }

    [self refreshContents];
}

#pragma mark - Misc

- (void)refreshContents {
    UILabel *textLabel = [self textLabel];
    textLabel.font = [UIFont TPRFontWithSize:13];
    textLabel.textColor = [UIColor blackColor];

    UILabel *dateLabel = [self dateLabel];
    dateLabel.font = [UIFont TPRFontWithSize:11];
    dateLabel.textColor = [UIColor blackColor];

    UILabel *retweetsLabel = [self retweetsLabel];
    retweetsLabel.font = [UIFont TPRFontWithSize:13];
    retweetsLabel.textColor = [UIColor blackColor];
    
    [textLabel sizeToFit];
    CGRect textLabelFrame = textLabel.frame;

    CGRect dateLabelFrame = [dateLabel frame];
    dateLabelFrame.origin.y = CGRectGetMaxY(textLabelFrame) + 12.0;
    [dateLabel setFrame:dateLabelFrame];

    CGRect retweetLabelFrame = [retweetsLabel frame];
    retweetLabelFrame.origin.y = CGRectGetMaxY(textLabelFrame) + 13.0;
    [retweetsLabel setFrame:retweetLabelFrame];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImageView *separatorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_wide"]];
    separatorImage.frame = CGRectMake(0, 29, 320, 1);
    UIImageView *topSeparatorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_wide"]];
    topSeparatorImage.frame = CGRectMake(0, 0, 320, 1);
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont TPRFontWithSize:12];
    l.textColor = [UIColor blackColor];
    l.text = NSLocalizedString(@"Latest retweeters", nil);
    [l addSubview:separatorImage];
    [l addSubview:topSeparatorImage];
    l.backgroundColor = [UIColor TPRBackgroundColor];
    return l;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 83;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MIN(self.items.count, 10);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TPRUsersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    TwitterUser *user = (self.items)[indexPath.row];
    cell.loaded = user.hasDetails;
    cell.showRetweetCount = YES;
    cell.showDisclosureIndicator = NO;
    __weak TPRUsersTableCell *wcell = cell;
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.profileImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        wcell.imageView.image = [UIImage tpr_maskedImageWithImage:image];
        if (cacheType == SDImageCacheTypeNone) {
            wcell.imageView.alpha = 0.0;
            [UIView animateWithDuration:0.5 animations:^{
                wcell.imageView.alpha = 1.0;
            }];
        }
        [wcell setNeedsLayout];
    }];
//	[cell.imageView setImageWithURL:[NSURL URLWithString:user.profileImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        wcell.imageView.image = [UIImage tpr_maskedImageWithImage:image];
//        if (cacheType == SDImageCacheTypeNone) {
//            wcell.imageView.alpha = 0.0;
//            [UIView animateWithDuration:0.5 animations:^{
//                wcell.imageView.alpha = 1.0;
//            }];
//        }
//        [wcell setNeedsLayout];
//    }];
    cell.retweetsLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)user.retweets.count];
    cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", user.screenName];
    cell.nameLabel.text = user.fullName;
    
    NSString *followingStr = [Utils numberToKStringNotation:@(user.numFollowing)];
    NSString *followersStr = [Utils numberToKStringNotation:@(user.numFollowers)];
    cell.followingLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Following", nil), followingStr];
    cell.followersLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Followers", nil), followersStr];
	return cell;
}


@end
