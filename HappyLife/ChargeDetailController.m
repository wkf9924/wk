//
//  ChargeDetailController.m
//  HappyLife
//
//  Created by mac on 16/5/11.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "ChargeDetailController.h"

@implementation ChargeDetailController

-(IBAction)BtnSelectAction:(UIButton *)sender
{
    if (self.payBlock)
    {
        self.payBlock((int)sender.tag);
    }
}

@end
