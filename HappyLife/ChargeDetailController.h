//
//  ChargeDetailController.h
//  HappyLife
//
//  Created by mac on 16/5/11.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PayBtnselectBLock)(int tag);

@interface ChargeDetailController : UIView

@property(nonatomic,weak)IBOutlet UILabel   *nameLab;

@property(nonatomic,weak)IBOutlet UILabel   *carNumlab;

@property(nonatomic,weak)IBOutlet UILabel   *userAddresslab;

@property(nonatomic,weak)IBOutlet UILabel   *moneyCountlab;

@property(nonatomic,weak)IBOutlet UITextField   *buyGasCountLab;

@property(nonatomic,weak)IBOutlet UITextField *qiliangText;

//购气金额
@property(nonatomic,weak)IBOutlet UIButton     *gouqiLab;
//上标金额
@property(nonatomic,weak)IBOutlet UIButton     *shangbiaoBtn;
//补差金额
@property(nonatomic,weak)IBOutlet UIButton     *buchaBtn;

@property(nonatomic,copy)PayBtnselectBLock   payBlock;

-(IBAction)BtnSelectAction:(UIButton *)sender;

@end
