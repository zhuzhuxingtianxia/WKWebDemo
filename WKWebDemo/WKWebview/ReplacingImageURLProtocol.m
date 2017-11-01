//
//  ReplacingImageURLProtocol.m
//  NSURLProtocol+WebKitSupport
//
//  Created by yeatse on 2016/10/11.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "ReplacingImageURLProtocol.h"
#import "SDWebImageManager.h"
#import <UIKit/UIKit.h>

static NSString* const FilteredKey = @"FilteredKey";

@implementation ReplacingImageURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (request.URL.scheme) {
        
        NSString* extension = request.URL.pathExtension;
        BOOL isImage = [@[@"png", @"jpeg", @"gif", @"jpg"] indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [extension compare:obj options:NSCaseInsensitiveSearch] == NSOrderedSame;
        }] != NSNotFound;
        return [NSURLProtocol propertyForKey:FilteredKey inRequest:request] == nil && isImage;
    }else{
        return NO;
    }
    
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest* request = self.request.mutableCopy;
    [NSURLProtocol setProperty:@YES forKey:FilteredKey inRequest:request];
    
    [self zj_setImageWithURL:request.URL placeholderImage:[self imageWithColor:[UIColor groupTableViewBackgroundColor] andSize:CGSizeMake(10, 10)]];
    //[self replceResponse:nil];
}

- (void)stopLoading {
    
}
- (void)zj_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder{
    if (url) {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager loadImageWithURL:url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            
            [manager saveImageToCache:image forURL:url];
            [self replceResponse:image];
            
        }];
        
    }else{
        [self replceResponse:placeholder];
    }
    
}

-(void)replceResponse:(UIImage*)placeholder{
    placeholder = placeholder ?: [self imageWithColor:[UIColor groupTableViewBackgroundColor] andSize:CGSizeMake(10, 10)];
    NSData* data = UIImagePNGRepresentation(placeholder);
    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"image/png" expectedContentLength:data.length textEncodingName:nil];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size {
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
