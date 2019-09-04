//
//  TPRSettingsViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 12/06/2013.
//
//

#import "TPRSettingsViewController.h"
#import "TPRAppDelegate.h"

@interface TPRSettingsViewController ()

@property (nonatomic, strong) UISwitch *notificationsSwitch;

@end

@implementation TPRSettingsViewController

-(void)awakeFromNib
{
    self.title = NSLocalizedString(@"Settings", nil);
}

- (void) viewDidLoad {
    [super viewDidLoad];
}

- (void)loadView {
    [super loadView];
    
    UILabel *tweetLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 30, 200, 20)];
    tweetLabel.font = [UIFont TPRFontWithSize:18];
    tweetLabel.text = NSLocalizedString(@"Enable Tweet notifications", nil);
    tweetLabel.adjustsFontSizeToFitWidth = YES;
    tweetLabel.backgroundColor = [UIColor clearColor];
    tweetLabel.textColor = [UIColor blackColor];
    [self.view addSubview:tweetLabel];
    
    UISwitch *notificationsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(240, 26, 80, 40)];
    [self.view addSubview:notificationsSwitch];
    self.notificationsSwitch = notificationsSwitch;
    self.notificationsSwitch.onTintColor = [UIColor colorWithRed:46.0 / 255.0 green:186.0 / 255.0 blue:232.0 / 255.0 alpha:1.0];
    
    [self.notificationsSwitch addTarget:self action:@selector(toggleNotifications:) forControlEvents:UIControlEventValueChanged];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    BOOL notificationsEnabled = [UserLoadingRoutine sharedRoutine].notificationsEnabled;
    self.notificationsSwitch.on = notificationsEnabled;
}

- (void)toggleNotifications:(UISwitch *)sender {
    [UserLoadingRoutine sharedRoutine].notificationsEnabled = sender.on;
}

#pragma mark - IBActions


@end
