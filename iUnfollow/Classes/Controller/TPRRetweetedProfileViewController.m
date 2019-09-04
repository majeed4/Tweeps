//
//  TPRRetweetedProfileViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 11/06/2013.
//
//

#import "TPRRetweetedProfileViewController.h"
#import "UserTweet.h"
#import "TwitterUser.h"
#import "TPRTweetTableCell.h"

@interface TPRRetweetedProfileViewController ()

@property (nonatomic, strong) TwitterUser *user;
@property (nonatomic, strong) NSArray *tweets;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign, getter = isModernTableViewCache) BOOL modernTableViewCache;

@end

@implementation TPRRetweetedProfileViewController

static NSString *cellIdentifier = @"TPRProfileTableViewCell";

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    [super loadView];
    self.tableView.backgroundColor = [UIColor TPRBackgroundColor];
    self.tableView.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"section-divider"]];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)])
    {
        [self setModernTableViewCache:YES];
        [self.tableView registerClass:[TPRTweetTableCell class] forCellReuseIdentifier:cellIdentifier];
    }
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"E dd MMM Y HH:mm";
        _dateFormatter = dateFormatter;
    }
    return _dateFormatter;
}

- (id)initWithUser:(TwitterUser *)user
{
    if ((self = [super initWithNibName:nil bundle:nil]))
    {
        self.user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"@%@", self.user.screenName];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadView) name:didUpdateUserTweets object:nil];

    [self reloadView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[NetworkManager sharedInstance] getUserTimeline:self.user];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:didUpdateUserTweets object:nil];
}


- (void)reloadView
{
    self.tweets = [self.user.userRetweets.allObjects sortedArrayUsingComparator:^NSComparisonResult(UserTweet *t1, UserTweet *t2) {
        return [t2.createdAt compare:t1.createdAt];
    }];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImageView *separatorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"divider_wide"]];
    separatorImage.frame = CGRectMake(0, 29, 320, 1);
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
    l.textAlignment = NSTextAlignmentCenter;
    l.font = [UIFont TPRFontWithSize:12];
    l.textColor = [UIColor blackColor];
    l.text = NSLocalizedString(@"Tweets you retweeted", nil);
    [l addSubview:separatorImage];
    l.backgroundColor = [UIColor TPRBackgroundColor];
    return l;
}


- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section
{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView
viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserTweet *tweet = (self.tweets)[indexPath.row];
    NSString *text = [tweet.text stringByDecodingHTMLEntities];
    return [TPRTweetTableCell heightWithText:text hasMedia:NO];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.tweets.count;
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
    
    UserTweet *tweet = (self.tweets)[indexPath.row];

    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:tweet.createdAt];
    cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", tweet.retweetedFrom.screenName];
    cell.textLabel.text = [tweet.text stringByDecodingHTMLEntities];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.hasMedia = NO;
    __weak typeof(cell) wcell = cell;
    NSString *authorURL = tweet.retweetedFrom.profileImageUrl;
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

