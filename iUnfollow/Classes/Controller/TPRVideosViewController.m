//
//  TPRVideosViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 09/06/2013.
//
//

#import "TPRVideosViewController.h"
#import "TPRTweetTableCell.h"
#import "TPRWebViewController.h"

@interface TPRVideosViewController ()

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign, getter = isModernTableViewCache) BOOL modernTableViewCache;

@end

@implementation TPRVideosViewController

static NSString *cellIdentifier = @"TPRVideosTableCell";

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    [super loadView];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 40)];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont TPRFontWithSize:18];
    label.text = NSLocalizedString(@"There is currently no history to show.", nil);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    [self.view addSubview:label];
    label.alpha = 0.0;
    self.emptyLabel = label;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Videos", nil);
    
    self.tableView.backgroundColor = [UIColor TPRBackgroundColor];
    self.tableView.separatorColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"section-divider"]];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if ([self.tableView respondsToSelector:@selector(registerClass:forCellReuseIdentifier:)])
    {
        [self setModernTableViewCache:YES];
        [self.tableView registerClass:[TPRTweetTableCell class] forCellReuseIdentifier:cellIdentifier];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserTweet"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userIdentifier beginswith[cd] %@ AND hasVideo = 1", [[UserLoadingRoutine sharedRoutine] lastSelectedUserIdentifier]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[DataManager sharedInstance].mainThreadContext sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController = frc;
}

- (void)reloadData
{
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    
    NSMutableArray *ids = [NSMutableArray array];
    for (NSInteger i = 0; i < [self tableView:self.tableView numberOfRowsInSection:0]; ++i)
    {
        UserTweet *tweet = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        TwitterUser *user = tweet.retweetedFrom;
        if (user && !user.hasDetails)
        {
            if (!user.hasDetails && ids.count < 100)
            {
                [ids addObject:user.identifier];
            }
        }
    }
    
    if (ids.count)
    {
        [[NetworkManager sharedInstance] fetchDetailsForUserIds:ids animated:YES];
    }
    
    [self.tableView reloadData];

    BOOL isEmpty = ([self tableView:self.tableView numberOfRowsInSection:0] == 0);
    self.emptyLabel.alpha = (isEmpty) ? 1.0 : 0.0;
}

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"E dd MMM Y HH:mm";
        _dateFormatter = dateFormatter;
    }
    return _dateFormatter;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:didFetchUserTweetsNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:didSwitchAccountNotification object:self];

    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:didFetchUserTweetsNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didSwitchAccountNotification object:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UIView *)tableView:(UITableView *)tableView
viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserTweet *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *text = [tweet.text stringByDecodingHTMLEntities];
    return [TPRTweetTableCell heightWithText:text hasMedia:tweet.hasVideo];
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.retweetsLabel.text = [NSString stringWithFormat:@"%ld", (long)tweet.retweetCount];
    cell.hasMedia = tweet.hasImage;

    __weak TPRTweetTableCell *weakCell = cell;
    User *user = [dataManager getUserInfoInContext:[dataManager mainThreadContext]];
    NSString *authorURL = user.profileImageUrl;
    if (tweet.retweetedFrom)
    {
        authorURL = tweet.retweetedFrom.profileImageUrl;
        if (tweet.retweetedFrom.screenName)
        {
            cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", tweet.retweetedFrom.screenName];
        }
        else
        {
            cell.screenNameLabel.text = nil;
        }
    }
    else
    {
        cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", user.userName];
    }

    [cell.userImageView sd_setImageWithURL:[NSURL URLWithString:authorURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        weakCell.userImageView.image = [UIImage tpr_maskedImageWithImage:image];
        if (cacheType == SDImageCacheTypeNone) {
            weakCell.userImageView.alpha = 0.0;
            [UIView animateWithDuration:0.5 animations:^{
                weakCell.userImageView.alpha = 1.0;
            }];
        }
        [weakCell setNeedsLayout];
    }];
    
//    [cell.userImageView setImageWithURL:[NSURL URLWithString:authorURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        weakCell.userImageView.image = [UIImage tpr_maskedImageWithImage:image];
//        if (cacheType == SDImageCacheTypeNone) {
//            weakCell.userImageView.alpha = 0.0;
//            [UIView animateWithDuration:0.5 animations:^{
//                weakCell.userImageView.alpha = 1.0;
//            }];
//        }
//        [weakCell setNeedsLayout];
//    }];

    cell.hasMedia = YES;
    cell.mediaUrlLabel.text = tweet.videoUrl;
    if (tweet.hasVideo)
    {
        cell.showPlayButton = YES;
        cell.playButton.tag = indexPath.row;
        [cell.playButton removeTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
        [cell.playButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];

        __block NSString *videoId;
        if ([tweet.videoUrl rangeOfString:@"youtu.be"].location != NSNotFound)
        {
            videoId = [[tweet.videoUrl pathComponents] lastObject];
        }
        else
        {
            NSError *error;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"v=([A-Za-z0-9_-]+)"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:&error];
            [regex enumerateMatchesInString:tweet.videoUrl options:0 range:NSMakeRange(0, tweet.videoUrl.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                videoId = [tweet.videoUrl substringWithRange:[match rangeAtIndex:1]];
            }];
        }

        if (videoId)
        {
            NSString *imageUrl = [NSString stringWithFormat:@"http://img.youtube.com/vi/%@/hqdefault.jpg", videoId];
            [cell.mediaImageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[[UIImage alloc] init] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                __strong TPRTweetTableCell *strongCell = weakCell;
                if (!image)
                {
                    strongCell.mediaImageView.image = [UIImage imageNamed:@"youtube"];
                }
                
                if (cacheType == SDImageCacheTypeNone)
                {
                    strongCell.mediaImageView.alpha = 0.0;
                    [UIView animateWithDuration:0.5 animations:^{
                        strongCell.mediaImageView.alpha = 1.0;
                    }];
                }
            }];
//            [cell.mediaImageView setImageWithURL:[NSURL URLWithString:imageUrl]
//                           placeholderImage:[[UIImage alloc] init]
//                                  completed:
//             ^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//                 __strong TPRTweetTableCell *strongCell = weakCell;
//                 if (!image)
//                 {
//                     strongCell.mediaImageView.image = [UIImage imageNamed:@"youtube"];
//                 }
//
//                 if (cacheType == SDImageCacheTypeNone)
//                 {
//                     strongCell.mediaImageView.alpha = 0.0;
//                     [UIView animateWithDuration:0.5 animations:^{
//                         strongCell.mediaImageView.alpha = 1.0;
//                     }];
//                 }
//             }];
        }
        else
        {
            cell.mediaImageView.image = [UIImage imageNamed:@"youtube"];
        }
    }
    else
    {
        cell.showPlayButton = NO;
        cell.mediaImageView.image = [UIImage imageNamed:@"youtube"];
    }
    return cell;
}

#pragma mark - Actions

- (void)playVideo:(id)sender
{
    UIButton *button = sender;
    NSInteger index = button.tag;
    UserTweet *tweet = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    TPRWebViewController *vc = [[TPRWebViewController alloc] initWithNibName:nil bundle:nil];
    vc.url = tweet.videoUrl;
    UINavigationController *wnc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:wnc animated:YES completion:NULL];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
