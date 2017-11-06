# WKWebDemo

    WKWebView的使用

## WKWebView和UIWebView性能对比

    [![](https://github.com/zhuzhuxingtianxia/WKWebDemo/blob/master/web.png)]()
    [![](https://github.com/zhuzhuxingtianxia/WKWebDemo/blob/master/wk.png)]()

UIWebView加载后的内存占用</br>
![img](https://github.com/zhuzhuxingtianxia/WKWebDemo/blob/master/web.png)

WKWebView加载后内存占用和刷新加载时内存基本一致</br>
![img](https://github.com/zhuzhuxingtianxia/WKWebDemo/blob/master/wk.png)

 UIWebView刷新时内存占用</br>
 ![img](https://github.com/zhuzhuxingtianxia/WKWebDemo/blob/master/mjweb.png)

## KVO监听WKWebView的属性

    监听estimatedProgress属性，设置web加载进度条！

## 目标
### 拦截图片请求

    拦截图片请求为本地请求，实现图片资源缓存机制，节约流量消耗
  
### 缓存h5文档到本地

    根据场景设置缓存机制，对一些实时性要求不高的界面设置文档缓存

### gitread.me
- 小圆点 **文字加粗** `添加阴影`

```
分块处理

```
[添加链接]()
