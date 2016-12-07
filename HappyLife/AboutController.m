//
//  AboutController.m
//  HappyLife
//
//  Created by mac on 16/5/5.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "AboutController.h"

@interface AboutController ()

@end

@implementation AboutController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"关于我们";
    [self setDismissBarButton];
    NSString *Version=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.versionLab.text=[NSString stringWithFormat:@"当前系统版本号:%@",Version];
    self.iconBtn.layer.cornerRadius=10;
    self.iconBtn.layer.borderWidth=2;
    self.iconBtn.layer.borderColor=[UIColor orangeColor].CGColor;
}
@end
