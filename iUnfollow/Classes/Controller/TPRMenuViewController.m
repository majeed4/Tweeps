//
//  TPRMenuViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 12/10/2013.
//
//

#import "TPRMenuViewController.h"
#import "TPRAppDelegate.h"

@interface TPRMenuViewController ()

@property (nonatomic, strong) IBOutlet UIButton *profileButton, *unfollowButton, *tweetButton, *settingsButton;

- (IBAction)selectProfile;
- (IBAction)selectUnfollow;
- (IBAction)selectTweet;
- (IBAction)selectSettings;

@end

@implementation TPRMenuViewController

#pragma mark - IBActions

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![Utils isIphoneFive]) {
        self.profileButton.frame = CGRectMake(0, 0, 70, 120);
        self.unfollowButton.frame = CGRectMake(0, 120, 70, 120);
        self.tweetButton.frame = CGRectMake(0, 240, 70, 120);
        self.settingsButton.frame = CGRectMake(0, 360, 70, 120);
    }
    
    if (![self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        CGFloat height = [Utils isIphoneFive] ? 137 : 115;
        self.profileButton.frame = CGRectMake(0, 0, 70, height);
        self.unfollowButton.frame = CGRectMake(0, height, 70, height);
        self.tweetButton.frame = CGRectMake(0, 2 * height, 70, height);
        self.settingsButton.frame = CGRectMake(0, 3 * height, 70, height);
    }
}

- (IBAction)selectProfile {
    [self _selectViewControllerWithIdentifier:@"TPRUserProfileNavigationController"];
}

- (IBAction)selectUnfollow {
    [self _selectViewControllerWithIdentifier:@"TPRUnfollowNavigationController"];
}

- (IBAction)selectTweet {
    [self _selectViewControllerWithIdentifier:@"TPRTweetNavigationController"];
}

- (IBAction)selectSettings {
    [self _selectViewControllerWithIdentifier:@"TPRSettingsNavigationController"];
}

#pragma mark - Private

- (void)_selectViewControllerWithIdentifier:(NSString *)identifier {
    TPRAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    UIViewController *vc = [delegate.storyboard instantiateViewControllerWithIdentifier:identifier];
    self.slidingViewController.topViewController = vc;
    [self.slidingViewController resetTopView];
}

@end
