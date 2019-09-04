//
//  UIColor+TPR.m
//  Tweepr
//
//  Created by Kamil Kocemba on 05/07/2013.
//
//

#import "UIColor+TPR.h"

@implementation UIColor (TPR)

+ (UIColor *)TPRGrayColor {
    return [UIColor colorWithWhite:0.84 alpha:1.0];
}

+ (UIColor *)TPRLightGrayColor {
    return [UIColor colorWithWhite:0.90 alpha:1.0];
}

+ (UIColor *)TPRDarkTextColor {
    return [UIColor colorWithRed:22.0 / 255.0 green:20.0 / 255.0 blue:20.0 / 255.0 alpha:1.0];
}

+ (UIColor *)TPRHighlightedTextColor {
    return [UIColor colorWithWhite:0.94 alpha:1.0];
}

+ (UIColor *)TPRBackgroundColor {
    return [UIColor colorWithRed:234.0 / 255.0 green:235.0 / 255.0 blue:230.0 / 255.0 alpha:1.0];
}

+ (UIColor *)TPRDarkColor {
    return [UIColor colorWithWhite:0.43 alpha:1.0];
}

+ (UIColor *)TPRBlueColor {
    return [UIColor colorWithRed:45.0 / 255.0 green:186.0 / 255.0 blue:232.0 / 255.0 alpha:1.0];
}

@end
