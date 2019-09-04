//
//  UIImageView+TPR.m
//  Tweepr
//
//  Created by Kamil Kocemba on 12/10/2013.
//
//

#import "UIImageView+TPR.h"

@implementation UIImageView (TPR)

- (void)TPRSetImageWithURL:(NSURL *)url {
    __weak typeof(self) wself = self;
    [self sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        wself.image = [UIImage tpr_maskedImageWithImage:image];
        if (cacheType == SDImageCacheTypeNone) {
            wself.alpha = 0.0;
            [UIView animateWithDuration:0.4 animations:^{
                wself.alpha = 1.0;
            }];
        }
    }];
//    [self setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        wself.image = [UIImage tpr_maskedImageWithImage:image];
//        if (cacheType == SDImageCacheTypeNone) {
//            wself.alpha = 0.0;
//            [UIView animateWithDuration:0.4 animations:^{
//                wself.alpha = 1.0;
//            }];
//        }
//    }];
}

- (void)tpr_setAvatarImageWithURL:(NSURL *)url {
    __weak typeof(self) wself = self;
    [self sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        wself.image = [UIImage tpr_maskedImageWithImage:image];
        if (cacheType == SDImageCacheTypeNone) {
            wself.alpha = 0.0;
            [UIView animateWithDuration:0.4 animations:^{
                wself.alpha = 1.0;
            }];
        }
    }];
//    [self setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        wself.image = [UIImage tpr_maskedImageWithImage:image];
//        if (cacheType == SDImageCacheTypeNone) {
//            wself.alpha = 0.0;
//            [UIView animateWithDuration:0.4 animations:^{
//                wself.alpha = 1.0;
//            }];
//        }
//    }];
}

@end
