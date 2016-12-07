//
//  SettingController.m
//  HappyLife
//
//  Created by mac on 16/3/20.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "SettingController.h"
#import "OptionController.h"

@interface SettingController ()

@end

@implementation SettingController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"设置";
    [self setDismissBarButton];
}

-(IBAction)aboutOurSelf:(id)sender
{

}

-(IBAction)Advise:(id)sender
{
    [self.navigationController pushViewController:[[OptionController alloc] init] animated:YES];
}

-(IBAction)Help:(id)sender
{

}

-(IBAction)CheckVersion:(id)sender
{
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:@[] methodName:@"Version"];
    [_helper asynServiceMethod:@"Version" SoapMessage:soapMsg Tag:100];
}

-(IBAction)Exit:(id)sender
{
    [[Config Instance] isBlueToothConnect:@"0"];
    [UIApplication sharedApplication].keyWindow.rootViewController=[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LogInViewController"];
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    NSString *version=xml[@"VersionResponse"][@"VersionResult"][@"text"];
    NSString *title=[NSString stringWithFormat:@"当前版本号:%@",version];
    SB_SHOW_Time_HIDE(title, self.view, 1);
}

- (void)dealloc
{
    CANCEL_REQUEST
}


@end
