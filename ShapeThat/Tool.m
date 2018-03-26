//
//  Tool.m
//  ShapeThat
//
//  Created by Lilian Erhan on 7/31/13.
//  Copyright (c) 2013 Lilian Erhan. All rights reserved.
//

#import "Tool.h"
#import <QuartzCore/QuartzCore.h>
#import <stdlib.h>

#define ROUND_UP(N, S) ((((N) + (S) - 1) / (S)) * (S))

@implementation Tool

+ (NSString *)shareImagePath:(UIImage *)image
{
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [directory stringByAppendingPathComponent:@"image.png"];
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
    return filePath;
}

+ (NSString *)instagramImagePath:(UIImage *)image
{
    NSString *directory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [directory stringByAppendingPathComponent:@"image.ig"];
    [UIImageJPEGRepresentation(image, 1) writeToFile:filePath atomically:YES];
    return filePath;
}

+ (CGImageRef)createMaskWithImageAlpha:(CGContextRef)originalImageContext
{
    UInt8 *data = (UInt8 *)CGBitmapContextGetData(originalImageContext);
    
    float width = CGBitmapContextGetBytesPerRow(originalImageContext) / 4;
    float height = CGBitmapContextGetHeight(originalImageContext);
    
    int strideLength = ROUND_UP(width * 1, 4);
    unsigned char * alphaData = (unsigned char * )calloc(strideLength * height, 1);
    CGContextRef alphaOnlyContext = CGBitmapContextCreate(alphaData,
                                                          width,
                                                          height,
                                                          8,
                                                          strideLength,
                                                          NULL,
                                                          kCGImageAlphaOnly);
    
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            unsigned char val = data[y*(int)width*4 + x*4 + 3];
            val = (val==255)?255:0;
            alphaData[y*strideLength + x] = val;
        }
    }
    
    CGImageRef alphaMaskImage = CGBitmapContextCreateImage(alphaOnlyContext);
    CGContextRelease(alphaOnlyContext);
    free(alphaData);
    
    CGImageRef finalMaskImage = CGImageMaskCreate(CGImageGetWidth(alphaMaskImage),
                                                  CGImageGetHeight(alphaMaskImage),
                                                  CGImageGetBitsPerComponent(alphaMaskImage),
                                                  CGImageGetBitsPerPixel(alphaMaskImage),
                                                  CGImageGetBytesPerRow(alphaMaskImage),
                                                  CGImageGetDataProvider(alphaMaskImage), NULL, false);
    CGImageRelease(alphaMaskImage);

    return finalMaskImage;
}

+ (UIImage *)reverseMask:(UIImage *)maskImage
{
    CGImageRef originalImage = [maskImage CGImage];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       CGImageGetWidth(originalImage),
                                                       CGImageGetHeight(originalImage),
                                                       8,
                                                       CGImageGetWidth(originalImage)*4,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext)), originalImage);
    
    CGImageRef finalMaskImage = [self createMaskWithImageAlpha:bitmapContext];
    
    UIImage *resultImage = [UIImage imageWithCGImage:finalMaskImage];
    
    CGContextRelease(bitmapContext);
    CGImageRelease(finalMaskImage);
    
    return resultImage;
}

+ (UIImage *)maskImage:(UIImage *)givenImage withClippingMask:(UIImage *)maskImage
{
    UIGraphicsBeginImageContext(givenImage.size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(currentContext, 0, givenImage.size.height);
    CGContextScaleCTM(currentContext, 1.0, -1.0);
    CGRect rectSize = CGRectMake(0, 0, givenImage.size.width, givenImage.size.height);
    CGContextClipToMask(currentContext, rectSize, maskImage.CGImage);
    CGContextDrawImage(currentContext, rectSize, givenImage.CGImage);
    UIImage *imgMasked = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imgMasked;
}

+ (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage maskMode:(MaskMode)maskMode
{
    UIImage *resultImage = nil;
    
    switch (maskMode)
    {
        case MaskModeNormal:
        {
            resultImage = [self maskImage:image withClippingMask:maskImage];
            break;
        }
        case MaskModeRevert:
        {
            resultImage = [self maskImage:image withClippingMask:[self reverseMask:maskImage]];
            break;
        }
        default:
            break;
    }
    return resultImage;
}

+ (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage
{
    CGImageRef maskRef = maskImage.CGImage;
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef maskedImageRef = CGImageCreateWithMask([image CGImage], mask);
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedImageRef];
    
    CGImageRelease(mask);
    CGImageRelease(maskedImageRef);
    
    return maskedImage;
}

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size
{
    if (image.size.width > image.size.height)
    {
        size = CGSizeMake((image.size.width/image.size.height)*size.height, size.height);
    }
    else
    {
        size = CGSizeMake(size.width, (image.size.height/image.size.width)*size.width);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height));
    
    if (image.imageOrientation == UIImageOrientationRight)
    {
        CGContextRotateCTM(context, -M_PI_2);
        CGContextTranslateCTM(context, -size.height, 0.0f);
        CGContextDrawImage(context, CGRectMake(0, 0, size.height, size.width), image.CGImage);
    }
    else
    {
        CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image.CGImage);
    }
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(context);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    UIImage *resultImage = [UIImage imageWithCGImage:scaledImage];
    CGImageRelease(scaledImage);
    
    return resultImage;
}

+ (UIImage *)getVisibleAreaFromScroll:(UIScrollView *)scrollView sourceImage:(UIImage *)sourceImage value:(float)value size:(CGSize)size
{
    CGRect finalRect = CGRectZero;
    float scale = 1.0f/scrollView.zoomScale;
    finalRect.origin.x = finalRect.origin.y = 80 * value;
    finalRect.size.width = finalRect.size.height = scrollView.frame.size.width - (finalRect.origin.x * 2);
    
    finalRect.origin.x = (scrollView.contentOffset.x + finalRect.origin.x) * scale;
    finalRect.origin.y = (scrollView.contentOffset.y + finalRect.origin.y) * scale;
    finalRect.size.width = finalRect.size.width * scale;
    finalRect.size.height = finalRect.size.height * scale;
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([sourceImage CGImage], finalRect);
    UIImage *resultImage = [[[UIImage alloc] initWithCGImage:imageRef] autorelease];
    UIImage *finalImage = [self scaleImage:resultImage toSize:size];
    CGImageRelease(imageRef);
    
    return finalImage;
}

+ (UIImage *)renderImage:(UIImage *)sourceImage originalImage:(UIImage *)originalImage withView:(UIView *)view
{
    CGRect imageRect = CGRectMake(0, 0, sourceImage.size.width, sourceImage.size.height);
    UIImageView *imageView = [[[UIImageView alloc] initWithFrame:imageRect] autorelease];
    [imageView setBackgroundColor:view.backgroundColor];
    [imageView setContentMode:UIViewContentModeCenter];
    [imageView setImage:sourceImage];
    
    UIImageView *originalImageView = [[[UIImageView alloc] initWithFrame:imageRect] autorelease];
    [originalImageView setContentMode:UIViewContentModeCenter];
    [originalImageView setImage:originalImage];
    [originalImageView setAlpha:1.0-view.alpha];
    
    [imageView addSubview:originalImageView];
    
    UIGraphicsBeginImageContextWithOptions(sourceImage.size, FALSE, [[UIScreen mainScreen] scale]);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImage;
}

+ (UIImage *)resolveImageOrientations:(UIImage *)sourceImage
{
    CGImageRef imgRef = sourceImage.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orientations = sourceImage.imageOrientation;
    
    switch (orientations)
    {
        case UIImageOrientationUp:
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientations == UIImageOrientationRight || orientations == UIImageOrientationLeft)
    {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else
    {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();  
    
    return resultImage;
}

+ (UIImage *)rotateImage:(UIImage *)sourceImage andOrientation:(UIImageOrientation)orientation
{
    UIGraphicsBeginImageContext(sourceImage.size);
    CGContextRef context = (UIGraphicsGetCurrentContext());
	
    if (orientation == UIImageOrientationRight)
    {
        CGContextRotateCTM (context, 90/180*M_PI);
    }
    else if (orientation == UIImageOrientationLeft)
    {
        CGContextRotateCTM (context, -90/180*M_PI);
    }
    else if (orientation == UIImageOrientationUp)
    {
        CGContextRotateCTM (context, 90/180*M_PI);
    }
	
    [sourceImage drawAtPoint:CGPointMake(0, 0)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    return resultImage;
}

@end
