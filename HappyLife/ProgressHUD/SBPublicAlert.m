//
//  SBPublicAlert.m
//
//  Created by xie xianhui on 13-6-23.
//  Copyright (c) 2013年 xie xianhui. All rights reserved.
//

#import "SBPublicAlert.h"

@implementation SBPublicAlert

static MBProgressHUD *loadingView = nil;

#pragma mark 获取提示框单例
+ (MBProgressHUD *)getMBProgress
{
    return loadingView;
}

#pragma mark 显示提示框　　states为YES代表没有活动指示器　　　为NO代表有活动指示器
+ (void)showMBProgressHUD:(NSString *)showMessage andWhereView:(UIView *)view states:(BOOL)states
{
    if (loadingView!=nil) {
        [MBProgressHUD hideHUDForView:view animated:NO];
    }
    loadingView = [MBProgressHUD showHUDAddedTo:view animated:YES];
    loadingView.labelText = showMessage;
    //states 为YES  不出活动指示器
    if (states) {
        loadingView.customView = [[UIImageView alloc] initWithImage:nil];
        loadingView.mode = MBProgressHUDModeCustomView;
    }
}

#pragma mark 显示提示框　　只显示文字， theTime后消失
+ (void)showMBProgressHUD:(NSString *)showMessage andWhereView:(UIView *)view hiddenTime:(CGFloat)theTime
{
   ;
    if (loadingView!=nil) {
        [MBProgressHUD hideHUDForView:view animated:NO];
    }
    [view bringSubviewToFront:loadingView];
    loadingView = [MBProgressHUD showHUDAddedTo:view animated:YES];
    loadingView.labelText = showMessage;
    //states 为YES  不出活动指示器
    loadingView.customView = [[UIImageView alloc] initWithImage:nil];
    loadingView.mode = MBProgressHUDModeCustomView;
    [loadingView performSelector:@selector(hide:) withObject:nil afterDelay:theTime];
}

#pragma mark 更换提示框的文字  isSuccess为YES代表成功，显示成功的图片　　为NO则相反
+ (void)hideYESMBprogressHUDcontent:(NSString *)showMessage isSuccess:(int)states//1:成功  2:请求成功但没有数据3:请求超时
{
    UIView *supView=[loadingView superview];
    [supView bringSubviewToFront:loadingView];

    if (states==1) { //对号
        loadingView.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark@2x.png"]];
    }else if (states==2) { //感叹号
        loadingView.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"提示.png"]];

    }else if (states==3) { //叉叉
        loadingView.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-False@2x.png"]];

    }
    loadingView.mode = MBProgressHUDModeCustomView;
    loadingView.labelText = showMessage;
    [loadingView performSelector:@selector(hide:) withObject:nil afterDelay:1];

}

#pragma mark 隐藏提示框
+ (void)hideMBprogressHUD:(UIView *)view
{
    [MBProgressHUD hideHUDForView:view animated:YES];
    loadingView = nil;
}

#pragma mark 提示系统的alert
+ (void)showAlertTitle:(NSString*)title Message:(NSString *)showMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:showMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark 返回一个alert对象 系统的alert 设置delegate，title，message，btn 只传两个一个确定一个取消
+ (UIAlertView *)showWithReturnAlertTitle:(NSString *)theTitleStr
                                  Message:(NSString *)theMessageStr
                                 delegate:(id)delegate
                                      tag:(NSInteger)tag
                             cancelButton:(NSString *)theCancelBtnStr
                         sureButtonTitles:(NSString *)theSureBtnStr
{
    UIAlertView *alert = [[UIAlertView alloc]
                           initWithTitle:theTitleStr
                           message:theMessageStr
                           delegate:delegate
                           cancelButtonTitle:theCancelBtnStr
                           otherButtonTitles:theSureBtnStr, nil];
    alert.tag = tag;
    [alert show];
    return alert;
}

//系统的alert 设置delegate，title，message，btn  只传两个一个确定一个取消
+ (void)showAlertTitle:(NSString *)theTitleStr
               Message:(NSString *)theMessageStr
              delegate:(id)delegate
                   tag:(NSInteger)tag
          cancelButton:(NSString *)theCancelBtnStr
      sureButtonTitles:(NSString *)theSureBtnStr
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:theTitleStr
                          message:theMessageStr
                          delegate:delegate
                          cancelButtonTitle:theCancelBtnStr
                          otherButtonTitles:theSureBtnStr, nil];
    alert.tag = tag;
    [alert show];
}

#pragma mark 返回一个alert对象 系统的alert 设置delegate，title，message，btn  可以传多个按钮
+ (UIAlertView *)showWithReturnAlertTitle:(NSString *)theTitleStr
                                  Message:(NSString *)theMessageStr
                                 delegate:(id)delegate
                                      tag:(NSInteger)tag
                             cancelButton:(NSString *)theCancelBtnStr
                        otherButtonTitles:(NSArray *)theOtherBtnArr
{
    UIAlertView *alert = [[UIAlertView alloc]
                           initWithTitle:theTitleStr
                           message:theMessageStr
                           delegate:delegate
                           cancelButtonTitle:theCancelBtnStr
                           otherButtonTitles:nil, nil];
    alert.tag = tag;
    for (int i = 0; i < [theOtherBtnArr count]; ++i) {
        [alert addButtonWithTitle:[theOtherBtnArr objectAtIndex:i]];
    }
    [alert show];
    return alert;
}

#pragma mark 系统的alert 设置delegate，title，message，btn 可以传多个按钮
+ (void)showAlertTitle:(NSString *)theTitleStr
               Message:(NSString *)theMessageStr
              delegate:(id)delegate
                   tag:(NSInteger)tag
          cancelButton:(NSString *)theCancelBtnStr
     otherButtonTitles:(NSArray *)theOtherBtnArr
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:theTitleStr
                          message:theMessageStr
                          delegate:delegate
                          cancelButtonTitle:theCancelBtnStr
                          otherButtonTitles:nil, nil];
    alert.tag = tag;
    for (int i = 0; i < [theOtherBtnArr count]; ++i) {
        [alert addButtonWithTitle:[theOtherBtnArr objectAtIndex:i]];
    }
    [alert show];
}


@end
