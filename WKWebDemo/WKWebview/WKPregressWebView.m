//
//  WKPregressWebView.m
//  WebViewDemo
//
//  Created by Jion on 2017/10/17.
//  Copyright © 2017年 天天. All rights reserved.
//

#import "WKPregressWebView.h"
@interface ZJProgressView : UIView
@property (nonatomic) float progress;
@property(nonatomic,strong)UIColor  *progressColor;
@property (nonatomic) UIView *progressBarView;
@property (nonatomic) NSTimeInterval barAnimationDuration; // default 0.1
@property (nonatomic) NSTimeInterval fadeAnimationDuration; // default 0.27
@property (nonatomic) NSTimeInterval fadeOutDelay; // default 0.1

- (void)setProgress:(float)progress animated:(BOOL)animated;

@end

@implementation ZJProgressView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureViews];
    }
    return self;
}

-(void)configureViews{
    self.userInteractionEnabled = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressBarView = [[UIView alloc] initWithFrame:self.bounds];
    _progressBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    UIColor *tintColor = [UIColor colorWithRed:22.f / 255.f green:126.f / 255.f blue:251.f / 255.f alpha:1.0]; // iOS7 Safari bar color
    if ([UIApplication.sharedApplication.delegate.window respondsToSelector:@selector(setTintColor:)] && UIApplication.sharedApplication.delegate.window.tintColor) {
        tintColor = UIApplication.sharedApplication.delegate.window.tintColor;
    }
    _progressBarView.backgroundColor = tintColor;
    [self addSubview:_progressBarView];
    
    _barAnimationDuration = 0.27f;
    _fadeAnimationDuration = 0.27f;
    _fadeOutDelay = 0.1f;
}

-(void)setProgress:(float)progress{
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(float)progress animated:(BOOL)animated{
    BOOL isGrowing = progress > 0.0;
    [UIView animateWithDuration:(isGrowing && animated) ? _barAnimationDuration : 0.0 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = _progressBarView.frame;
        frame.size.width = progress * self.bounds.size.width;
        _progressBarView.frame = frame;
    } completion:nil];
    
    if (progress >= 1.0) {
        [UIView animateWithDuration:animated ? _fadeAnimationDuration : 0.0 delay:_fadeOutDelay options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _progressBarView.alpha = 0.0;
        } completion:^(BOOL completed){
            CGRect frame = _progressBarView.frame;
            frame.size.width = 0;
            _progressBarView.frame = frame;
        }];
    }
    else {
        [UIView animateWithDuration:animated ? _fadeAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _progressBarView.alpha = 1.0;
        } completion:nil];
    }
}

-(void)setProgressColor:(UIColor *)progressColor{
    if (progressColor) {
        _progressBarView.backgroundColor = progressColor;
    }
}

@end

//防止循环强引用问题
@interface WeakScriptMessageDelegate : NSObject<WKScriptMessageHandler>

@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end

@implementation WeakScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate{
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}
- (void)dealloc{
   // NSLog(@"%s",__func__);
}

@end


@interface WKPregressWebView ()<WKScriptMessageHandler>
@property(nonatomic,strong)ZJProgressView *progressView;
@property(nonatomic,strong)WKWebViewConfiguration *config;
@end
@implementation WKPregressWebView

-(instancetype)initWKFrame:(CGRect)frame{
    self = [super initWithFrame:frame configuration:self.config];
    if (self) {
        [self setup];
    }
    return self;
}

-(instancetype)initWKWeb{
    self = [super initWithFrame:CGRectZero configuration:self.config];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup{
    self.showNavbar = YES;
    
    //比如我在这个时候保存了Cookie
    [self saveCookie];
    
    [self addListen];
    //是否允许右滑返回上个链接，左滑前进
    self.allowsBackForwardNavigationGestures = NO;
    //是否允许3D Touch
    //self.allowsLinkPreview = YES;
}

-(void)addListen{
    [self addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:NULL];
}

-(void)dealloc{
    [self removeObserver:self forKeyPath:@"title"];
    [self removeObserver:self forKeyPath:@"estimatedProgress"];
    [self removeObserver:self forKeyPath:@"loading"];
    
    for (NSString *messageName in self.handlerMessageNames) {
        [_config.userContentController removeScriptMessageHandlerForName:messageName];
    }
    [_config.userContentController removeAllUserScripts];
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self) {
        if ([keyPath isEqualToString:@"estimatedProgress"] && !self.hideProgress) {
            id objcVC;
            if (self.handlerDelegate) {
                objcVC = self.handlerDelegate;
            }else{
                objcVC = self.navigationDelegate;
            }
            if (_showNavbar) {
                if ([objcVC isKindOfClass:[UIViewController class]] && !self.progressView.superview) {
                    UIViewController *vc = (UIViewController*)objcVC;
                    CGFloat progressBarHeight = 2.f;
                    CGRect navigationBarBounds = vc.navigationController.navigationBar.bounds;
                    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
                    self.progressView.frame = barFrame;
                    
                    [vc.navigationController.navigationBar addSubview:_progressView];
                }
            }else {
                if(!self.progressView.superview){
                    CGFloat progressBarHeight = 2.f;
                    CGRect barFrame = CGRectZero;
                    if (self.frame.origin.y == 0 && ((UIViewController*)objcVC).navigationController.navigationBar.hidden == NO) {
                        CGFloat statusBarH = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
                        CGSize navSize = ((UIViewController*)objcVC).navigationController.navigationBar.bounds.size;
                        barFrame = CGRectMake(0, statusBarH+navSize.height, navSize.width, progressBarHeight);
                    }else{
                       barFrame = CGRectMake(0, 0, self.bounds.size.width, progressBarHeight);
                    }
                    
                    if (self.translatesAutoresizingMaskIntoConstraints == NO) {
                        [self layoutIfNeeded];
                    }
                    self.progressView.frame = barFrame;
                    
                    [self addSubview:_progressView];
                }
                
            }
            
            if (self.progressColor) {
                self.progressView.progressColor = self.progressColor;
            }
            [self.progressView setAlpha:1.0f];
            [self.progressView setProgress:self.estimatedProgress animated:YES];
            if(self.estimatedProgress >= 1.0f) {
                [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [self.progressView setAlpha:0.0f];
                    
                } completion:^(BOOL finished) {
                    [self.progressView setProgress:0.0f animated:NO];
                    
                }];
                
            }
        }else if ([keyPath isEqualToString:@"loading"]){
            if (self.loading) {
                //正在加载
                
            }else{
              //加载完成
            }
        }else if ([keyPath isEqualToString:@"title"]){
            id objcVC;
            if (self.handlerDelegate) {
                objcVC = self.handlerDelegate;
            }else{
                objcVC = self.navigationDelegate;
            }
            
            if ([objcVC isKindOfClass:[UIViewController class]]) {
                UIViewController *vc = (UIViewController*)self.handlerDelegate;
                if (vc.tabBarController && !vc.tabBarController.tabBar.hidden) {
                    vc.navigationItem.title = self.title;
                }else if (vc.navigationController && !vc.title) {
                    vc.title = self.title;
                }
            }
            
        }
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        
    }
    
}

- (void)addScriptElementId:(NSString*)elementId methodName:(NSString*)methodName params:(id)params{
    
    params = [self paramsTransformation:params];
    
    NSString *jsCode = [NSString stringWithFormat:
                        @"var element = document.getElementById('%@');"                                               "element.onclick = function(param){"
                                      "%@(%@);"
                            "};"
                        "function %@(param){"
                               "window.webkit.messageHandlers.%@.postMessage(param);"
                        "};",elementId,methodName,params,methodName,methodName];
    
    //可添加一个字典容器，在loading加载完成后，判断该元素是否存在，若存在则注入脚本
    WKUserScript *JSScript = [[WKUserScript alloc] initWithSource:jsCode injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [self.configuration.userContentController addUserScript:JSScript];
    
}

-(NSString*)paramsTransformation:(id)param{
    if (param) {
        if([NSJSONSerialization isValidJSONObject:param]){
            NSError *error = nil;
            NSData *JSONData = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:&error];
            param = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
        }else{
            param = @"";
            NSLog(@"无效JSON对象");
        }
    }else{
        param = @"";
    }
    
    return param;
    
}

#pragma mark -- WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    if ([self.handlerDelegate respondsToSelector:@selector(userContent:didReceiveScriptMessage:)]) {
        [self.handlerDelegate userContent:userContentController didReceiveScriptMessage:message];
    }
}

#pragma mark -- Cookie
//比如你在登录成功时，保存Cookie
- (void)saveCookie{
    /*
     //如果从已有的地方保存Cookie，比如登录成功
     NSArray *allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
     for (NSHTTPCookie *cookie in allCookies) {
     if ([cookie.name isEqualToString:DAServerSessionCookieName]) {
     NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:DAUserDefaultsCookieStorageKey];
     if (dict) {
     NSHTTPCookie *localCookie = [NSHTTPCookie cookieWithProperties:dict];
     if (![cookie.value isEqual:localCookie.value]) {
     NSLog(@"本地Cookie有更新");
     }
     }
     [[NSUserDefaults standardUserDefaults] setObject:cookie.properties forKey:DAUserDefaultsCookieStorageKey];
     [[NSUserDefaults standardUserDefaults] synchronize];
     break;
     }
     }
     */
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:@{
                                                                NSHTTPCookieName: DAServerSessionCookieName,
                                                                NSHTTPCookieValue: @"1314521",
                                                                NSHTTPCookieDomain: @".baidu.com",
                                                                NSHTTPCookiePath: @"/"
                                                                }];
    [[NSUserDefaults standardUserDefaults] setObject:cookie.properties forKey:DAUserDefaultsCookieStorageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 修复打开链接Cookie丢失问题
 
 @param request 请求
 @return 一个fixedRequest
 */
- (NSURLRequest *)fixRequest:(NSURLRequest *)request{
    NSMutableURLRequest *fixedRequest;
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        fixedRequest = (NSMutableURLRequest *)request;
    } else {
        fixedRequest = request.mutableCopy;
    }
    //防止Cookie丢失
    NSDictionary *dict = [NSHTTPCookie requestHeaderFieldsWithCookies:[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies];
    if (dict.count) {
        NSMutableDictionary *mDict = request.allHTTPHeaderFields.mutableCopy;
        [mDict setValuesForKeysWithDictionary:dict];
        fixedRequest.allHTTPHeaderFields = mDict;
    }
    return fixedRequest;
}

- (NSString *)cookieString{
    NSMutableString *script = [NSMutableString string];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        // Skip cookies that will break our script
        if ([cookie.value rangeOfString:@"'"].location != NSNotFound) {
            continue;
        }
        // Create a line that appends this cookie to the web view's document's cookies
        NSString *string = [NSString stringWithFormat:@"%@=%@;domain=%@;path=%@",
                            cookie.name,
                            cookie.value,
                            cookie.domain,
                            cookie.path ?: @"/"];
        if (cookie.secure) {
            string = [string stringByAppendingString:@";secure=true"];
        }
        [script appendFormat:@"document.cookie='%@'; \n", string];
    }
    return script;
}

#pragma mark -- setter
-(void)setHandlerMessageNames:(NSArray<NSString *> *)handlerMessageNames{
    _handlerMessageNames = handlerMessageNames;
    for (NSString *messageName in _handlerMessageNames) {
        
        [_config.userContentController addScriptMessageHandler:[[WeakScriptMessageDelegate alloc] initWithDelegate:self] name:messageName];
    }
}

#pragma mark -- getter
-(WKWebViewConfiguration*)config {
    if (!_config) {
        _config = [[WKWebViewConfiguration alloc] init];
        _config.userContentController = [[WKUserContentController alloc]init];
        WKPreferences *preferences = [WKPreferences new];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        _config.preferences = preferences;
    }
    return _config;
}

-(ZJProgressView*)progressView{
    if (!_progressView) {
        _progressView = [[ZJProgressView alloc] init];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
    }
    return _progressView;
}


@end
