//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "ChildController.h"

@interface ChildController ()

@end

@implementation ChildController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor redColor];
}

- (id)initWithCenterVC:(RootViewController *)centerV CleftVC:(LeftViewController *)leftVC
{
    if (self = [super init]) {
        [self addChildViewController:leftVC];
        
        UINavigationController *centerNC = [[UINavigationController alloc] initWithRootViewController:centerV];
        [self addChildViewController:centerNC];
        
        
        leftVC.view.frame = CGRectMake(0, 0, 250, [UIScreen mainScreen].bounds.size.height);
        
        centerNC.view.frame = [UIScreen mainScreen].bounds;
        
        [self.view addSubview:leftVC.view];
        [self.view addSubview:centerNC.view];
        
        KDXEasyTouchButton *button = [KDXEasyTouchButton buttonWithType:UIButtonTypeCustom];
        button.frame=CGRectMake(0, 13, 30, 30);
        [button setImage:[UIImage imageNamed:@"info"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(leftAction:) forControlEvents:UIControlEventTouchUpInside];
        centerV.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    return self;
}

- (void)leftAction:(UIBarButtonItem *)sender {
    
    UINavigationController *centerNC = self.childViewControllers.lastObject;
    LeftViewController *leftVC = self.childViewControllers.firstObject;
    [UIView animateWithDuration:0.5 animations:^{
    if ( centerNC.view.center.x != self.view.center.x )
    {
            leftVC.view.frame = CGRectMake(0, 0, 250, [UIScreen mainScreen].bounds.size.height);
            centerNC.view.frame = [UIScreen mainScreen].bounds;
            return;
    }{
        
            centerNC.view.frame = CGRectMake(250, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        }
    }];
}

- (void)dealloc
{
    CANCEL_REQUEST
}

@end
