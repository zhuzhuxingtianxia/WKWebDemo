//
//  HomeController.m
//  WKWebDemo
//
//  Created by Jion on 2017/10/20.
//  Copyright © 2017年 Jion. All rights reserved.
//
#import <objc/runtime.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "HomeController.h"
#import "WKPregressWebView.h"
#import "MJRefresh.h"
@interface HomeController ()<WKNavigationDelegate,WKUIDelegate,WKHandlerDelegate>
@property(nonatomic,strong)WKPregressWebView *webWkView;
@end

@implementation HomeController
-(void)ocTojs{
    
    //调用js方法
    [self.webWkView evaluateJavaScript:@"changeColor()" completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
        NSLog(@"调用evaluateJavaScript异步获取：%@", obj);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"WK主页";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"调用js" style:UIBarButtonItemStylePlain target:self action:@selector(ocTojs)];
    [self changeWeb];
}

-(void)changeWeb{
    self.navigationItem.title = @"WK主页";
    [self buildWKwebView];
}

-(void)buildWKwebView{
    
    self.webWkView = [[WKPregressWebView alloc] initWKFrame:self.view.bounds];
    self.webWkView.navigationDelegate = self;
    self.webWkView.UIDelegate = self;
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
    NSString *pp = @"push://MyController/login/1?name=看是不是跳转";
    //div触发事件
    [self.webWkView addScriptElementId:@"eval_pic" methodName:@"outEvaluate" params:dic];
    //跳转按钮
    [self.webWkView addScriptElementId:@"button2" methodName:@"handleMothed2" params:pp];
    
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
- (void)userContent:(WKUserContentController *)userContent didReceiveScriptMessage:(WKScriptMessage *)message{
    if ([message.body isKindOfClass:[NSDictionary class]]) {
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
    }else if (message.body){
        NSURL *messageURL = [NSURL URLWithString:message.body];
        id createClass = [[NSClassFromString(messageURL.host) alloc] init];
        
        [self.navigationController pushViewController:createClass animated:YES];
        
    }
    
}

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

#pragma mark -- WKUIDelegate
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{

    NSLog(@"%@\n", NSStringFromSelector(_cmd));
    return nil;
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(nonnull void (^)(void))completionHandler{
    //js 里面的alert实现，如果不实现，网页的alert函数无效
   NSLog(@"%@\n", NSStringFromSelector(_cmd));
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    //  js 里面的alert实现，如果不实现，网页的alert函数无效  ,
   NSLog(@"%@\n", NSStringFromSelector(_cmd));
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler{
    //用于和JS交互，弹出输入框
   NSLog(@"%@\n", NSStringFromSelector(_cmd));
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)dealloc{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
