//
//  GasQueryController.h
//  HappyLife
//
//  Created by mac on 16/3/20.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^BtnSelectBlockHandle)(NSInteger section);

@interface HeaderView : UIView

@property(nonatomic,weak)IBOutlet UIImageView   *leftImg;

@property(nonatomic,assign)NSInteger            section;

@property(nonatomic,strong) IBOutlet UILabel      *carNum;

@property(nonatomic,strong) IBOutlet UILabel      *NumLab;

@property(nonatomic,copy)  BtnSelectBlockHandle btnSelectblock;

-(IBAction)BtnSelect:(id)sender;

@end



@interface GasQueryController : UIViewController<UITableViewDataSource,UITableViewDelegate,ServiceHelperDelegate,UserDatePickerDelegate>

@property(nonatomic,weak)IBOutlet UITableView   *bigTableView;

@property(nonatomic,weak)IBOutlet UIButton      *startBtn;

@property(nonatomic,weak)IBOutlet UIButton      *endBtn;

@property(nonatomic,strong)ServiceHelper        *helper;

//所绑定的帐号
@property(nonatomic,strong)NSMutableArray       *CarNumArr;

@end
