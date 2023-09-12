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

@interface MyController ()<WKNavigationDelegate,WKUIDelegate,WKHandlerDelegate>
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
    self.webWkView.UIDelegate = self;
    self.webWkView.handlerDelegate = self;
    self.webWkView.showNavbar = YES;
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
//    NSString *script = [NSString stringWithFormat:@"%@('%@')",@"(function(s){ window.Unity = {}; setTimeout(function(){ alert('Hello from JavaScript!')},3000)})",@""];
//    [self.webWkView evaluateJavaScript:script completionHandler:^(id _Nullable cookies, NSError * _Nullable error) {
//        NSLog(@"调用evaluateJavaScript异步获取");
//    }];
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
