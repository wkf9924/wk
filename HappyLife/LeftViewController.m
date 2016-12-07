//
//  LeftViewController.m
//  HappyLife
//
//  Created by mac on 16/3/28.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "LeftViewController.h"
#import "MenuCell.h"
#import "SettingController.h"
#import "OptionController.h"
#import "AboutController.h"
#import "HelpViewController.h"
#import "ProtectController.h"

@interface LeftViewController ()

@end

@implementation LeftViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColorFromRGB(0x323232);
//    @"version"
    self.items = @[@"ours",@"opinion",@"help",@"protection"];
    NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
    self.phoneLab.text=[NSString stringWithFormat:@"用户名: %@",logerDic[@"phone"]];
    self.versionLab.text=[NSString stringWithFormat:@"版本号: %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}


#pragma -mark tableView Delegates

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_items count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==0)
    {
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[[AboutController alloc] init]] animated:YES completion:nil];
    }
    else if (indexPath.row==1)
    {
        OptionController *optionVc=[[OptionController alloc] init];
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:optionVc] animated:YES completion:nil];
    }
    else if (indexPath.row==2)
    {
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[[HelpViewController alloc] init]] animated:YES completion:nil];
    }
    else if (indexPath.row==3)
    {
        //账号保护
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[[ProtectController alloc] init]] animated:YES completion:nil];
    }
    else if (indexPath.row==4)
    {
        NSString *version=[NSString stringWithFormat:@"当前版本号:%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
        SB_SHOW_Time_HIDE(version, self.view, 1);
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.myTableView registerNib:[UINib nibWithNibName:@"MenuCell" bundle:nil] forCellReuseIdentifier:@"MenuCell"];
    MenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    cell.icon.image = [UIImage imageNamed:[self.items objectAtIndex:indexPath.row]];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;
    return cell;
}

-(IBAction)ExitAction:(id)sender
{
    NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
    helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@",logerDic[@"phone"]],@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"ExitLoginLog"];
    [helper asynServiceMethod:@"ExitLoginLog" SoapMessage:soapMsg Tag:200];

    [UIApplication sharedApplication].keyWindow.rootViewController=[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LogInViewController"];
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==200)
    {
        
    }
}

-(void)finishFailRequest:(NSError*)error
{
    NSLog(@"异步请发生失败:%@\n",[error description]);
    SB_MBPHUD_HIDE(@"请检查网络", 3)
}

- (void)dealloc
{
    CANCEL_REQUEST
}



@end
