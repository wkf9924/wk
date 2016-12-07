//
//  UIViewController+ViewControllerGeneralMethod.m
//  Golf
//
//  Created by Blankwonder on 6/4/13.
//  Copyright (c) 2013 Suixing Tech. All rights reserved.
//

#import "UIViewController+GeneralMethod.h"
#import "KDXEasyTouchButton.h"

@implementation UIViewController (GeneralMethod)

- (void)popViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)setBackBarButton
{
    UIButton *button = [KDXEasyTouchButton buttonWithType:UIButtonTypeCustom];
    button.frame=CGRectMake(0, 5, 30, 30);
    [button setImage:[UIImage imageNamed:@"back@3x"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(popViewController) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)setDismissBarButton
{
    UIButton *button = [KDXEasyTouchButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 5, 30, 30);
    [button setImage:[UIImage imageNamed:@"back@3x"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"back@3x"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(dismissViewController) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)setDoneBarButtonWithSelector:(SEL)selector andTitle:(NSString *)title{
    UIButton *button = [KDXEasyTouchButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 45, 24);
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    button.titleLabel.font = [UIFont systemFontOfSize:18];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

//刷新按钮
- (void)setRefreshBarButtonWithSelector:(SEL)selector andTitle:(NSString *)title{
    UIButton *button = [KDXEasyTouchButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 30, 30);
    [button setBackgroundImage:[UIImage imageNamed:@"refresh"] forState:0];
    [button setTitle:title forState:UIControlStateNormal];
//    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
//    button.titleLabel.font = [UIFont systemFontOfSize:18];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}


@end
