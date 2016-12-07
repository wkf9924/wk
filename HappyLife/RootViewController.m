//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//


#import "RootViewController.h"
#import "LocationController.h"
#import "GasQueryController.h"
#import "UserChargeController.h"
#import "PurchaseGasController.h"
#import "GasManageController.h"
#import "LeftViewController.h"
#import "ChargeController.h"

@implementation AdScrollview

-(void)drawRect:(CGRect)rect
{
    self.backgroundColor=[UIColor whiteColor];
    self.showsHorizontalScrollIndicator=NO;
    self.showsVerticalScrollIndicator=NO;
    self.pagingEnabled=YES;
}

-(void)showMoreImage:(NSArray *)arr
{
    for (int i=0; i<arr.count; i++)
    {
        UIImageView *img=[[UIImageView alloc] initWithFrame:CGRectMake(i*winsize.width, 0, winsize.width, self.frame.size.height)];
        img.image=[UIImage imageNamed:arr[i]];
        [self addSubview:img];
    }
    self.contentSize=CGSizeMake(winsize.width*arr.count, 0);
}

@end


@interface RootViewController ()
{
    UIButton *cityBtn;
}
@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"生活易";
//    self.navigationController.navigationBar.barTintColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"navBar"]];
//    self.navigationController.navigationBar.translucent=NO;
//    [self.navigationController.navigationBar setTitleTextAttributes:
//     @{NSFontAttributeName:[UIFont systemFontOfSize:18],
//       NSForegroundColorAttributeName:[UIColor grayColor]}];
    
    BlueArr=[NSMutableArray array];
    isBanding=YES;
    
//    cityBtn = [KDXEasyTouchButton buttonWithType:UIButtonTypeCustom];
//    cityBtn.frame = CGRectMake(0, 0, 80, 20);
//    [cityBtn setTitle:@"西安" forState:UIControlStateNormal];
//    [cityBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
//    [cityBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
//    cityBtn.titleLabel.font = [UIFont systemFontOfSize:14];
//    [cityBtn addTarget:self action:@selector(getlocation) forControlEvents:UIControlEventTouchUpInside];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cityBtn];
    
    
    // 轻扫手势
    UISwipeGestureRecognizer *leftswipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftswipeGestureAction:)];
    
    // 设置清扫手势支持的方向
    leftswipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    
    // 添加手势
    [self.view addGestureRecognizer:leftswipeGesture];
    
    UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightswipeGestureAction:)];
    
    rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self.view addGestureRecognizer:rightSwipeGesture];
    [ad_scrollview showMoreImage:@[@"logo1",@"logo2"]];
}

-(void)viewWillAppear:(BOOL)animated
{
   [super viewWillAppear:YES];
   [self judjueifbanding];
}

-(void)judjueifbanding
{
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[Config Instance] getPhoneAndPass][@"phone"],@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"IsBunding1"];
    [_helper asynServiceMethod:@"IsBunding1" SoapMessage:soapMsg Tag:100];
}

-(void)getlocation
{
    LocationController *locationVc=[[LocationController alloc] init];
    locationVc.postLocation=^(NSString *city)
    {
        [cityBtn setTitle:city forState:UIControlStateNormal];
    };
    locationVc.currentCity=cityBtn.titleLabel.text;
    [self.navigationController pushViewController:locationVc animated:YES];
}

-(IBAction)Recharge:(id)sender
{
    [self.navigationController pushViewController:[[UserChargeController alloc] init] animated:YES];
}

-(IBAction)GasQuery:(id)sender
{
    if (!isBanding)
    {
        return;
    }
    GasQueryController *gasQuery=[[GasQueryController alloc] init];
    [self.navigationController pushViewController:gasQuery animated:YES];
}

-(IBAction)BuygasRecord:(id)sender
{
    if (!isBanding)
    {
        return;
    }
    PurchaseGasController *PurGas=[[PurchaseGasController alloc] init];
    [self.navigationController pushViewController:PurGas animated:YES];
}
-(IBAction)GasManage:(id)sender
{
    GasManageController *manage=[[GasManageController alloc] init];
    [self.navigationController pushViewController:manage animated:YES];
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==100)
    {
        [BlueArr removeAllObjects];
        NSString * strObj=xml[@"IsBunding1Response"][@"IsBunding1Result"][@"text"];
        NSArray *ResultArr=[strObj componentsSeparatedByString:@"|"];
        
        if ([ResultArr[0] isEqualToString:@"0"])
        {
            [UIAlertView showAlertViewWithTitle:@"网络异常" message:nil];
        }
        
        else if ([ResultArr[0] isEqualToString:@"1"])
        {
            isBanding=YES;
            [[Config Instance] judjeIfBlueToothisBanging:@{@"state":@"1",@"num":ResultArr[2]}];
        }
        
        else if ([ResultArr[0] isEqualToString:@"2"])
        {
            
            [[Config Instance] judjeIfBlueToothisBanging:@{@"state":@"1",@"num":ResultArr[1]}];
        }
        else if ([ResultArr[0] isEqualToString:@"3"])
        {
            [[Config Instance] judjeIfBlueToothisBanging:@{@"state":@"0",@"num":ResultArr[1]}];
        }
        
        if ([ResultArr[0] isEqualToString:@"3"]|[ResultArr[0] isEqualToString:@"2"])
        {
            isBanding=NO;
            KDXAlertView *alert=[[KDXAlertView alloc] initWithTitle:@"您当前还未绑定，是否前去绑定?" message:nil cancelButtonTitle:@"确定" cancelBlock:^
                                 {
                                     [self GasManage:nil];
                                 }];
            
            [alert addButtonWithTitle:@"取消" actionBlock:^{
            }];
            [alert show];
        }
        
        //广告位展示接口
        _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[Config Instance] getPhoneAndPass][@"phone"],@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:@[] methodName:@"Advert"];
        [_helper asynServiceMethod:@"Advert" SoapMessage:soapMsg Tag:200];
    }
    else if (request.tag==200)
    {
        NSArray *strArr=[configEmpty(xml[@"AdvertResponse"][@"AdvertResult"][@"text"]) componentsSeparatedByString:@"$"];
        NSString *str;
        NSMutableString *textStr=[[NSMutableString alloc] init];
        if (strArr.count>=2)
        {
            urlStr=configEmpty(strArr[1]);
            str=strArr[0];
            NSArray *newArr=[str componentsSeparatedByString:@"|"];
            for (NSString *str in newArr)
            {
                [textStr appendString:[NSString stringWithFormat:@"%@\n",str]];
            }
            m_text.text=textStr;
        }
    }
}

-(void)finishFailRequest:(NSError*)error
{
     NSLog(@"异步请发生失败:%@\n",[error description]);
     SB_MBPHUD_HIDE(@"请检查网络", 3)
}

-(IBAction)BtnSelectAction:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
}

/**
 *  左轻扫
 */
- (void)leftswipeGestureAction:(UISwipeGestureRecognizer *)sender
{
    UINavigationController *centerNC = self.navigationController;
    LeftViewController *leftVC  = self.navigationController.parentViewController.childViewControllers[0];
    [UIView animateWithDuration:0.5 animations:^{
        
        if ( centerNC.view.center.x != self.view.center.x ) {
            leftVC.view.frame = CGRectMake(0, 0, 250, [UIScreen mainScreen].bounds.size.height);
            centerNC.view.frame = [UIScreen mainScreen].bounds;
            return;
        }
    }];
}

/**
 *  右轻扫
 */
- (void)rightswipeGestureAction:(UISwipeGestureRecognizer *)sender
{
    UINavigationController *centerNC = self.navigationController;
    
    [UIView animateWithDuration:0.5 animations:^{
        if ( centerNC.view.center.x == self.view.center.x )
        {
            centerNC.view.frame = CGRectMake(250, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        }
    }];
    
}

- (void)dealloc
{
    NSLog(@"-CANCEL_REQUEST");
    CANCEL_REQUEST;
}

@end


