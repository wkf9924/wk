//
//  HelpViewController.m
//  HappyLife
//
//  Created by mac on 16/5/5.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"使用帮助";
    [self setDismissBarButton];
    NSString *str1=@"1.打开软件，前导页->登录(注册->登录)->首页。若是用户致歉登录无退出，软件开启直接进入首页。";
    NSString *str2=@"2.绑定燃气卡。燃气表管理->账户绑定->连接蓝牙->读卡->绑定";
    NSString *str3=@"3.用户充值。连接蓝牙->读卡->输气量或金额->选择支付方式支付.";
    NSString *str4=@"4.更换蓝牙设备。燃气表管理->更换蓝牙设备->搜索蓝牙->确定";
    NSString *str5=@"5.解除绑定。燃气表管理->长按已绑定的账户信息->解除绑定";
    NSString *str6=@"6.用气,购气纪录分别对用户用气情况和购气情况进行查询。";
    self.m_Textview.text=[NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@",str1,str2,str3,str4,str5,str6];
}

@end
