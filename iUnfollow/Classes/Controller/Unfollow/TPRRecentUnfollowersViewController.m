//
//  TPRRecentUnfollowersViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

#import "TPRRecentUnfollowersViewController.h"

@interface TPRRecentUnfollowersViewController ()

@end

@implementation TPRRecentUnfollowersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.unfollowEnabled = NO;
    }

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
    return self;
}

- (void)viewDidLoad
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    [super viewDidLoad];
    self.title = NSLocalizedString(@"Unfollowing you", nil);

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)updateDataSource
{
	BTITrackingLog(@">>> Entering <%p> %s <<<", self, __PRETTY_FUNCTION__);

    self.items = [[DataManager sharedInstance] getRecentUnfollowers];
    [super updateDataSource];

	BTITrackingLog(@"<<< Leaving  <%p> %s >>>", self, __PRETTY_FUNCTION__);
}

@end
