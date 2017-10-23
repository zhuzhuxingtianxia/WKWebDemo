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
    
    [_config.userContentController removeAllUserScripts];
    for (NSString *messageName in self.handlerMessageNames) {
        [_config.userContentController removeScriptMessageHandlerForName:messageName];
    }
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
    
    NSString *jstest = [NSString stringWithFormat:
                        @"var element = document.getElementById('%@');"                                               "element.onclick = function(param){"
                                      "%@(%@);"
                            "};"
                        "function %@(param){"
                               "window.webkit.messageHandlers.%@.postMessage(param);"
                        "};",elementId,methodName,params,methodName,methodName];
    
    WKUserScript *JSScript = [[WKUserScript alloc] initWithSource:jstest injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
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

#pragma mark -- setter
-(void)setHandlerMessageNames:(NSArray<NSString *> *)handlerMessageNames{
    for (NSString *messageName in handlerMessageNames) {
        [_config.userContentController addScriptMessageHandler:self name:messageName];
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
