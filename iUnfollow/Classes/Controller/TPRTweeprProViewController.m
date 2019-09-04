//
//  TPRTweeprProViewController.m
//  Tweepr
//
//  Created by Kamil Kocemba on 15/06/2013.
//
//

#import "TPRTweeprProViewController.h"
#import "TPRIAPManager.h"

@interface TPRTweeprProViewController ()

@end

@implementation TPRTweeprProViewController

- (void)loadView {
    [super loadView];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor TPRBackgroundColor];
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pro-version-box"]];
    backgroundView.frame = CGRectMake(10, 40, 300, 288);
    [self.view addSubview:backgroundView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 150, 220, 100)];
    label.font = [UIFont TPRFontWithSize:14];
    label.text = NSLocalizedString(@"Sorry. This Feature is only available with Tweepr Pro Version. Please feel free to buy Tweepr Pro if you want unlock this and many other features.", nil);
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.backgroundColor = [UIColor clearColor];
    [self.view addSubview:label];
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pro_purchase_logo"]];
    logoImageView.frame = CGRectMake(118, 65, 78, 57);
    [self.view addSubview:logoImageView];
    
    UIImageView *separatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pro_purchase_divider"]];
    separatorView.frame = CGRectMake(18, 145, 282, 1);
    [self.view addSubview:separatorView];
    
    UIButton *buyButton = [[UIButton alloc] initWithFrame:CGRectMake(18, 260, 282, 56)];
    [buyButton setBackgroundImage:[UIImage imageNamed:@"purchase-btn"] forState:UIControlStateNormal];
    [buyButton setTitle:[NSLocalizedString(@"Purchase", nil) uppercaseString] forState:UIControlStateNormal];
    buyButton.titleLabel.font = [UIFont TPRFontWithSize:24];
    buyButton.titleEdgeInsets = UIEdgeInsetsMake(0, 40, 0, 0);
    [buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [buyButton addTarget:self action:@selector(purchase) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buyButton];
    
    UIButton *restoreButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    restoreButton.frame = CGRectMake(20, self.view.bounds.size.height - 61, 280, 56);
    restoreButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    //[restoreButton setBackgroundImage:[UIImage imageNamed:@"purchase-btn"] forState:UIControlStateNormal];
    [restoreButton setTitle:[NSLocalizedString(@"Restore Purchase", nil) uppercaseString] forState:UIControlStateNormal];
    restoreButton.titleLabel.font = [UIFont TPRFontWithSize:20];
    //restoreButton.titleEdgeInsets = UIEdgeInsetsMake(0, 80, 0, 0);
    //[restoreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [restoreButton addTarget:self action:@selector(restorePurchase:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:restoreButton];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Tweepr Pro";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:didPurchaseTweeprProNotification object:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)purchase {

#warning Enable to simulate IAP
#if 0
    {{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"tweepr_pro_enabled"];
        [defaults synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:didPurchaseTweeprProNotification object:nil];
    }}
#endif
    // This is the normal IAP code.  Disable to test.
    [[TPRIAPManager sharedManager] purchaseProVersion];

}

- (void)restorePurchase:(UIButton*)sender
{
    [[TPRIAPManager sharedManager] restorePurchases];
}

@end
