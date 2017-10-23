//
//  MyController.m
//  WKWebDemo
//
//  Created by Jion on 2017/10/20.
//  Copyright © 2017年 Jion. All rights reserved.
//

#import "MyController.h"
#import "MJRefresh.h"
#import "WKPregressWebView.h"

@interface MyController ()<WKNavigationDelegate,WKHandlerDelegate>
@property(nonatomic,strong)WKPregressWebView *webWkView;
@end

@implementation MyController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"个人中心";
    
    if (self.name) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.name message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:YES completion:^{
            
        }];
    }
    
    [self buildWKwebView];
}

-(void)buildWKwebView{
    
    self.webWkView = [[WKPregressWebView alloc] initWKFrame:self.view.bounds];
    self.webWkView.navigationDelegate = self;
    self.webWkView.handlerDelegate = self;
    _webWkView.progressColor = [UIColor redColor];
    [self.view addSubview:self.webWkView];
    self.webWkView.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadWKWeb)];
    
    
    [self loadWKWeb];
    
}

-(void)loadWKWeb{
    if (_urlString) {
        [self.webWkView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]]];
    }else{
        [self.webWkView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"demo" ofType:@"html"]]]];
    }
    
}

#pragma mark --WKHandlerDelegate
- (void)userContent:(WKUserContentController *)userContent didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"message.name == %@\n message.body === %@",message.name,message.body);
}

-(void)evaluateJavaScript{
    [self.webWkView evaluateJavaScript:@"document.cookie" completionHandler:^(id _Nullable cookies, NSError * _Nullable error) {
        NSLog(@"调用evaluateJavaScript异步获取cookie：%@", cookies);
    }];
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
            MyController *myvc = [[MyController alloc] init];
            myvc.urlString = requestURL.absoluteString;
            [self.navigationController pushViewController:myvc animated:YES];
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
    [self evaluateJavaScript];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
