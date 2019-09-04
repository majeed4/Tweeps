//
//  TPRProfileViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 27/05/2013.
//
//

#import "TPRProfileViewController.h"
#import "TPRWebViewController.h"
#import "Tweet.h"
#import "TPRTweetTableCell.h"

typedef NS_ENUM(NSInteger, TPRAlertTag) {
    TPRBlockAlertTag = 1,
    TPRUnfollowAlertTag = 2,
    TPRFollowAlertTag = 3,
    TPRUnblockAlertTag = 4
};

@interface TPRProfileViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UIButton *followBtn, *blockBtn;
@property (nonatomic, strong) NSArray *tweets;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) IBOutlet UIImageView *profileBackgroundView, *avatarImageView, *backgroundImageView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel, *handleLabel, *websiteLabel, *descriptionLabel;
@property (nonatomic, strong) IBOutlet UILabel *numTweetsLabel, *numFollowersLabel, *numFollowingLabel;

- (IBAction)toggleFollow;
- (IBAction)toggleBlock;

@end

@implementation TPRProfileViewController

static NSString *cellIdentifier = @"TPRProfileTableViewCell";

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
    self.title = [NSString stringWithFormat:@"@%@", self.user.screenName];
    self.tweets = [self.user.tweets.allObjects sortedArrayUsingComparator:^NSComparisonResult(Tweet *t1, Tweet *t2) {
        return [t2.createdAt compare:t1.createdAt];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadView) name:didFetchUserDetailsNotifcation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadView) name:didUpdateUserTweets object:nil];

    [self reloadView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[NetworkManager sharedInstance] updateUser:self.user animated:YES];
    [[NetworkManager sharedInstance] getUserTimeline:self.user];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:didFetchUserDetailsNotifcation object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didUpdateUserTweets object:nil];
}

- (IBAction)toggleFollow {
    if (self.user.following.boolValue)
        [[NetworkManager sharedInstance] unfollowUser:self.user];
    else
        [[NetworkManager sharedInstance] followUser:self.user];
}

- (IBAction)toggleBlock {
    if (self.user.blocked.boolValue)
        [[NetworkManager sharedInstance] unblockUser:self.user];
    else
        [[NetworkManager sharedInstance] blockUser:self.user];
}

- (void)reloadView {
    NSURL *backgroundURL = [NSURL URLWithString:self.user.profileBackgroundUrl];
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
    
    NSURL *avatarURL = [NSURL URLWithString:self.user.profileImageUrl];
    [self.avatarImageView TPRSetImageWithURL:avatarURL];
    
    self.nameLabel.text = self.user.fullName;
    self.handleLabel.text = [NSString stringWithFormat:@"@%@", self.user.screenName];
    self.websiteLabel.text = self.user.websiteUrl.length ? self.user.websiteUrl : NSLocalizedString(@"No website", nil);
    self.descriptionLabel.text = self.user.biography;
    
    self.numTweetsLabel.text = [NSString stringWithFormat:@"%ld", (long)self.user.numTweets];
    self.numFollowersLabel.text = [NSString stringWithFormat:@"%ld", (long)self.user.numFollowers];
    self.numFollowingLabel.text = [NSString stringWithFormat:@"%ld", (long)self.user.numFollowing];


    NSString *followStr = self.user.following.boolValue ? @"Unfollow" : @"Follow";
    if (!self.user.following.boolValue)
        [self.followBtn setBackgroundImage:[UIImage imageNamed:@"follow_btn-bg"] forState:UIControlStateNormal];
    else
        [self.followBtn setBackgroundImage:[UIImage imageNamed:@"unf-bar-bg"] forState:UIControlStateNormal];
    
    [self.followBtn setTitle:[NSLocalizedString(followStr, nil) uppercaseString] forState:UIControlStateNormal];
    [self.followBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 26, 0, 0)];
    NSString *blockStr = self.user.blocked.boolValue ? @"Unblock" : @"Block";
    [self.blockBtn setTitle:[NSLocalizedString(blockStr, nil) uppercaseString] forState:UIControlStateNormal];
    [self.blockBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 26, 0, 0)];
    
    self.tweets = [self.user.tweets.allObjects sortedArrayUsingComparator:^NSComparisonResult(Tweet *t1, Tweet *t2) {
        return [t2.createdAt compare:t1.createdAt];
    }];
    
    [self.tableView reloadData];
}

//- (void)showAlertWithTag:(NSInteger)tag {
//    NSString *message = nil;
//    switch (tag) {
//        case TPRBlockAlertTag: message = NSLocalizedString(@"Are you sure you want to block this user?", nil); break;
//        case TPRFollowAlertTag: message = NSLocalizedString(@"Are you sure you want to follow this user?", nil); break;
//        case TPRUnblockAlertTag: message = NSLocalizedString(@"Are you sure you want to unblock this user?", nil); break;
//        case TPRUnfollowAlertTag: message = NSLocalizedString(@"Are you sure you want to unfollow this user?", nil); break;
//        default: break;
//    }
//}

- (void)showUserWebsite {
    if (!self.user.websiteUrl.length) {
        return;
    }
    TPRWebViewController *wvc = [[TPRWebViewController alloc] initWithNibName:nil bundle:nil];
    wvc.url = self.user.websiteUrl;
    wvc.pageTitle = self.user.screenName;
    UINavigationController *wnc = [[UINavigationController alloc] initWithRootViewController:wvc];
    [self.navigationController presentViewController:wnc animated:YES completion:NULL];
}

#pragma mark - UITableViewDelegate 

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImageView *separatorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_wide"]];
    separatorImage.frame = CGRectMake(0, 29, 320, 1);
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont TPRFontWithSize:12];
    l.textColor = [UIColor blackColor];
    l.text = NSLocalizedString(@"Latest Tweets", nil);
    [l addSubview:separatorImage];
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
    Tweet *tweet = (self.tweets)[indexPath.row];
    NSString *text = [tweet.text stringByDecodingHTMLEntities];
    return [TPRTweetTableCell heightWithText:text hasMedia:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TPRTweetTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    Tweet *tweet = (self.tweets)[indexPath.row];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:tweet.createdAt];
    cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", self.user.screenName];
    cell.textLabel.text = [tweet.text stringByDecodingHTMLEntities];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:tweet.createdAt];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.hasMedia = NO;
    __weak typeof(cell) wcell = cell;
    NSString *authorURL = self.user.profileImageUrl;
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


@end
