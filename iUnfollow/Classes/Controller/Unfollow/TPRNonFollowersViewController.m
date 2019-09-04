//
//  TPRNonFollowersViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

#import "TPRNonFollowersViewController.h"

@interface TPRNonFollowersViewController ()

@end

@implementation TPRNonFollowersViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.unfollowEnabled = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Non-Followers", nil);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)updateDataSource {
    self.items = [[DataManager sharedInstance] getAllNonFollowingUsers];
    
    [super updateDataSource];
}


@end
