//
//  TPRFriendsViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 27/05/2013.
//
//

#import "TPRFriendsViewController.h"

@interface TPRFriendsViewController ()

@end

@implementation TPRFriendsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.unfollowEnabled = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Friends", nil);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)updateDataSource {
    self.items = [[DataManager sharedInstance] getAllFriends];
    [super updateDataSource];
}


@end
