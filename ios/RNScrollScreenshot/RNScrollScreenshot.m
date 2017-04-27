//
//  RNScrollScreenshot.m
//  RNScrollScreenshot
//
//  Created by wangzixiao on 16/12/14.
//  Copyright © 2016年 WangZiXiao. All rights reserved.
//

#import "RNScrollScreenshot.h"
#import "RCTConvert.h"
#import "RCTBridge.h"
#import "RCTView.h"
#import "RCTUIManager.h"
#import  <QuartzCore/QuartzCore.h>

@implementation RNScrollScreenshot

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCTResponseSenderBlock _callback;

- (void) screenshotCurrent:(UIView *)view{
    
    // defaults: snapshot the same size as the view, with alpha transparency, with current device's scale factor
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0.0);
    
    [view drawViewHierarchyInRect:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height) afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    [self saveImage:image];
}

- (void) screenshot:(UIScrollView *)scrollView{
    
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat screenHeight = scrollView.bounds.size.height;
    
    NSInteger until = (int)( ceil( contentHeight / screenHeight ) );
    
    CGPoint savedContentOffset = scrollView.contentOffset;
    CGRect savedFrame = scrollView.frame;
    
    @autoreleasepool {
        
        NSMutableArray *imageList = [NSMutableArray arrayWithCapacity:until];
        UIImage *firstImage;
        
        scrollView.contentOffset = CGPointZero;
        for (NSInteger index = 0; index < until; index++){
            
            CGFloat offsetVirtical = ((CGFloat)index ) * screenHeight;
            [scrollView setContentOffset:CGPointMake(0, offsetVirtical ) animated:NO];
            
            UIGraphicsBeginImageContextWithOptions(scrollView.contentSize, NO, 0.0);
            CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, -offsetVirtical);
            [scrollView.layer renderInContext: UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            if (image != nil) {
                CGImageRef imageRef = [image CGImage];
                CGImageRef tempImage = CGImageCreateWithImageInRect(imageRef, CGRectMake(0,0,scrollView.frame.size.width*image.scale, scrollView.frame.size.height*image.scale));
                image = [UIImage imageWithCGImage:tempImage];
                CGImageRelease(tempImage);
                
                if( index == 0 ){
                    firstImage = image;
                }
                
                [imageList addObject:image];
                [NSThread sleepForTimeInterval:0.1];
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(scrollView.contentSize.width*[UIScreen mainScreen].scale, scrollView.contentSize.height*[UIScreen mainScreen].scale) , NO, firstImage.scale);
        NSInteger index = 0;
        for (UIImage __weak *image in imageList)
        {
            [image drawInRect:CGRectMake(0, (image.size.height*index),image.size.width, image.size.height)];
            index++;
        }
        
        UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [self saveImage:finalImage];
        imageList = nil;
    }
    
    [scrollView setContentOffset:savedContentOffset animated:NO];
    scrollView.frame = savedFrame;
}

- (void) saveImage:(UIImage *)imageToSave {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath =  [paths objectAtIndex:0];
    NSString *currentTime = [self getCurrentTime];
    int rendom = arc4random() % 100;
    
    NSString *filePath = [basePath stringByAppendingString:[NSString stringWithFormat:@"/%@%d.jpg", currentTime,rendom]];
    NSError *error;
    
    NSData *data = UIImageJPEGRepresentation(imageToSave, 0.5);
    
    BOOL writeSucceeded = [data writeToFile:filePath options:0 error:&error];
    if (!writeSucceeded) {
        NSLog( @"error occured to save in document" );
        imageToSave = nil;
    } else {
        NSLog( @"saved in document %@", filePath );
        _callback(@[[NSNull null], filePath]);
    }
    
}

- (UIScrollView *) findUIScrollView:(UIView *) view{
    UIScrollView *result = nil;
    
    if ([view isKindOfClass:[UIScrollView class]]) {
        result = (UIScrollView *)view;
    } else if ([view isKindOfClass:[UIWebView class]]){
        result = ((UIWebView *)view).scrollView;
    }
    
    if( result != nil ){
        return result;
    }
    
    for (UIView *subview in view.subviews){
        result = [self findUIScrollView:subview];
        if( result != nil ){
            break;
        }
    }
    
    return result;
}

RCT_EXPORT_METHOD(takeScreenshot:(nonnull NSNumber *)reactTag
                  callback:(RCTResponseSenderBlock)callback)
{
    _callback = callback;
    
    UIView *view = [self.bridge.uiManager viewForReactTag:reactTag];
    UIScrollView *scrollView = [self findUIScrollView:view];
    if( scrollView != nil ){
        [self screenshot:scrollView];
    } else {
        [self screenshotCurrent:view];
    }
}

-(NSString*)getCurrentTime {
    
    NSDateFormatter*formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyMMddHHmmss"];
    
    NSString*dateTime = [formatter stringFromDate:[NSDate date]];
    
    return dateTime;
}

@end
