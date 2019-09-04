//
//  UIImage+TPR.h
//  Tweepr
//
//  Created by Kamil Kocemba on 05/07/2013.
//
//

@interface UIImage (TPR)

- (UIImage *)TPRImageWithInsets:(UIEdgeInsets)insets;

+ (instancetype)tpr_maskedImageWithImage:(UIImage *)image;


@end
