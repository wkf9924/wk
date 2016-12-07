//
//  PurchaseGasController.h
//  HappyLife
//
//  Created by mac on 16/3/24.
//  Copyright © 2016年 mac. All rights reserved.
//



#import <UIKit/UIKit.h>

@interface PurchaseGasController : UIViewController<UITableViewDataSource,UITableViewDelegate,ServiceHelperDelegate,UserDatePickerDelegate>

@property(nonatomic,weak)IBOutlet UITableView   *bigTableView;

@property(nonatomic,weak)IBOutlet UIButton      *startBtn;

@property(nonatomic,weak)IBOutlet UIButton      *endBtn;

@property(nonatomic,strong)ServiceHelper        *helper;

//所绑定的帐号
@property(nonatomic,strong)NSMutableArray       *CarNumArr;

@end
