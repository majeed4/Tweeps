//
//  TPRFansViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 26/05/2013.
//
//

#import "TPRFansViewController.h"

@interface TPRFansViewController ()

@end

@implementation TPRFansViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.unfollowEnabled = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Fans", nil);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)updateDataSource {
    self.items = [[DataManager sharedInstance] getAllFans];
    [super updateDataSource];
}

@end
