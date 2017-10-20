//
//  TabBarController.m
//  WKWebDemo
//
//  Created by Jion on 2017/10/20.
//  Copyright © 2017年 Jion. All rights reserved.
//

#import "TabBarController.h"
#import "NavigationController.h"
@interface TabBarController ()

@end

@implementation TabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self setTabBarChildController];
    
}
- (void)setTabBarChildController{
    NSArray *titleArray = @[@"首页",@"我的"];
    NSArray *imageArray = @[@"tab_btn_home_default",@"sy_table_wdicon_wxz"];
    NSArray *imageSelectArray =@[@"tab_btn_home_selected",@"tab_btn_mypage_selected"];
    NSArray *classNames = @[@"HomeController", @"MyController"];
    
    for (int j=0;j<classNames.count;j++) {
        NSString *className = classNames[j];
        UIViewController *vc = [(UIViewController*)[NSClassFromString(className) alloc] init];
        
        vc.tabBarItem.image = [[UIImage imageNamed:imageArray[j]]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
        vc.tabBarItem.selectedImage = [[UIImage imageNamed:imageSelectArray[j]]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        vc.tabBarItem.title = titleArray[j];
        
        //设置tabbar的title的颜色，字体大小，阴影
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor lightGrayColor],NSForegroundColorAttributeName,[UIFont systemFontOfSize:10],NSFontAttributeName, nil];
        [vc.tabBarItem setTitleTextAttributes:dic forState:UIControlStateNormal];
        
        NSShadow *shad = [[NSShadow alloc] init];
        shad.shadowColor = [UIColor whiteColor];
        
        NSDictionary *selectDic = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:0/255.0 green:194/255.0 blue:79/255.0 alpha:1.0],NSForegroundColorAttributeName,shad,NSShadowAttributeName,[UIFont boldSystemFontOfSize:10],NSFontAttributeName, nil];
        [vc.tabBarItem setTitleTextAttributes:selectDic forState:UIControlStateSelected];
        NavigationController *navi = [[NavigationController alloc] initWithRootViewController:vc];
        
        [self addChildViewController:navi];
    }
    
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
