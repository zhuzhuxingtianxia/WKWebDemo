//
//  WKPregressWebView.h
//  WebViewDemo
//
//  Created by Jion on 2017/10/17.
//  Copyright © 2017年 天天. All rights reserved.
//

#import <WebKit/WebKit.h>
static NSString *const DAWebViewDemoScheme = @"darkangel";
static NSString *const DAWebViewDemoHostSmsLogin = @"smsLogin";
static NSString *const DAServerSessionCookieName = @"DarkAngelCookie";
static NSString *const DAUserDefaultsCookieStorageKey = @"DAUserDefaultsCookieStorageKey";
static NSString *const DAURLProtocolHandledKey = @"DAURLProtocolHandledKey";

@protocol WKHandlerDelegate <NSObject>
@required
//js回调代理
- (void)userContent:(WKUserContentController *)userContent didReceiveScriptMessage:(WKScriptMessage *)message;
@end

@interface WKPregressWebView : WKWebView
//初始化
-(instancetype)initWKFrame:(CGRect)frame;
-(instancetype)initWKWeb;

//回调代理
@property(nonatomic,weak)id <WKHandlerDelegate> handlerDelegate;
//设置消息名字
@property(nonatomic,strong)NSArray<NSString*> *handlerMessageNames;

//是否显示在导航条上，默认显示在导航条上YES。
@property(nonatomic,assign)BOOL  showNavbar;
//进度条颜色，默认safari进度条颜色
@property(nonatomic,strong)UIColor  *progressColor;
//是否隐藏进度条，默认NO
@property(nonatomic,assign)BOOL  hideProgress;

/*
 若不需要注册js代码，则可以不使用该方法
 elementId是网页内需要操作标签的id.
 methodName必须要包含在handlerMessageNames数组内,对应代理方法中的message.name
 params参数，对应代理方法中message.body
 */
- (void)addScriptElementId:(NSString*)elementId methodName:(NSString*)methodName params:(id)params;

@end
