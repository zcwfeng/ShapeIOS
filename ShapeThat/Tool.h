//
//  Tool.h
//  ShapeThat
//
//  Created by Lilian Erhan on 7/31/13.
//  Copyright (c) 2013 Lilian Erhan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    MaskModeNormal = 0,
    MaskModeRevert = 1
}MaskMode;

@interface Tool : NSObject

+ (UIImage *)reverseMask:(UIImage *)maskImage;
+ (UIImage *)resolveImageOrientations:(UIImage *)sourceImage;
+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size;
+ (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage;
+ (UIImage *)rotateImage:(UIImage *)sourceImage andOrientation:(UIImageOrientation)orientation;
+ (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage maskMode:(MaskMode)maskMode;
+ (UIImage *)getVisibleAreaFromScroll:(UIScrollView *)scrollView sourceImage:(UIImage *)sourceImage value:(float)value size:(CGSize)size;
+ (UIImage *)renderImage:(UIImage *)sourceImage originalImage:(UIImage *)originalImage withView:(UIView *)view;
+ (NSString *)instagramImagePath:(UIImage *)image;
+ (NSString *)shareImagePath:(UIImage *)image;

@end
