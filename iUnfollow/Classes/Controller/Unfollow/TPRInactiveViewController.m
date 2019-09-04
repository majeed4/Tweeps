//
//  TPRInactiveViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

#import "TPRInactiveViewController.h"

@interface TPRInactiveViewController ()

@end

@implementation TPRInactiveViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.unfollowEnabled = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Inactive", nil);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:didFetchUserDetailsNotifcation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDataSource) name:didFetchUserDetailsNotifcation object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)updateDataSource {
    self.items = [[DataManager sharedInstance] getInactiveUsers];
    [super updateDataSource];
}


@end
