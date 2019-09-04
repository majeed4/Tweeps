//
//  Utils.m
//  Tweepr
//


#import "Utils.h"
#import "Reachability.h"
#import "SVProgressHUD.h"
#import "TPRTweeprProViewController.h"
#import "TPRAppDelegate.h"

#define iPad    UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

@implementation Utils

+ (BOOL)tweeprProEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"tweepr_pro_enabled"];
}

+ (BOOL)isValidEmail:(NSString *)checkString {
	BOOL stricterFilter = YES; 
	NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
	NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:checkString];
}

+ (BOOL)internetConnectionIsAvailable {

	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Your device doesn't seem to be connected to any internet network", nil)
														message:NSLocalizedString(@"Please try again later", nil)
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
											  otherButtonTitles:nil];
		[alert show];

		return NO;
	}
	return YES;
}
+ (BOOL)internetConnectionIsAvailableWithoutAlertView {
    
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        
		return NO;
	}
	return YES;
}

+ (void)saveImage:(UIImage *)img withName:(NSString *)name {
	name = [NSString stringWithFormat:@"%@",name];
	name = [name stringByReplacingOccurrencesOfString:@".png" withString:@""];
	name = [name stringByReplacingOccurrencesOfString:@".jpg" withString:@""];
	name = [name stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	name = [name stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	
	NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	
	NSString *jpegFilePath = [NSString stringWithFormat:@"%@/%@.png",docDir,name];
	NSData *data2 = [NSData dataWithData:UIImagePNGRepresentation(img)];
	[data2 writeToFile:jpegFilePath atomically:YES];
}

+ (void)saveScalledImage:(UIImage *)img withName:(NSString *)name {
	name = [NSString stringWithFormat:@"s_%@",name];
	name = [name stringByReplacingOccurrencesOfString:@".png" withString:@""];
	name = [name stringByReplacingOccurrencesOfString:@".jpg" withString:@""];
	name = [name stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	name = [name stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	
	NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	
	NSString *jpegFilePath = [NSString stringWithFormat:@"%@/%@.png",docDir,name];
	NSData *data2 = [NSData dataWithData:UIImagePNGRepresentation([self imageWithImage:img scaledToSize:CGSizeMake(78, 78)])];
	[data2 writeToFile:jpegFilePath atomically:YES];

}

+ (UIImage *)imageWithName:(NSString *)name {
	UIImage *retVal;

		name = [name stringByReplacingOccurrencesOfString:@".png" withString:@""];
		name = [NSString stringWithFormat:@"%@",name];
		name = [name stringByReplacingOccurrencesOfString:@".jpg" withString:@""];
		name = [name stringByReplacingOccurrencesOfString:@"http://" withString:@""];
		name = [name stringByReplacingOccurrencesOfString:@"https://" withString:@""];
		NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		
		NSString *jpegFilePath = [NSString stringWithFormat:@"%@/%@.png",docDir,name];
		retVal = [UIImage imageWithContentsOfFile:jpegFilePath];
		if (!retVal) {
		}
	return retVal;
}

+ (UIImage *)scalledImageWithName:(NSString *)name {
	UIImage *retVal;
	
	name = [name stringByReplacingOccurrencesOfString:@".png" withString:@""];
	name = [NSString stringWithFormat:@"s_%@",name];
	name = [name stringByReplacingOccurrencesOfString:@".jpg" withString:@""];
	name = [name stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	name = [name stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	
	NSString *jpegFilePath = [NSString stringWithFormat:@"%@/%@.png",docDir,name];
	retVal = [UIImage imageWithContentsOfFile:jpegFilePath];
	if (!retVal) {
	}
	return retVal;

}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0f);
	CGContextSetInterpolationQuality( UIGraphicsGetCurrentContext() , kCGInterpolationHigh );
	[image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}


- (BOOL)isIphoneFive {
    if (iPad) {
        return NO;
    } else {
        if ([UIScreen mainScreen].bounds.size.height == 568) {
            return YES;
        }
    }
    return NO;
}

+ (void)userLoggedIn {
	NSUserDefaults *defautls = [NSUserDefaults standardUserDefaults];
	[defautls setBool:YES forKey:@"userIsLoggedIn"];
	[defautls synchronize];
}

+ (BOOL)isUserLoggedIn {
	NSUserDefaults *defautls = [NSUserDefaults standardUserDefaults];
	if ([defautls boolForKey:@"userIsLoggedIn"]) {
		return YES;
	}
	return NO;
}

+(BOOL)isIphoneFive {
    if (iPad) {
        return NO;
    } else {
        if ([UIScreen mainScreen].bounds.size.height == 568) {
            return YES;
        }
    }
    return NO;
}

+ (void)showPrevUserChangedAlert {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) 
													message:NSLocalizedString(@"No twitter account set or last account is no longer available", nil) 
												   delegate:nil 
										  cancelButtonTitle:NSLocalizedString(@"Ok", nil)
										  otherButtonTitles:nil];
    [alert setTag:100];
	[alert show];
}

+ (void)showTweeprProAlert {
    TPRTweeprProViewController *vc = [[TPRTweeprProViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    TPRAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [delegate.window.rootViewController presentViewController:nc animated:YES completion:NULL];
}

+ (NSString *)numberToKStringNotation:(NSNumber *)number {
	NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[formatter setRoundingMode:NSNumberFormatterRoundHalfEven];
	[formatter setMaximumFractionDigits:0];
	
	NSString *retVal;
	if ([number integerValue] > 1000) {
		float kNumber = [number integerValue] / 1000.0;
		NSNumber *n = @(kNumber);
		retVal = [formatter stringFromNumber:n];
	} else {
        return number.stringValue;
    }
	return [retVal stringByAppendingFormat:@"K"];
}


+ (void)cancelAllRequests {
    [SVProgressHUD dismiss];
}

+ (BOOL)isArabic {
    static BOOL arabic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *language = [NSLocale preferredLanguages][0];
        arabic = [language isEqualToString:@"ar"];
    });
    return arabic;
}

//+ (BOOL)didFetchCursor:(NSString *)cursor {
//    NSString *key = [NSString stringWithFormat:@"cursor_%@", cursor];
//    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
//}
//
//+ (void)setDidFetchCursor:(NSString *)cursor fetched:(BOOL)fetched {
//    NSString *key = [NSString stringWithFormat:@"cursor_%@", cursor];
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:fetched forKey:key];
//    [defaults synchronize];
//}

@end
