//
//  MsgView.m
//  HappyLife
//
//  Created by mac on 16/3/26.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "MsgView.h"

@implementation MsgView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self=[[NSBundle mainBundle] loadNibNamed:@"MsgView" owner:self options:nil][0];
    }
    return self;
}

-(void)setLabeltitle:(NSDictionary *)dic
{
    self.nameLab.text=configEmpty(dic[@"name1"][@"text"]);
    self.numLab.text=configEmpty(dic[@"kahao1"][@"text"]);
    self.addressLab.text=configEmpty(dic[@"address1"][@"text"]);
    NSLog(@"--%@--%@--%@",self.nameLab.text,self.numLab.text,self.addressLab.text);
}


@end
