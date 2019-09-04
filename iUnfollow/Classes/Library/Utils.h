//
//  Utils.h
//  Tweepr
//

@interface Utils : NSObject

+ (BOOL)isArabic;
+ (BOOL)tweeprProEnabled;

+ (BOOL)isValidEmail:(NSString *)checkString;
+ (BOOL)internetConnectionIsAvailable;
+ (BOOL)internetConnectionIsAvailableWithoutAlertView;
+ (BOOL)isIphoneFive;

+ (void)saveImage:(UIImage *)img withName:(NSString *)name;
+ (void)saveScalledImage:(UIImage *)img withName:(NSString *)name;
+ (UIImage *)imageWithName:(NSString *)name;
+ (UIImage *)scalledImageWithName:(NSString *)name;
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

+ (void)userLoggedIn;
+ (BOOL)isUserLoggedIn;

+ (void)showTweeprProAlert;
+ (void)showPrevUserChangedAlert;

+ (NSString *)numberToKStringNotation:(NSNumber *)number;

+ (void)cancelAllRequests;

//+ (BOOL)didFetchCursor:(NSString *)cursor;
//+ (void)setDidFetchCursor:(NSString *)cursor fetched:(BOOL)fetched;

@end
