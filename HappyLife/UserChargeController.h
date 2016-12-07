//
//  UserChargeController.h
//  HappyLife
//
//  Created by mac on 16/4/11.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CommonCrypto/CommonDigest.h"
#import "UPPaymentControl.h"

@interface UserChargeController : UIViewController<ServiceHelperDelegate>
{
    NSMutableArray *parserObjects;
}
@property(nonatomic,weak)IBOutlet UILabel   *carNumLab;

@property(nonatomic,weak)IBOutlet UILabel   *AddressLab;

@property(nonatomic,weak)IBOutlet UILabel   *BlueToothLab;

@property(nonatomic,strong)ServiceHelper    *helper;

@property(nonatomic,assign)int      hank;

@property(nonatomic,copy)NSString           *Danjia;
//微信支付参数
@property(nonatomic,copy)NSString           *WeChatnonceStr;
@property(nonatomic,copy)NSString           *WeChatSign;
@property(nonatomic,copy)NSString           *PreayId;

@property (nonatomic,assign)BOOL            AlreadyBanding;


//strKahao（卡号） + strPay （金额）+ "1" （单价）+ strCapacity（气量）+ c（购气次数）+OrderN（订单号）+"民用"（用户类型）+"卡类型"+strSBiaoje（上表金额）+strBChaje（补差金额）+"$"+danjia+"$"+danjia2+"$"+danjia3+"$"+danjia4+"$"+danjia5+"$"+danjia6+"$"+Sg1+"$"+Sg2+"$"+Sg3+"$"+Sg4+"$"+Sg5+"$"+Sg6+"$"+Sm1+"$"+Sm2+"$"+Sm3+"$"+Sm4+"$"+Sm5+"$"+Sm6;
@property (nonatomic,copy)NSString          *ChargeStr;  //支付

@property (nonatomic,copy)NSString          *tradeNo;    //支付订单号

@property (nonatomic,copy)NSString          *payMetohd;  //支付方式

//上表strAll[8];
//补差strAll[9]
//danjia=strAll[17];
//danjia2=strAll[18];
//danjia3=strAll[19];
//danjia4=strAll[20];
//danjia5=strAll[21];
//danjia6=strAll[22];
//
//Sg1=strAll[2];
//Sg2=strAll[3];
//Sg3=strAll[4];
//Sg4=strAll[10];
//Sg5=strAll[11];
//Sg6=strAll[12];
//
//Sm1=strAll[5];
//Sm2=strAll[6];
//Sm3=strAll[7];
//Sm4=strAll[13];
//Sm5=strAll[14];
//Sm6=strAll[15];

//private String danjia="1", danjia2="0",danjia3="0",danjia4="0",danjia5="0",danjia6="0",Sg1="0",Sg2="0",Sg3="0",Sg4="0",Sg5="0",
//Sg6="0",Sm1="0",Sm2="0",Sm3="0",Sm4="0",Sm5="0",Sm6="0",strSBiaoje="0",strBChaje="0";

@property (nonatomic,strong)NSMutableArray   *DataArr;  //存放ComGas接口里面下发的字段

@property (nonatomic,copy)  NSString         *gouqicishu;

@property (nonatomic,copy)  NSString         *readCarFuwei;

@property (nonatomic,strong)NSMutableArray   *ReadArr;

@property (nonatomic,assign)BOOL             ifMovieElse;   //视频卡里面走else的部分


-(IBAction)readCardAction:(id)sender;

@end
