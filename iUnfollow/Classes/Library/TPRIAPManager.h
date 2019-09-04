//
//  TPRIAPManager.h
//  Tweepr
//
//  Created by Kamil Kocemba on 06/07/2013.
//
//

@interface TPRIAPManager : NSObject

+ (TPRIAPManager *)sharedManager;
- (void)requestProductData;
- (void)purchaseProVersion;
- (void)restorePurchases;

@end
