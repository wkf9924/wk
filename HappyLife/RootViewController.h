//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.

//  Copyright © 2016年 mac. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface AdScrollview : UIScrollView

-(void)showMoreImage:(NSArray *)arr;

@end



@interface RootViewController : UIViewController<ServiceHelperDelegate>
{
    IBOutlet    AdScrollview   *ad_scrollview;
    NSMutableArray             *BlueArr;            //获取到当前绑定的卡号
    BOOL                       isBanding;          //是否绑定，当未绑定时候界面按钮点击提示请绑定卡
    IBOutlet    UITextView     *m_text;
    NSString                   *urlStr;         
}
@property (nonatomic,strong)ServiceHelper              *helper;
-(IBAction)Recharge:(id)sender;
-(IBAction)GasQuery:(id)sender;
-(IBAction)BuygasRecord:(id)sender;
-(IBAction)GasManage:(id)sender;

@end
