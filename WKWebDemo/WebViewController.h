//
//  WebViewController.h
//  WKWebDemo
//
//  Created by ZZJ on 2018/12/27.
//  Copyright © 2018 Jion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN
@protocol JSEventDelegate <NSObject,JSExport>
@required
-(void)jsMethodName:(NSString*)param;
@end

@interface WebViewController : UIViewController<JSEventDelegate>
@property(nonatomic,copy)NSString *urlString;
@end

NS_ASSUME_NONNULL_END
