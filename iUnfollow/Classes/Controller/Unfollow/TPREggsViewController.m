//
//  TPREggsViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 28/05/2013.
//
//

#import "TPREggsViewController.h"

@interface TPREggsViewController ()

@end

@implementation TPREggsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.unfollowEnabled = NO;
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
    self.items = [[DataManager sharedInstance] getAllEggs];
    [super updateDataSource];
}


@end
