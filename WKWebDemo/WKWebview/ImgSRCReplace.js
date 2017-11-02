
document.addEventListener('DOMContentLoaded',function(){
                          jsEventHandler();
                          },false);

var jsEventHandler = function (event) {
    //alert("ok");
    

}
//获取所有img标签
var imgs = document.getElementsByTagName("img");

for (var i = 0; i < imgs.length; i++){
    
    var img = imgs[i];
    
    //如果图片链接存在
    if (img.src || img.getAttribute('data-src')) {
        
        var imgUrl = img.src ? img.src : img.getAttribute('data-src');
    
        /*
        var callBack = function (localUrl){
            img.src = localUrl;
        }
        h5ImageSrcReplace({imgUrl:imgUrl,
                          callBack:callBack
                          });
        */
        h5ImageSrcReplace({imgUrl:imgUrl,
                          index:i
                          });
    }
    
}

function callBackReplace(localUrl,index) {
    var img = imgs[index];
    
    //在此执行回调
    img.src = localUrl;
    // console.log("打印日志记录" + localUrl);
    //window.alert(localUrl ? localUrl : "nothing");
    
}

function h5ImageSrcReplace (info){
   // var callBack = info.callBack;
    
   // info.callBack = callBack.toString();
    //WKWebView使用
    window.webkit.messageHandlers.imageSrcReplace.postMessage(info);
}
