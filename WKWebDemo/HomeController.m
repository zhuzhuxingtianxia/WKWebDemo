//
//  HomeController.m
//  WKWebDemo
//
//  Created by Jion on 2017/10/20.
//  Copyright © 2017年 Jion. All rights reserved.
//
#import <objc/runtime.h>
#import "HomeController.h"
#import "WKPregressWebView.h"
#import "MJRefresh.h"
@interface HomeController ()<WKNavigationDelegate,WKHandlerDelegate,UIWebViewDelegate>
@property(nonatomic,strong)WKPregressWebView *webWkView;
@property(nonatomic,strong)UIWebView  *webview;
@end

@implementation HomeController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"WK主页";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"切换web" style:UIBarButtonItemStylePlain target:self action:@selector(changeWeb)];
    [self buildWKwebView];
}

-(void)changeWeb{
    static BOOL change = YES;
    if (change) {
        _webWkView = nil;
        self.navigationItem.title = @"Web主页";
        [self buildwebView];
        change = NO;
    }else{
        _webview = nil;
        self.navigationItem.title = @"WK主页";
       [self buildWKwebView];
        change = YES;
    }
}

-(void)buildwebView{
    _webview = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webview.delegate = self;
    [self.view addSubview:_webview];
    
    _webview.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadWebView)];
    [self loadWebView];
}

-(void)loadWebView{
    if (_urlString) {
        [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]]];
    }else{
        [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"demo" ofType:@"html"]]]];
    }
}

-(void)buildWKwebView{
    
    self.webWkView = [[WKPregressWebView alloc] initWKFrame:self.view.bounds];
    self.webWkView.navigationDelegate = self;
    self.webWkView.handlerDelegate = self;
    _webWkView.progressColor = [UIColor redColor];
    [self.view addSubview:self.webWkView];
    self.webWkView.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadWKWeb)];
    
    self.webWkView.handlerMessageNames = @[@"handleMothed1",@"handleMothed2",@"outEvaluate"];
    
    NSDictionary *dic = @{@"className":@"MyController",
                          @"login":[NSNumber numberWithBool:NO],
                          @"param":@{
                                     @"name":@"看是不是跳转"
                                     }};
    //div触发事件
    [self.webWkView addScriptElementId:@"eval_pic" methodName:@"outEvaluate" params:dic];
    //跳转按钮
    [self.webWkView addScriptElementId:@"button2" methodName:@"handleMothed2" params:dic];
    
    [self loadWKWeb];
    
}

-(void)loadWKWeb{
    if (_urlString) {
        [self.webWkView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]]];
    }else{
       [self.webWkView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"demo" ofType:@"html"]]]];
    }
    
    
}

#pragma mark - WKHandler
-(BOOL)pushToClass:(id)vc parm:(id)parm{
    if (!vc) {
        return NO;
    }
    if ([parm isKindOfClass:[NSDictionary class]]) {
        
        unsigned int propertyCount = 0;
        objc_property_t *propertys = class_copyPropertyList([vc class], &propertyCount);
        NSMutableArray *propertyArray = [NSMutableArray arrayWithCapacity:propertyCount];
        for (int i = 0; i < propertyCount; i ++) {
            ///取出属性
            objc_property_t property = propertys[i];
            
            const char * propertyName = property_getName(property);
            NSString  *propertyString = [NSString stringWithUTF8String:propertyName];
            [propertyArray addObject:propertyString];
        }
        
        NSDictionary *dict = (NSDictionary*)parm;
        //这个判断存在风险，不能获取到父类属性
        NSMutableSet *set = [[NSMutableSet alloc] initWithArray:propertyArray];
        [set addObjectsFromArray:dict.allKeys];
        if ([dict.allKeys containsObject:@"title"] && set.count >propertyArray.count+1) {
            return NO;
        }else if (![dict.allKeys containsObject:@"title"] && set.count>propertyArray.count) {
            return NO;
        }
        
        for (NSInteger k=0; k<dict.allKeys.count; k++) {
            NSString *key = dict.allKeys[k];
            id vaule = dict.allValues[k];
            if ([propertyArray containsObject:key]) {
                [vc setValue:vaule forKey:key];
            }
            
        }
        
    }
    
    return YES;
}

- (void)userContent:(WKUserContentController *)userContent didReceiveScriptMessage:(WKScriptMessage *)message{
    if (message.body) {
        if ([message.body[@"login"] boolValue]) {
            if([message.body[@"login"] boolValue]){
                
                //如果没有登录先跳转到一个登录的界面中去
                
            }else{
                if (message.body[@"className"]) {
                    id createClass = [[NSClassFromString(message.body[@"className"]) alloc] init];
                    BOOL ispush = [self pushToClass:createClass parm:message.body[@"param"]];
                    if (createClass && ispush) {
                        [self.navigationController pushViewController:createClass animated:YES];
                    }
                    
                    
                }
                
            }
        }else{
            if (message.body[@"className"]) {
                id createClass = [[NSClassFromString(message.body[@"className"]) alloc] init];
                [self pushToClass:createClass parm:message.body[@"param"]];
                [self.navigationController pushViewController:createClass animated:YES];
                
            }
        }
    }
    
}

#pragma mark -- WKNavigationDelegate
// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    NSURL *requestURL = navigationAction.request.URL;
    NSLog(@"=========1\n requestURL = %@",requestURL);
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if ([requestURL.path isEqualToString: [NSURL URLWithString:_urlString].path]) {
            decisionHandler(WKNavigationActionPolicyAllow);
        }else if ([requestURL.scheme isEqualToString:@"tel"]){
            NSString *resourceSpecifier = [requestURL resourceSpecifier];
            NSString *callPhone = [NSString stringWithFormat:@"tel://%@", resourceSpecifier];
            if (@available(iOS 10.0,*)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:callPhone] options:@{} completionHandler:^(BOOL success) {
                    
                }];
                
            }else{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:callPhone]];
            }
            
            decisionHandler(WKNavigationActionPolicyAllow); //允许
            
        }else{
            HomeController *home = [[HomeController alloc] init];
            home.urlString = requestURL.absoluteString;
            [self.navigationController pushViewController:home animated:YES];
            //不允许
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        
    }else{
        decisionHandler(WKNavigationActionPolicyAllow); //允许
    }
    
}
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
    NSLog(@"=======2");
}
// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    
    NSLog(@"=====3");
    decisionHandler(WKNavigationResponsePolicyAllow);
}
//当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
    NSLog(@"======4");
    //navigationAction.request.URL.host
    
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"========5");
    [webView.scrollView.mj_header endRefreshing];
}

//页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"=====6fail");
    [webView.scrollView.mj_header endRefreshing];
}

// 接收到服务器跳转请求之后再执行
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"======7");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark --
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [webView.scrollView.mj_header endRefreshing];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [webView.scrollView.mj_header endRefreshing];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
