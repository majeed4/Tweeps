//
//  UIImage+TPR.m
//  Tweepr
//
//  Created by Kamil Kocemba on 05/07/2013.
//
//

#import "UIImage+TPR.h"

@implementation UIImage (TPR)

- (UIImage *)TPRImageWithInsets:(UIEdgeInsets)insets {
    CGRect frame = CGRectMake(0, 0, self.size.width - insets.left - insets.right, self.size.height - insets.top - insets.bottom);
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0.0);
    [self drawInRect:CGRectMake(-insets.left, -insets.top, self.size.width, self.size.height)];
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}

+ (instancetype)tpr_maskedImageWithImage:(UIImage *)image {
    if (!image)
        return nil;
    CGFloat dim = MIN(image.size.width, image.size.height);
    CGSize size = CGSizeMake(dim, dim);
    UIGraphicsBeginImageContextWithOptions(size, NO, .0);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithOvalInRect:(CGRect){ CGPointZero, size }];
    [bezierPath fill];
    [bezierPath addClip];
    CGPoint offset = CGPointMake((dim - image.size.width) * 0.5, (dim - image.size.height) * 0.5);
    [image drawInRect:(CGRect){ offset, image.size }];
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}

@end
