//
//  TPRIAPManager.m
//  Tweepr
//
//  Created by Kamil Kocemba on 06/07/2013.
//
//

#import "TPRIAPManager.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface TPRIAPManager ()<SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) SKProduct *tweeprProProduct;

@end

@implementation TPRIAPManager

static NSString *TPRTweeprProIdentifier = @"tweepr";

+ (TPRIAPManager *)sharedManager {
    static TPRIAPManager *sharedIAPManagerInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedIAPManagerInstance = [[TPRIAPManager alloc] init];
    });
    return sharedIAPManagerInstance;
}

- (id)init {
    if ((self = [super init])) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)requestProductData {
    if ([Utils tweeprProEnabled])
        return;
    SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithObject: TPRTweeprProIdentifier]];
    request.delegate = self;
    [request start];
}

- (void)purchaseProVersion {
    if (!self.tweeprProProduct)
        return;
    if ([Utils tweeprProEnabled])
        return;
    [SVProgressHUD show];
    SKPayment *payment = [SKPayment paymentWithProduct:self.tweeprProProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}


#pragma mark - SKProductRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"Products %@, invalid products %@", response.products, response.invalidProductIdentifiers);
    for (SKProduct *product in response.products) {
        if ([product.productIdentifier isEqualToString:TPRTweeprProIdentifier])
            self.tweeprProProduct = product;
    }
}


#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, transactions);
    if ([Utils tweeprProEnabled])
        return;
    
    for (SKPaymentTransaction *transaction in transactions) {
        
        BOOL shouldUnlockTweeprPro = NO;

        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            if ([transaction.payment.productIdentifier isEqualToString:TPRTweeprProIdentifier]) {
                shouldUnlockTweeprPro = YES;
            }
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [SVProgressHUD dismiss];
        }
        if (transaction.transactionState == SKPaymentTransactionStateRestored) {
            if ([transaction.originalTransaction.payment.productIdentifier isEqualToString:TPRTweeprProIdentifier]) {
                shouldUnlockTweeprPro = YES;
            }
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [SVProgressHUD dismiss];
        }
        if (transaction.transactionState == SKPaymentTransactionStateFailed) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [SVProgressHUD dismiss];
        }
        
        if (shouldUnlockTweeprPro) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"tweepr_pro_enabled"];
            [defaults synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:didPurchaseTweeprProNotification object:nil];
        }
    }
}

@end
