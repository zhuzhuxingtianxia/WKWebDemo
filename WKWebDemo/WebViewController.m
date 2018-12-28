//
//  WebViewController.m
//  WKWebDemo
//
//  Created by ZZJ on 2018/12/27.
//  Copyright © 2018 Jion. All rights reserved.
//

#import "WebViewController.h"
#import "NJKWebViewProgress.h"
#import "NJKWebViewProgressView.h"
#import "MJRefresh.h"

@interface WebViewController ()<UIWebViewDelegate>
@property(nonatomic,strong)UIWebView  *webView;
@property (nonatomic,strong)NJKWebViewProgress *progressProxy;
@property (nonatomic,strong)NJKWebViewProgressView *progressView;
@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"Web主页";
    [self buildwebView];
}
-(void)buildwebView{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"调用js方法" style:UIBarButtonItemStylePlain target:self action:@selector(nativeTojs7)];
    [self.view addSubview:self.webView];
    
    _webView.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadWebView)];
    [self loadWebView];
}
-(void)loadWebView{
//    _urlString = @"https://app2.taocaimall.com:4114/taocaimall/inviteFriend.htm?sessionId=2518C5081DF476921A23654623680733&version=ios3.4.00";
    if (_urlString) {
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]]];
    }else{
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"webview" ofType:@"html"]]]];
    }
}

#pragma mark -- UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    [self jsToNative:webView];
    
    return YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [webView.scrollView.mj_header endRefreshing];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [webView.scrollView.mj_header endRefreshing];
}

#pragma mark --nativeTojs
// !!!:一、 调用js方法
-(void)nativeTojs{
    NSString *script = @"changeColor()";
    [self.webView stringByEvaluatingJavaScriptFromString:script];
}
// !!!:二、 获取当前页面的url
-(void)nativeTojs2{
    NSString *script = @"document.location.href";
   NSString *url = [self.webView stringByEvaluatingJavaScriptFromString:script];
    NSLog(@"url=%@",url);
}
// !!!:三、 获取页面title
-(void)nativeTojs3{
    NSString *script = @"document.title";
   NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:script];
    NSLog(@"title=%@",title);
    self.title = title;
}
// !!!:四、 修改界面元素的值
-(void)nativeTojs4{
    NSString *script = @"document.getElementsByClassName('myClass')[0].innerHTML='修改元素值';";
    //或
    script = @"document.getElementsByName('myName')[0].innerHTML='修改元素值';";
    //或
    script = @"document.getElementById('jsCore').innerHTML='修改元素值';";
    [self.webView stringByEvaluatingJavaScriptFromString:script];
}
// !!!:五、 表单提交
-(void)nativeTojs5{
    NSString *script = @"document.forms[0].submit();";
    [self.webView stringByEvaluatingJavaScriptFromString:script];
}
// !!!:六、 插入js代码
-(void)nativeTojs6{
    NSString *script = @"var script = document.createElement('script');"
    "script.type = 'text/javascript';"
    "script.text = \"function myFunction() { "
    "var field = document.getElementsByName('pp')[0];"
    "field.innerHTML='插入代码';"
    "}\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    
    [self.webView stringByEvaluatingJavaScriptFromString:script];
    //调用定义的方法
    [self.webView stringByEvaluatingJavaScriptFromString:@"myFunction();"];
}
// !!!:六、 插入js代码不执行，有h5点击执行
-(void)nativeTojs7{
    NSString *script = @"var script = document.createElement('script');"
    "script.type = 'text/javascript';"
    "script.text = \""
    "var field = document.getElementsByName('pp')[0];"
    "field.onclick = function() { "
    "var field = document.getElementsByName('pp')[0];"
    "field.innerHTML='插入代码';"
    "}\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    
    [self.webView stringByEvaluatingJavaScriptFromString:script];
    
}

#pragma mark --UIWebView
// !!!:第一种交互方式
-(void)jsToNative:(UIWebView *)webView {
    NSMutableDictionary *dicCore = [NSMutableDictionary dictionary];
    dicCore[@"jsMethodName"] = ^(JSValue *msg){
        NSString *jsonData = [msg toObject];
        NSData *data = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingMutableContainers) error:nil];
        [self performSelectorOnMainThread:@selector(jsAction:) withObject:[dic copy] waitUntilDone:NO];
    };
    JSContext *context  = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"jsCore"] = dicCore;
}

-(void)jsAction:(NSDictionary *)param{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:param[@"title"] message:param[@"message"] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alert show];
}

// FIXME:第二种交互方式:需头文件中声明协议
-(void)jsToNative2:(UIWebView *)webView {
    JSContext *context  = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    __weak typeof(self) weakSelf = self;
    context[@"jsCore"] = weakSelf;
}

#pragma mark -- JSEventDelegate
-(void)jsMethodName:(NSString*)param {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([param isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"xx" message:param delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
            [alert show];
        }
    });
}

#pragma mark -- geter
-(UIWebView*)webView{
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
        _webView.scalesPageToFit = YES;
        _webView.dataDetectorTypes = UIDataDetectorTypePhoneNumber;
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.mediaPlaybackRequiresUserAction = NO;
        _webView.allowsInlineMediaPlayback = YES;
        _progressProxy = [[NJKWebViewProgress alloc] init];
        _webView.delegate = _progressProxy;
        _progressProxy.webViewProxyDelegate = self;
        __weak typeof(self) weakSelf = self;
        _progressProxy.progressBlock = ^(float progress) {
            if (progress == NJKInitialProgressValue){
                
            }
            //加载本地的html显示不准确
            [weakSelf.progressView setProgress:progress animated:YES];
        };
    }
    
    return _webView;
}
-(NJKWebViewProgressView*)progressView{
    if (!_progressView) {
        
        CGFloat progressBarHeight = 2.f;
        CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
        CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
        _progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
        [_progressView setProgress:0 animated:YES];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _progressView.progressBarView.backgroundColor = [UIColor redColor];
        [self.navigationController.navigationBar addSubview:_progressView];
        
    }
    return _progressView;
}

@end
