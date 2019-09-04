//
//  UIFont+TPR.m
//  Tweepr
//
//  Created by Kamil Kocemba on 05/07/2013.
//
//

#import "UIFont+TPR.h"

@implementation UIFont (TPR)

+ (UIFont *)TPRFontWithSize:(CGFloat)size {
    if ([Utils isArabic])
        return [UIFont systemFontOfSize:size];
    return [UIFont fontWithName:@"Abel-Regular" size:size];
}


@end
