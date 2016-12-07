//
//  UserChargeController.m
//  HappyLife
//
//  Created by mac on 16/4/11.
//  Copyright © 2016年 mac. All rights reserved.
#import "AsyncSocket.h"
#import "UserChargeController.h"
#import "NearByModal.h"
#import "ChargeDetailController.h"
#import "WriteCardView.h"
#import "DataSigner.h"
#import "DataVerifier.h"
#import "Order.h"
#import "PartnerConfig.h"
#import <AlipaySDK/AlipaySDK.h>
#import "WechatAuthSDK.h"
#import "WXApi.h"
#import "WXApiObject.h"

#define ScanTimeInterval 1.0


#define POSTNUMURL      @"www.prmt.cn"

#define WX_API_KEY      @"Prmtzal0q1xsw2nko9cde3bji8vf4g5h"

@interface UserChargeController ()<CBCentralManagerDelegate,ZSYPopoverListDelegate,ZSYPopoverListDatasource,CBPeripheralDelegate,AsyncSocketDelegate,WXApiDelegate,NSXMLParserDelegate>

@property (nonatomic,strong)ChargeDetailController  *chargeDetailView;

@property (nonatomic,strong)WriteCardView    *writeView;

//被连接蓝牙设备在数组中的位置
@property (nonatomic, assign) NSInteger        MacPosition;
// 中央设备
@property (nonatomic, strong) CBCentralManager *mgr;
// 外部设备
@property (nonatomic, strong) NSMutableArray *peripherals;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic,strong)ZSYPopoverListView *m_Tableview;

@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;

@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;

//uuid为2A29的特征
@property (nonatomic,strong)  CBCharacteristic *A29Characteristric;

//当前请求
@property (nonatomic,copy)  NSString              *identify;

//卡上公用区22个数据
@property (nonatomic,copy)  NSMutableString       *DNSdataStr;

//socket请求服务器
@property (nonatomic,strong)AsyncSocket           *socket;

//从服务器读卡的数据
@property (nonatomic,copy)  NSString              *DNSResult;

//从服务器获取卡上气量[金额]和卡号
@property (nonatomic,copy)  NSString              *DNSResult2;

//向服务器写卡返回的数据
@property (nonatomic,copy)  NSString              *DNSResult3;

//获取卡上气量[金额]和卡号时后台需要的数据的数组（根据下标取）
@property (nonatomic,strong)NSMutableArray         *DnsDataArr;

//暂时存储单次从服务器拿去的数据
@property (nonatomic,copy)NSMutableString         *litterString;

//是否是102卡
@property (nonatomic,assign)    BOOL               is102Card;

@property (nonatomic,copy)     NSString             *WriteOrRead;

@property (nonatomic,copy)      NSString            *carNum;    //卡号
@property (nonatomic,copy)      NSString            *name;      //用户名
@property (nonatomic,copy)      NSString            *Useraddress;//地址
@property (nonatomic,copy)      NSString            *macAddress; //MAC地址
@property (nonatomic,assign)    int                 CarType;     //carType
@property (nonatomic,copy)      NSString            *jinEstr;    //金额

@property (nonatomic,strong)    UIButton            *rightBtB;

@property (nonatomic,copy)     NSString              *CarTypeStr;

@property (nonatomic,copy)     NSMutableString       *ShipinStr;//写00b000002A命令时候拼接的字符串



@end

@implementation UserChargeController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"用户充值";
    [self setBackBarButton];
    [self setRightBarBtnItem];
    NSString *state=[[Config Instance] getBandingStatus][@"state"];
    self.AlreadyBanding=[state intValue]==1?YES:NO;
    BOOL toolState=[[Config Instance] getBlutToothConnectState];
//    if (self.AlreadyBanding)
//    {
//        [self startSearch];
//    }
    
    if (!toolState)
    {
        [self startSearch];
    }
    else
    {
        _discoveredPeripheral=[CentralManager Instance].discoveredPeripheral;
        _writeCharacteristic=[CentralManager Instance].writeCharacteristic;
        _A29Characteristric=[CentralManager Instance].A29Characteristric;
        
        [_discoveredPeripheral setDelegate:self];
        [_discoveredPeripheral discoverServices:nil];
    }
    
    _m_Tableview=[[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 270, 200)];
    _m_Tableview.titleName.text=@"搜索到的设备";
    _m_Tableview.delegate=self;
    _m_Tableview.datasource=self;
    [_m_Tableview dismiss];

    _DnsDataArr=[NSMutableArray array];
    _litterString=[[NSMutableString alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yinlianPayResult:) name:@"yinlianPay" object:nil];
    self.DataArr=[[NSMutableArray alloc] init];
    [self.DataArr addObjectsFromArray:@[@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"1",@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0"]];
    _is102Card=NO;
    
    //检测是否装了微信软件
    if ([WXApi isWXAppInstalled])
    {
        //监听通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOrderPayResult:) name:@"WXPay" object:nil];
    }
}

#pragma mark - 事件
- (void)getOrderPayResult:(NSNotification *)notification
{
    NSLog(@"userInfo: %@",notification.userInfo);

    if ([notification.object isEqualToString:@"1"])
    {
        _payMetohd=@"微信支付";
        [self ChargeSuccessful];
        [UIAlertView showAlertViewWithTitle:@"支付成功" message:nil];
    }
    else
    {
        [UIAlertView showAlertViewWithTitle:@"支付失败" message:nil];
    }
}


-(void)setRightBarBtnItem
{
    self.rightBtB = [KDXEasyTouchButton buttonWithType:UIButtonTypeCustom];
    self.rightBtB.frame = CGRectMake(0, 0, 45, 24);
    [self.rightBtB setTitle:@"搜索" forState:UIControlStateNormal];
    [self.rightBtB setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.rightBtB setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    self.rightBtB.titleLabel.font = [UIFont systemFontOfSize:18];
    [self.rightBtB addTarget:self action:@selector(SearchBlueTooth) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBtB];
}

-(IBAction)readCardAction:(UIButton *)sender
{
    if (_is102Card)
    {
        SB_SHOW_Time_HIDE(@"读卡中..", self.view, 15);
        _identify=@"选择卡类型";
        NSString *writeStr=@"02010003";
        [self writeChar:writeStr];
    }

    else
    {
        SB_SHOW_Time_HIDE(@"读卡中..", self.view, 15);
        _identify=@"选择卡类型";
        NSString *writeStr=@"010203";
        [self writeChar:writeStr];
    }
}

-(void)SearchBlueTooth
{
    [self startSearch];
}

#pragma 蓝牙功能实现
- (CBCentralManager *)mgr{
    if (_mgr == nil) {
        _mgr = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    }
    return _mgr;
}

- (NSMutableArray *)peripherals{
    if (_peripherals == nil) {
        _peripherals = [[NSMutableArray alloc]init];
    }
    return _peripherals;
}

- (void)startSearch
{
    [self.peripherals removeAllObjects];
    if (!_AlreadyBanding)
    {
        SB_MBPHUD_SHOW(@"搜索中...", self.m_Tableview, NO);
        [self.m_Tableview show];
    }
    else
    {
        SB_MBPHUD_SHOW(@"搜索中...", self.view, NO);
    }
    
    if (_timer == nil)
    {
        _timer = [NSTimer timerWithTimeInterval:ScanTimeInterval target:self selector:@selector(scanForPeripherals) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    if (_timer && !_timer.valid)
    {
        [_timer fire];
    }
}

- (void)stopScanss{
    if (_timer && _timer.valid) {
        [_timer invalidate];
        _timer = nil;
    }
    [self.mgr stopScan];
}

- (void)scanForPeripherals{
    if (self.mgr.state == CBCentralManagerStateUnsupported) {//设备不支持蓝牙
    }else
    {
        if (self.mgr.state == CBCentralManagerStatePoweredOn)
        {
            [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
            SB_HUD_HIDE;
            [self.mgr scanForPeripheralsWithServices:nil options:nil];
        }
    }
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"%s",__func__);
    switch ((long)central.state)
    {
        case 0:
            NSLog(@"蓝牙状态未知");
            [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
            break;
        case 1:
            NSLog(@"正在重置蓝牙状态");
            [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
            break;
        case 2:
            NSLog(@"该设备不支持蓝牙4.0");
            [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
            break;
        case 3:
            NSLog(@"该设备未授权");
            [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
            break;
        case 4:
            NSLog(@"蓝牙状态关闭");
            [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
            break;
        case 5:
            NSLog(@"蓝牙设备正常，可以使用");
            break;
        default:
            break;
    }
}

// 发现外部设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
    BOOL isExist = NO;
    if (peripheral.name.length>0&&[advertisementData.allKeys containsObject:@"kCBAdvDataManufacturerData"])
    {
        // 添加外部设备
        NearByModal *modal = [[NearByModal alloc]init];
        NSString *strs=[configEmpty(advertisementData[@"kCBAdvDataManufacturerData"]) description];
        NSMutableString *macAddress=[[NSMutableString alloc] initWithString:[strs substringWithRange:NSMakeRange(5, strs.length-6)]];
        [macAddress replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, macAddress.length)];
        
        NSMutableString *str=[[NSMutableString alloc] init];
        const char *chars=[macAddress UTF8String];
        for (int i=0; i<macAddress.length; i++)
        {
            char ch=toupper(chars[i]);
            [str appendString:[NSString stringWithFormat:@"%c",ch]];
            if ((i%2!=0&&i!=0)&&i!=macAddress.length-1)
            {
                [str appendString:@":"];
            }
        }
        modal.name = [NSString stringWithFormat:@"%@(%@)",peripheral.name,str];
        modal.macAddress=str;
        modal.RSSI = [NSString stringWithFormat:@"%@",RSSI];
        NSString *temp = [NSString stringWithFormat:@"%@",peripheral.identifier];
        modal.UUID = [temp substringFromIndex:31];
        modal.Peripheral = peripheral;
        if (self.peripherals.count == 0)
        {
            [self.peripherals addObject:modal];
            NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.m_Tableview.mainPopoverListView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
        }else
        {
            for (int i = 0;i < self.peripherals.count;i++)
            {
                NearByModal *nearModal = [self.peripherals objectAtIndex:i];
                if ([nearModal.UUID isEqualToString:modal.UUID])
                {
                    isExist = YES;
                }
            }
            if (!isExist)
            {
                [self.peripherals addObject:modal];
                NSIndexPath *path = [NSIndexPath indexPathForRow:self.peripherals.count - 1 inSection:0];
                [self.m_Tableview.mainPopoverListView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        if (!_AlreadyBanding)
        {
            [_m_Tableview.mainPopoverListView reloadData];
        }
        else
        {
            NSString *macAddress=[[Config Instance] getBandingStatus][@"num"];
            if ([modal.macAddress isEqualToString:macAddress])
            {
                NearByModal *modals = modal;
                _MacPosition=self.peripherals.count - 1;
                [self stopScanss];
                SB_MBPHUD_SHOW(@"开始连接", self.view, NO);
                
                if (self.mgr.state == CBCentralManagerStateUnsupported) {//设备不支持蓝牙
                    SB_HUD_HIDE;
                }else{
                    if (self.mgr.state == CBCentralManagerStatePoweredOn)
                    {
                        [self.mgr connectPeripheral:modals.Peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,CBConnectPeripheralOptionNotifyOnNotificationKey:@YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES}];
                    }else
                    {
                        [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
                    }
                }
                
            }
        }
        NSLog(@"peripheral--%@ advertisementData--%@    RSSI--%@",peripheral,advertisementData,RSSI);
    }
}

// 连接到外设
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    SB_MBPHUD_HIDE(@"连接成功", 1);
    [[Config Instance] isBlueToothConnect:@"1"];
    //判断此设备是否绑定如果没有绑定则继续
    NSString *Str = [NSString stringWithFormat:@"%@",peripheral];
    NSLog(@"----Str=%@",Str);
    NearByModal *modal = self.peripherals[_MacPosition];
//    self.BlueToothLab.text=modal.macAddress;
    self.carNumLab.text=@"****";
    self.AddressLab.text=@"****";
    self.BlueToothLab.text=@"****";
    self.macAddress=modal.macAddress;
    [[Config Instance] saveBluetoothNo:modal.macAddress];
    [self.m_Tableview dismiss];
    _discoveredPeripheral=peripheral;
    [CentralManager Instance].discoveredPeripheral=_discoveredPeripheral;
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    NSLog(@"连接外设失败 %@",peripheral);
    SB_MBPHUD_HIDE(@"设备连接失败！", 3);
}

//  跟某个外设失去连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"---已失去连接 %@",peripheral);
    [[Config Instance] isBlueToothConnect:@"0"];
    SB_MBPHUD_HIDE(@"与外部设备失去连接!", 3);
}

//获取服务后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"搜索服务%@时发生错误:%@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *s in peripheral.services)
    {
        NSLog(@"Service found with UUID : %@", s);
        [s.peripheral discoverCharacteristics:nil forService:s];
    }
}

//获取特征后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"搜索特征%@时发生错误:%@", service.UUID, [error localizedDescription]);
        return;
    }
    
    NSLog(@"---服务的uuid=%@",service.UUID);
    for (CBCharacteristic *c in service.characteristics)
    {
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF6"]])
        {
            NSLog(@"---c=%@",c);
            //监听特征
            _writeCharacteristic = c;
        }
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF7"]])
        {
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            _A29Characteristric=c;
            [CentralManager Instance].A29Characteristric=_A29Characteristric;
        }
    }
}

//订阅的特征值有新的数据时回调
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@",
              [error localizedDescription]);
    }
    [peripheral readValueForCharacteristic:characteristic];
}

static  int     countPrice;
int     priceCount;
int     priceComs;

-(void)TowriteDateFromArr:(int)a
{
    [self writeChar:[self movieXieyi:_ReadArr[a]]];
    _identify=[NSString stringWithFormat:@"写卡Arr%d",a];
}

// 获取到特征的值时回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"didUpdateValueForCharacteristic error : %@", error.localizedDescription);
        return;
    }
    NSData * data = characteristic.value;
    if ([characteristic.UUID.UUIDString isEqualToString:@"FFF7"])
    {
        NSString *str=[data description];
        NSLog(@"---数据:    %@",str);
        NSString *newStr=[str substringWithRange:NSMakeRange(7, 2)];
        
        if ([newStr isEqualToString:@"bb"])
        {
            [UIAlertView showAlertViewWithTitle:@"设备低电" message:nil];
            return;
        }
        
        if ([_WriteOrRead isEqualToString:@"写卡"])
        {
            if (![newStr isEqualToString:@"a5"]&&[_identify isEqualToString:@"写卡1"])
            {
                _identify=@"写卡2";
                priceCount=1;
                _DNSdataStr=[[NSMutableString alloc] init];
                [self writeChar:@"a5"];
                [self writeChar:@"011819"];
            }
            else if ([newStr isEqualToString:@"a5"]&&[_identify isEqualToString:@"写卡2"])
            {
                priceCount=2;
                return;
            }
            else if (priceCount==2&&[_identify isEqualToString:@"写卡2"])
            {
                [self writeChar:@"a5"];
                NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                
                if ([[RangeStr substringWithRange:NSMakeRange(4, 2)] isEqualToString:@"02"]&&[[RangeStr substringWithRange:NSMakeRange(8, 4)] isEqualToString:@"5658"])
                {
                    //失败
                    SB_HUD_HIDE;
                }
                else
                {
                    if (RangeStr.length>=32)
                    {
                        [_DNSdataStr appendString:RangeStr];
                    }
                    
                    if (RangeStr.length<32)
                    {
                        [_DNSdataStr appendString:RangeStr];
                        _DNSdataStr=[[NSMutableString alloc] initWithString:[_DNSdataStr substringWithRange:NSMakeRange(8, _DNSdataStr.length-12)]];
                        _readCarFuwei=_DNSdataStr;
                        if (_DNSdataStr.length<30)
                        {
                            //从8的位置开始减6个
                            _identify=@"写卡3";
                            _DNSdataStr=[[NSMutableString alloc] init];
                            [self writeChar:@"a5"];
                            [self writeChar:[self movieXieyi:@"80AA4C4B10"]];
                        }
                        else
                        {
                            _identify=@"写卡5";
                            _ifMovieElse=YES;
                            [self writeChar:@"a5"];
                            [self writeChar:[self movieXieyi:@"00a40000023f01"]];
                        }
                    }
                }
            }
            
            else if (![newStr isEqualToString:@"a5"]&&[_identify isEqualToString:@"写卡3"])
            {
                [self writeChar:@"a5"];
                NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                
                
                if (RangeStr.length>=32)
                {
                    [self writeChar:@"a5"];
                    [_DNSdataStr appendString:RangeStr];
                }
                
                if (RangeStr.length<32)
                {
                    [_DNSdataStr appendString:RangeStr];
                    NSMutableString *dataStr=[[NSMutableString alloc] initWithString:[_DNSdataStr substringWithRange:NSMakeRange(8, _DNSdataStr.length-14)]];
                    _readCarFuwei=dataStr;
                    if (_DNSdataStr.length>16)
                    {
                        _DNSdataStr=dataStr;
                        _identify=@"写卡5";
                        [self writeChar:@"a5"];
                        [self writeChar:[self movieXieyi:@"00a40000023f01"]];
                    }
                }
            }
            
            else if ([_identify isEqualToString:@"写卡4"])
            {
                NSString *baoshu=[str substringWithRange:NSMakeRange(1, 2)];
                NSString *currentBaoshu=[str substringWithRange:NSMakeRange(3, 2)];
                NSMutableString * shuju=[[NSMutableString alloc]initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                [shuju replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, shuju.length)];
                
                NSLog(@"baoshu: %@  currentBaoshu: %@",baoshu,currentBaoshu);
                
                if ([baoshu intValue]>[currentBaoshu intValue])
                {
                    [self writeChar:@"a5"];
                }
                
                if ([baoshu intValue]==([currentBaoshu intValue]+1))
                {
                    _identify=@"写卡5";
                    [self writeChar:@"a5"];
                    [self writeChar:[self movieXieyi:@"00a40000023f01"]];
                }
            }
            
            else if (![newStr isEqualToString:@"a5"]&&[_identify isEqualToString:@"写卡5"])
            {
                NSString *baoshu=[str substringWithRange:NSMakeRange(1, 2)];
                NSString *currentBaoshu=[str substringWithRange:NSMakeRange(3, 2)];
                NSMutableString * shuju=[[NSMutableString alloc]initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                [shuju replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, shuju.length)];
                
                NSLog(@"baoshu: %@  currentBaoshu: %@",baoshu,currentBaoshu);
                
                if ([baoshu intValue]>[currentBaoshu intValue]+1)
                {
                    [self writeChar:@"a5"];
                }
                
                if ([baoshu intValue]==([currentBaoshu intValue]+1))
                {
                    NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                    [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                    if (RangeStr.length<=32)
                    {
                        _identify=@"写卡6";
                        [self writeChar:@"a5"];
                        [self writeChar:[self movieXieyi:@"00a40000020021"]];
                    }
                }

            }
            
            else if ([_identify isEqualToString:@"写卡6"]&&![newStr isEqualToString:@"a5"])
            {
                _identify=@"写卡7";
                [self writeChar:@"a5"];
                [self writeChar:[self movieXieyi:@"00b0000b01"]];
            }
            
            else if ([newStr isEqualToString:@"a5"]&&[_identify isEqualToString:@"写卡7"])
            {
                priceCount=12;
            }
            
            else if ([_identify isEqualToString:@"写卡7"]&&priceCount==12)
            {
                [self writeChar:@"a5"];
                NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                NSString *charStr=[RangeStr substringWithRange:NSMakeRange(8, 2)];
                if (![charStr isEqualToString:@"22"])
                {
                    [UIAlertView showAlertViewWithTitle:@"写卡失败" message:nil];
                }
                else
                {
                    _identify=@"写卡77";
                    _CarType=1;
                    [self writeChar:@"a5"];
                    [self writeChar:[self movieXieyi:@"805c000204"]];
                }
            }
            
            else if ([_identify isEqualToString:@"写卡77"])
            {
                _identify=@"写卡8";
                priceCount=16;
            }
            
            else if ([_identify isEqualToString:@"写卡8"]&&priceCount==16)
            {
                [self writeChar:@"a5"];
                if (!_ifMovieElse)
                {
                    _identify=@"写卡88";
                    [self writeChar:[self movieXieyi:@"00b2011404"]];
                }
                else
                {
                    [self writeChar:@"a5"];
                    _CarType=0;
                    
                    //读卡APP发往后台
                    //类型，卡号，购气次数,卡类型,
                    NSString *DNsstring=@"1.98|0|20130305000000|1.98|0|30|15|0|123|1|1|01-01-1|4|1.98|2000|2.38|3000|2.97|1.98|2000|2.38|3000|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|;";
                    
                    NSString *PostStr1=[NSString stringWithFormat:@"683001%d|%@|%@|%@|%@aa16",_CarType,_chargeDetailView.carNumlab.text,_gouqicishu,@"3",DNsstring];
                    NSString *PostStr=[NSString stringWithFormat:@"683001%04d%d|%@|%@|%@|%@aa16",(int)(PostStr1.length-10),_CarType,_chargeDetailView.carNumlab.text,_gouqicishu,@"3",DNsstring];
                    self.socket=[[AsyncSocket alloc] initWithDelegate:self];
                    [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
                    self.socket.delegate=self;
                    [self.socket readDataWithTimeout:5 tag:4];
                    NSData *dataStr=[PostStr dataUsingEncoding:NSUTF8StringEncoding];
                    [self.socket writeData:dataStr withTimeout:5 tag:4];
                }
            }
            
            else if ([_identify isEqualToString:@"写卡88"])
            {
                _identify=@"写卡9";
                priceCount=16;
            }
            else if ([_identify isEqualToString:@"写卡9"]&&priceCount==16)
            {
                [self writeChar:@"a5"];
                _CarType=0;
                
                //读卡APP发往后台
                //类型，卡号，购气次数,卡类型,
                NSString *DNsstring=@"1.98|0|20130305000000|1.98|0|30|15|0|123|1|1|01-01-1|4|1.98|2000|2.38|3000|2.97|1.98|2000|2.38|3000|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|1.98|480|2.38|660|2.97|;";
                
                NSString *PostStr1=[NSString stringWithFormat:@"683001%d|%@|%@|%@|%@aa16",_CarType,_chargeDetailView.carNumlab.text,_gouqicishu,@"3",DNsstring];
                NSString *PostStr=[NSString stringWithFormat:@"683001%04d%d|%@|%@|%@|%@aa16",(int)(PostStr1.length-10),_CarType,_chargeDetailView.carNumlab.text,_gouqicishu,@"3",DNsstring];
                self.socket=[[AsyncSocket alloc] initWithDelegate:self];
                [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
                self.socket.delegate=self;
                [self.socket readDataWithTimeout:5 tag:4];
                NSData *dataStr=[PostStr dataUsingEncoding:NSUTF8StringEncoding];
                [self.socket writeData:dataStr withTimeout:5 tag:4];
            }
            
            else if ([newStr isEqualToString:@"aa"]&&[_identify isEqualToString:@"写卡10"])
            {
                [self writeChar:@"a5"];
                NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
            
                NSString *Range=[RangeStr substringWithRange:NSMakeRange(8, RangeStr.length-14)];
                //683002长度复位|Range|卡类型3|;aa16
                
                NSString *PostStr1=[NSString stringWithFormat:@"683002%@|%@|%@|;aa16",_readCarFuwei,Range,@"3"];
                
                NSString *PostStr=[NSString stringWithFormat:@"683002%04d%@|%@|%@|;aa16",(int)(PostStr1.length-10),_readCarFuwei,Range,@"3"];
                self.socket=[[AsyncSocket alloc] initWithDelegate:self];
                [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
                self.socket.delegate=self;
                [self.socket readDataWithTimeout:5 tag:5];
                NSData *dataStr=[PostStr dataUsingEncoding:NSUTF8StringEncoding];
                [self.socket writeData:dataStr withTimeout:5 tag:5];
                priceCount=0;
            }
            
            else if ([_identify isEqualToString:@"写卡11"])
            {
                if (priceCount==_ReadArr.count-1)
                {
                    if ([newStr isEqualToString:@"a5"])
                    {
                        return;
                    }
                    NSMutableArray *arr=[[NSMutableArray alloc] initWithArray:[self.DNSResult componentsSeparatedByString:@"|"]];
                    [_ReadArr removeAllObjects];

                    for (int i=0; i<arr.count; i++)
                    {
                        [self setArr:arr[i]];
                    }
                    
                    [self writeChar:@"a5"];
                    priceCount=0;
                    _identify=[NSString stringWithFormat:@"写卡Arr%d",priceCount];
                    NSData *myData=[self hexToBytes:[self getNewNStr:_ReadArr[priceCount] andCom:priceCount]];
                    [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
                }
                else
                {
                    if (![newStr isEqualToString:@"a5"]) {
                        return;
                    }
                    priceCount++;
                    _identify=@"写卡11";
                    _identify=[NSString stringWithFormat:@"写卡Arr%d",priceCount];
                    NSData *myData=[self hexToBytes:[self getNewNStr:_ReadArr[priceCount] andCom:priceCount]];
                    [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
                }
            }
            
            else if ([_identify isEqualToString:[NSString stringWithFormat:@"写卡Arr%d",priceCount]])
            {
                if (priceCount+1<_ReadArr.count)
                {
                    //还的判断是否包含9000
                    priceCount++;
                    NSData *myData=[self hexToBytes:[self getNewNStr:_ReadArr[priceCount] andCom:priceCount]];
                    [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
                }
                else
                {
                    // Stop
                    if (![newStr isEqualToString:@"aa"]) {
                        return;
                    }
                    _CarType=1;
                    _identify=@"写卡12";
                    [self writeChar:@"a5"];
                    [self writeChar:[self movieXieyi:@"805c000204"]];
                }
            }
            
            else if (![[str substringWithRange:NSMakeRange(7, 5)] isEqualToString:@"aa fd"]&&[_identify isEqualToString:@"写卡12"]&&![newStr isEqualToString:@"a5"])
            {
            NSMutableString *   RangeStr=[[NSMutableString alloc] initWithString:str];
            [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
             if (![RangeStr containsString:@"9000"]||[RangeStr containsString:@"5658"])
             {
                 _CarType=0;
             }
             
              if (self.CarType==1)
              {
                  _identify=@"写卡13";
                  [self writeChar:@"a5"];
                  [self writeChar:[self movieXieyi:@"0020000403793146"]];
              }
              else
              {
                  _identify=@"写卡!13";
                  [self writeChar:@"a5"];
                  [self writeChar:[self movieXieyi:@"00a40000020002"]];
              }
            }
            
            else if ([newStr isEqualToString:@"aa"]&&[_identify isEqualToString:@"写卡13"])
            {
                long wriCard=[self.chargeDetailView.buyGasCountLab.text longLongValue];
                
                long long1 = wriCard / 256 / 256 % 256;
                long long2 = wriCard / 256 % 256;
                long long3 = wriCard % 256;
                int strMone=[self getHexTen:[NSString stringWithFormat:@"%ld",long1]]+[self getHexTen:[NSString stringWithFormat:@"%ld",long2]]+[self getHexTen:[NSString stringWithFormat:@"%ld",long3]];
                
                NSString *Ss=[NSString stringWithFormat:@"%@%06d%@",@"805000020B01",strMone,@"00112233445566"];
                
                NSString *strs=[self movieXieyi:Ss];
                int cCount;
                int ci=(int)strs.length/32;
                int bi=strs.length%32;
                if (ci==0)
                {
                    cCount=1;
                }
                else if (bi!=0)
                {
                    cCount=ci+1;
                }
                else
                {
                    cCount=ci;
                }
                _DNSdataStr=[[NSMutableString alloc] init];
                [_ReadArr removeAllObjects];
                NSString *arrStr;
                for (int j=0; j<cCount; j++)
                {
                    if (j!=cCount-1)
                    {
                        arrStr=[strs substringWithRange:NSMakeRange(j*32, 32)];
                    }
                    else
                    {
                        arrStr=[strs substringWithRange:NSMakeRange(j*32, strs.length-j*32)];
                    }
                    [_ReadArr addObject:arrStr];
                }
                
                priceCount=0;
                _identify=@"写卡13'";
                [self writeChar:@"a5"];
                NSData *myData=[self hexToBytes:[self getNewNStr:_ReadArr[priceCount] andCom:priceCount]];
                [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
                [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
            }
            
            else if ([_identify isEqualToString:@"写卡13'"])
            {
                if (priceCount==_ReadArr.count-1)
                {
                    if ([newStr isEqualToString:@"a5"])
                    {
                        return;
                    }
                    NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                    [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                    
                    if (RangeStr.length>=32)
                    {
                        [self writeChar:@"a5"];
                        [_DNSdataStr appendString:RangeStr];
                    }
                    if (RangeStr.length<32)
                    {
                        [_DNSdataStr appendString:RangeStr];
                        [self writeChar:@"a5"];
                        NSMutableString *dataStr=[[NSMutableString alloc] initWithString:[_DNSdataStr substringWithRange:NSMakeRange(8, _DNSdataStr.length-14)]];
                        
                        NSString *PostStr1=[NSString stringWithFormat:@"683003%@|%@|%d|%d|%@|;aa16",dataStr,_chargeDetailView.carNumlab.text,[_chargeDetailView.buyGasCountLab.text intValue],[_gouqicishu intValue],@"3"];
                        
                        NSString *PostStr=[NSString stringWithFormat:@"683003%04d%@|%@|%d|%d|%@|;aa16",(int)(PostStr1.length-10),dataStr,_chargeDetailView.carNumlab.text,[_chargeDetailView.buyGasCountLab.text intValue],[_gouqicishu intValue],@"3"];
                        self.socket=[[AsyncSocket alloc] initWithDelegate:self];
                        [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
                        self.socket.delegate=self;
                        [self.socket readDataWithTimeout:5 tag:7];
                        NSData *dataStrs=[PostStr dataUsingEncoding:NSUTF8StringEncoding];
                        [self.socket writeData:dataStrs withTimeout:5 tag:7];
                    }
                }
                else
                {
                    if (![newStr isEqualToString:@"a5"]) {
                        return;
                    }
                    priceCount++;
                    _identify=@"写卡13'";
                    NSData *myData=[self hexToBytes:[self getNewNStr:_ReadArr[priceCount] andCom:priceCount]];
                    [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
                }
            }
            
            else if (![newStr isEqualToString:@"a5"]&&[_identify isEqualToString:@"写卡!13"])
            {
                _identify=@"写卡!14";
                [self writeChar:@"a5"];
                [self writeChar:[self movieXieyi:@"00B2010404"]];
            }
            
            else if (![newStr isEqualToString:@"a5"]&&[_identify isEqualToString:@"写卡!14"])
            {
                 NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                
                if (RangeStr.length<8)
                {
                    return;
                }
                NSString *SubStr=[RangeStr substringWithRange:NSMakeRange(8, RangeStr.length-14)];
                
                NSString *PostStr1=[NSString stringWithFormat:@"683004%@|%@|%@|%@|%@|;aa16",SubStr,_chargeDetailView.carNumlab.text,_chargeDetailView.buyGasCountLab.text,_gouqicishu,@"3"];
                
                NSString *PostStr=[NSString stringWithFormat:@"683004%04d%@|%@|%@|%@|%@|;aa16",(int)(PostStr1.length-10),SubStr,_chargeDetailView.carNumlab.text,_chargeDetailView.buyGasCountLab.text,_gouqicishu,@"3"];
                self.socket=[[AsyncSocket alloc] initWithDelegate:self];
                [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
                self.socket.delegate=self;
                [self.socket readDataWithTimeout:5 tag:6];
                NSData *dataStr=[PostStr dataUsingEncoding:NSUTF8StringEncoding];
                [self.socket writeData:dataStr withTimeout:5 tag:6];
            }
            
            else if ([_identify isEqualToString:@"下电前一步"])
            {
                if (priceCount==_ReadArr.count-1)
                {
                    if ([newStr isEqualToString:@"a5"])
                    {
                        return;
                    }
                    _identify=@"视频卡下电";
                    [self writeChar:@"a5"];
                    priceCount=0;
                    [self writeChar:[self movieXieyi:@"010809"]];
                }
                else
                {
                    if (![newStr isEqualToString:@"a5"]) {
                        return;
                    }
                    priceCount++;
                    _identify=@"下电前一步";
                    NSData *myData=[self hexToBytes:[self getNewNStr:_ReadArr[priceCount] andCom:priceCount]];
                    [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
                    [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
                }
            }
            
            else if ([_identify isEqualToString:@"视频卡下电"])
            {
                if (priceCount==0)
                {
                    //写卡成功更新后台购气表
                    [self ChangeDNsGasDBState:self.carNum];
                }
                priceCount++;
            }
        }
        
        if (_is102Card)
        {
            if (![newStr isEqualToString:@"a5"]&&[_identify isEqualToString:@"选择卡类型"])
            {
                _identify=@"给卡上电";
                [self writeChar:@"a5"];
                [self writeChar:@"010203"];
            }
            
            NSString *newStr1=[str substringWithRange:NSMakeRange(7, 5)];
            if ([newStr1 isEqualToString:@"aa 00"]&&[_identify isEqualToString:@"给卡上电"])
            {
                /*
                 给卡上电成功，然后读卡，获取到卡上公用区22个数据 ，然后向服务器请求获取密码
                 */
                _identify=@"卡上公用区22个数据";
                [self writeChar:@"a5"];
                [self writeChar:@"0609000000001625"];
                _DNSdataStr=[[NSMutableString alloc] initWithString:@"6830110044"];
                countPrice=1;
            }
            
            if ([_identify isEqualToString:@"卡上公用区22个数据"])
            {
                NSLog(@"---卡上公用区22个数据=%@",str);
                [self writeChar:@"a5"];
                if (str.length>20)
                {
                    NSString *newStr;
                    if (countPrice==1)
                    {
                        newStr=[str substringWithRange:NSMakeRange(14, str.length-17)];
                        countPrice=2;
                        [_DNSdataStr appendString:newStr];
                    }
                    else
                    {
                        newStr=[str substringWithRange:NSMakeRange(7, str.length-10)];
                        [_DNSdataStr appendString:newStr];
                        [_DNSdataStr appendString:@"AA16"];
                        int a=(int)[_DNSdataStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, _DNSdataStr.length)];
                        NSLog(@"%d",a);
                        //读卡APP发往后台
                        self.socket=[[AsyncSocket alloc] initWithDelegate:self];
                        [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
                        self.socket.delegate=self;
                        [self.socket readDataWithTimeout:5 tag:1];
                        NSData *dataStr=[_DNSdataStr dataUsingEncoding:NSUTF8StringEncoding];
                        [self.socket writeData:dataStr withTimeout:5 tag:1];
                    }
                }
            }
            
            if ([_identify isEqualToString:@"效验密码"]&&[newStr1 isEqualToString:@"aa 00"])
            {
                //密码验证成功
                [self writeChar:@"a5"];
                _identify=@"读卡";
                [_DnsDataArr removeAllObjects];
                priceCount=0;
                _WriteOrRead=@"读卡";
                [self read102CartoBlueTooth:priceCount];
            }
            
            if ([_identify isEqualToString:@"读卡"]&&str.length>17)
            {
                NSString *baoshu=[str substringWithRange:NSMakeRange(1, 2)];
                NSString *currentBaoshu=[str substringWithRange:NSMakeRange(3, 2)];
                NSMutableString * shuju=[[NSMutableString alloc]initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
                [shuju replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, shuju.length)];
                
                NSLog(@"baoshu: %@  currentBaoshu: %@",baoshu,currentBaoshu);
                
                if ([baoshu intValue]>[currentBaoshu intValue])
                {
                    [_litterString appendString:shuju];
                }
                
                if ([baoshu intValue]==([currentBaoshu intValue]+1))
                {
                    [_litterString replaceCharactersInRange:NSMakeRange(0, 6) withString:@""];
                    
                    [_DnsDataArr addObject:_litterString];
                    _litterString=[[NSMutableString alloc] init];
                    priceCount+=1;
                    [self read102CartoBlueTooth:priceCount];
                }
                [self writeChar:@"a5"];
            }
            
            if ([_identify isEqualToString:@"写卡"]&&[newStr1 isEqualToString:@"aa 00"])
            {
                [self writeChar:@"a5"];
                [NSThread sleepForTimeInterval:0.1];
                [self writeDataToBlueTooth:WriteCount];
            }
            if ([_identify isEqualToString:@"写卡第二部，给卡上写数据"]&&[newStr1 isEqualToString:@"a5 a7"])
            {
                //            Test
                WriteTime++;
                [self WriteCards:WriteCount];
            }
            if ([_identify isEqualToString:@"写卡2"])
            {
                [self writeChar:@"a5"];
                WriteCount++;
                _identify=@"写卡";
                [self writeTocard:WriteCount];
            }
        }
        
        //视频卡
        else {
            if ([newStr isEqualToString:@"aa"]&&[_identify isEqualToString:@"选择卡类型"])
            {
                _identify=@"给卡上电";
                [self writeChar:@"a5"];
                [self writeChar:@"011819"];
                countPrice=1;
            }
            
            if ([_identify isEqualToString:@"给卡上电"]&&str.length>15)
            {
                [self writeChar:@"a5"];
                [NSThread sleepForTimeInterval:0.003];
                [self writeChar:@"a5"];
                NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-8)]];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                
                if ([[RangeStr substringWithRange:NSMakeRange(4, 2)] isEqualToString:@"02"]&&[[RangeStr substringWithRange:NSMakeRange(8, 4)] isEqualToString:@"5658"])
                {
                    //失败
                    SB_HUD_HIDE;
                    _is102Card=YES;
                    [self readCardAction:nil];
                }
                else
                {
                    if (RangeStr.length<32)
                    {
                        _identify=@"卡上公用区22个数据";
                        priceComs=0;
                        countPrice=1;
                        [self writeChar:[self movieXieyi:@"00a40000023f01"]];
                    }
                }
            }
            
            else  if ([_identify isEqualToString:@"卡上公用区22个数据"])
            {
                if (priceComs==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                priceComs++;
                NSString *count=[str substringWithRange:NSMakeRange(2, 1)];
                if ([count intValue]>priceComs)
                {
                    [self writeChar:@"a5"];
                }
                else
                {
                    _identify=@"视频卡1";
                    [self writeChar:@"a5"];
                    [self writeChar:[self movieXieyi:@"00a40000020021"]];
                }
            }
            
            else if ([_identify isEqualToString:@"视频卡1"]&&[newStr isEqualToString:@"aa"])
            {
                _identify=@"视频卡2";
                [self writeChar:@"a5"];
                priceComs=0;
                _DNSdataStr=[[NSMutableString alloc] init];
                _CarTypeStr=[[NSString alloc] init];
                [self writeChar:[self movieXieyi:@"00b000000c"]];
            }
            
            else if ([_identify isEqualToString:@"视频卡2"])
            {
                NSMutableString *RangeStr;
                if (priceComs==0)
                {
                    if (![newStr isEqualToString:@"aa"])
                    {
                        return;
                    }
                    else
                    {
                        RangeStr=[[NSMutableString alloc] initWithString:str];
                        [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                        self.carNum=[RangeStr substringWithRange:NSMakeRange(15, 10)];
                        self.AddressLab.text=self.carNum;
                        _CarTypeStr=[RangeStr substringWithRange:NSMakeRange(37, 2)];
                    }
                }
                [self writeChar:@"a5"];
                
                RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                
                if (RangeStr.length<42)
                {
                    //最后一条
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    if (![self judjeIfcontainStr:_DNSdataStr])
                    {
                        SB_HUD_HIDE;
                        [UIAlertView showAlertViewWithTitle:@"读卡失败" message:nil];
                    }
                    else
                    {
                        if (![_CarTypeStr isEqualToString:@"22"])
                        {
                            SB_HUD_HIDE;
                            [UIAlertView showAlertViewWithTitle:@"不是用户卡!" message:nil];
                            return;
                        }
                        else
                        {
                            _identify=@"视频卡3";
                            [self writeChar:[self movieXieyi:@"00b0840003"]];
                        }
                    }
                }
                else
                {
                    priceComs++;
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
            }
            
            else if ([_identify isEqualToString:@"视频卡3"]&&str.length>15)
            {
                [self writeChar:@"a5"];
                NSMutableString *RangeStr=[[NSMutableString alloc] initWithString:[str substringWithRange:NSMakeRange(7, str.length-8)]];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                
                if ([[RangeStr substringWithRange:NSMakeRange(4, 2)] isEqualToString:@"02"]&&[[RangeStr substringWithRange:NSMakeRange(8, 4)] isEqualToString:@"5658"])
                {
                    //失败
                    SB_HUD_HIDE;
                    [UIAlertView showAlertViewWithTitle:@"读卡失败" message:nil];
                }
                else
                {
                    //81开户卡,01补卡，00购气卡
                    
                    //<01000aaa 000606   00(卡类型) 00 01(购气次数) 9000 1163>
                    
                    NSLog(@"--%@-购气次数: %@",str,[RangeStr substringWithRange:NSMakeRange(RangeStr.length-10, 2)]);
                    _gouqicishu=[RangeStr substringWithRange:NSMakeRange(RangeStr.length-10, 2)];
                    if (RangeStr.length<42)
                    {
                        _identify=@"视频卡4";
                        [self writeChar:[self movieXieyi:@"805c000204"]];
                    }
                }
            }
            
            else if ([_identify isEqualToString:@"视频卡4"]&&[newStr isEqualToString:@"aa"])
            {
                //               <01000baa 000707	00009300(余额或者气量)	90 0011f8>
                NSMutableString *rangeStr=[[NSMutableString alloc] initWithString:str];
                [rangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, rangeStr.length)];
                
                if (rangeStr.length>22)
                {
                    NSString *rangeJinE=[rangeStr substringWithRange:NSMakeRange(15, 8)];
                    //金额
                    int KK=0;
                    for (int i=0; i<4; i++)
                    {
                        if (i<3)
                        {
                            KK+=[self getHexTen:[rangeJinE substringWithRange:NSMakeRange(i*2, 2)]]*[self getMiResult:256 andCount:2-i];
                        }
                        else
                        {
                            KK+=[self getHexTen:[rangeJinE substringWithRange:NSMakeRange(i*2, 2)]]/100;
                        }
                    }
                    NSLog(@"---余额或者气量1:%d",KK);
                    self.jinEstr=[NSString stringWithFormat:@"%d",KK];
                    _identify=@"视频卡6";
                    [self writeChar:@"a5"];
                    [self writeChar:[self movieXieyi:@"00a4000002000b"]];
                    _DNSdataStr=[[NSMutableString alloc] init];
                }
                else
                {
                    [self writeChar:@"a5"];
                    _identify=@"视频卡5";
                    //如果这条命令成功则余额气量拿这条的
                    [self writeChar:[self movieXieyi:@"00b2011404"]];
                }
            }
            
            else if ([_identify isEqualToString:@"视频卡5"]&&[newStr isEqualToString:@"aa"])
            {
                //               <01000baa 000707	00009300(余额或者气量)	90 0011f8>
                NSMutableString *rangeStr=[[NSMutableString alloc] initWithString:str];
                [rangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, rangeStr.length)];
                NSString *rangeJinE=[rangeStr substringWithRange:NSMakeRange(15, 8)];
                //金额
                int KK=0;
                for (int i=0; i<4; i++)
                {
                    if (i<3)
                    {
                        KK+=[self getHexTen:[rangeJinE substringWithRange:NSMakeRange(i*2, 2)]]*[self getMiResult:256 andCount:2-i];
                    }
                    else
                    {
                        KK+=[self getHexTen:[rangeJinE substringWithRange:NSMakeRange(i*2, 2)]]/100;
                    }
                }
                NSLog(@"---余额或者气量2:%d",KK);
                self.jinEstr=[NSString stringWithFormat:@"%d",KK];
                _identify=@"视频卡6";
                [self writeChar:@"a5"];
                [self writeChar:[self movieXieyi:@"00a4000002000b"]];
                _DNSdataStr=[[NSMutableString alloc] init];
                
//                _identify=@"视频卡6";
//                [self writeChar:@"a5"];
//                [self writeChar:[self movieXieyi:@"00a4000002000b"]];
//                _DNSdataStr=[[NSMutableString alloc] init];
            }
            
            else if ([_identify isEqualToString:@"视频卡6"]&&[newStr isEqualToString:@"aa"])
            {
                [self writeChar:@"a5"];
                
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                
                if (RangeStr.length<42)
                {
                    //最后一条
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    if ([[_DNSdataStr substringWithRange:NSMakeRange(_DNSdataStr.length-6, 4)] intValue]==9000)
                    {
                        _identify=@"包含9000步骤1";
                        priceComs=0;
                        _DNSdataStr=[[NSMutableString alloc] init];
                        [self writeChar:@"a5"];
                        [self writeChar:[self movieXieyi:@"00b000002A"]];
                    }
                    else
                    {
                        _identify=@"不包含9000步骤1";
                        priceComs=0;
                        [self writeChar:@"a5"];
                        _ShipinStr=[[NSMutableString alloc] init];
                        [self writeChar:[self movieXieyi:@"00a40000020007"]];
                    }
                }
                else
                {
                    priceComs++;
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
            }
            
            else if ([_identify isEqualToString:@"包含9000步骤1"])
            {
                if (priceComs==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceComs++;
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                if (RangeStr.length<42)
                {
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    [_DNSdataStr replaceCharactersInRange:NSMakeRange(0, 8) withString:@""];
                    [_DNSdataStr replaceCharactersInRange:NSMakeRange(_DNSdataStr.length-6, 6) withString:@""];
                    _identify=@"包含9000步骤2";
                    priceComs=0;
                    _ShipinStr=[[NSMutableString alloc] init];
                    [self writeChar:[self movieXieyi:@"00b0002A2A"]];
                }
                else
                {
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
                
            }
            
            else if ([_identify isEqualToString:@"不包含9000步骤1"])
            {
                NSMutableString *RangeStr;
                if (priceComs==0)
                {
                    if (![newStr isEqualToString:@"aa"])
                    {
                        return;
                    }
                }
                [self writeChar:@"a5"];
                
                RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                
                if (RangeStr.length<42)
                {
                    //最后一条
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    if (![self judjeIfcontainStr:_ShipinStr]&&![[_ShipinStr substringFromIndex:8] isEqualToString:@"6a82"])
                    {
                        SB_HUD_HIDE;
                        [UIAlertView showAlertViewWithTitle:@"读卡失败" message:nil];
                    }
                    else
                    {
                        _identify=@"不包含9000步骤2";
                        priceComs=0;
                        _DNSdataStr=[[NSMutableString alloc] init];
                        [self writeChar:[self movieXieyi:@"00b0000028"]];
                    }
                }
                else
                {
                    priceComs++;
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
            }
            
            else if ([_identify isEqualToString:@"包含9000步骤2"])
            {
                if (priceComs==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceComs++;
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                if (RangeStr.length<42)
                {
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    [_ShipinStr replaceCharactersInRange:NSMakeRange(0, 8) withString:@""];
                    [_ShipinStr replaceCharactersInRange:NSMakeRange(_ShipinStr.length-6, 6) withString:@""];
                    [_DNSdataStr appendString:_ShipinStr];
                    _identify=@"包含9000步骤3";
                    priceComs=0;
                    _ShipinStr=[[NSMutableString alloc] init];
                    [self writeChar:[self movieXieyi:@"00b0005435"]];
                }
                else
                {
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
                
            }
            
            else if ([_identify isEqualToString:@"不包含9000步骤2"])
            {
                if (priceComs==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceComs++;
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                if (RangeStr.length<42)
                {
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    [_DNSdataStr replaceCharactersInRange:NSMakeRange(0, 8) withString:@""];
                    [_DNSdataStr replaceCharactersInRange:NSMakeRange(_DNSdataStr.length-6, 6) withString:@""];
                    _identify=@"不包含9000步骤3";
                    priceComs=0;
                    _ShipinStr=[[NSMutableString alloc] init];
                    [self writeChar:[self movieXieyi:@"00b0002828"]];
                }
                else
                {
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
            }
            
            else if ([_identify isEqualToString:@"包含9000步骤3"])
            {
                if (priceComs==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceComs++;
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                if (RangeStr.length<42)
                {
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    [_ShipinStr replaceCharactersInRange:NSMakeRange(0, 8) withString:@""];
                    [_ShipinStr replaceCharactersInRange:NSMakeRange(_ShipinStr.length-6, 6) withString:@""];
                    [_DNSdataStr appendString:_ShipinStr];
                    _identify=@"步骤4";
                    [self writeChar:[self movieXieyi:@"00b088000f"]];
                }
                else
                {
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
            }
            
            else if ([_identify isEqualToString:@"不包含9000步骤3"])
            {
                if (priceComs==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceComs++;
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                if (RangeStr.length<42)
                {
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    [_ShipinStr replaceCharactersInRange:NSMakeRange(0, 8) withString:@""];
                    [_ShipinStr replaceCharactersInRange:NSMakeRange(_ShipinStr.length-6, 6) withString:@""];
                    [_DNSdataStr appendString:_ShipinStr];
                    _identify=@"步骤4";
                    [self writeChar:[self movieXieyi:@"00b088000f"]];
                }
                else
                {
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
                
            }
            
            else if ([_identify isEqualToString:@"步骤4"]&&![newStr isEqualToString:@"aa"])
            {
                [self writeChar:@"a5"];
                _identify=@"步骤5";
                [self writeChar:[self movieXieyi:@"00a40000020003"]];
            }
            
            else if ([_identify isEqualToString:@"步骤5"]&&![newStr isEqualToString:@"aa"])
            {
                [self writeChar:@"a5"];
                _identify=@"步骤6";
                [self writeChar:[self movieXieyi:@"00b0000030"]];
            }
            
            else if ([_identify isEqualToString:@"步骤6"]&&![newStr isEqualToString:@"aa"])
            {
                [self writeChar:@"a5"];
                _identify=@"步骤7";
                [self writeChar:[self movieXieyi:@"00b000302e"]];
            }
            
            else if ([_identify isEqualToString:@"步骤7"]&&![newStr isEqualToString:@"aa"])
            {
                [self writeChar:@"a5"];
                _identify=@"步骤8";
                [self writeChar:[self movieXieyi:@"00a40000020005"]];
            }
            
            else if ([_identify isEqualToString:@"步骤8"]&&![newStr isEqualToString:@"aa"])
            {
                [self writeChar:@"a5"];
                _identify=@"步骤9";
                [self writeChar:[self movieXieyi:@"00b0000031"]];
            }
            
            else if ([_identify isEqualToString:@"步骤9"]&&![newStr isEqualToString:@"aa"])
            {
                [self writeChar:@"a5"];
                _identify=@"步骤10";
                [self writeChar:[self movieXieyi:@"00b0003132"]];
            }
            
            else if ([_identify isEqualToString:@"步骤10"]&&![newStr isEqualToString:@"aa"])
            {
                [self writeChar:@"a5"];
                _identify=@"步骤11";
                priceComs=1;
                [self writeChar:[self movieXieyi:@"010809"]];
            }
            
            else if ([_identify isEqualToString:@"步骤11"]&&![newStr isEqualToString:@"aa"])
            {
                //读卡完毕
                if (priceComs==1)
                {
                    //请求服务器判断此卡类型然后展示相应页面
                    SB_MBPHUD_SHOW(@"请求中...", self.view, NO);
                    NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
                    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
                    NSMutableArray *arr=[NSMutableArray array];
                    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@$%@$%@",logerDic[@"phone"],self.carNum,@"民用",@""],@"strParm", nil]];
                    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"Query1"];
                    [_helper asynServiceMethod:@"Query1" SoapMessage:soapMsg Tag:200];
                }
                priceComs++;
            }
        }
    }
}

-(BOOL)judjeIfcontainStr:(NSString *)str
{
    if ([[str substringWithRange:NSMakeRange(str.length-6, 4)] intValue]!=9000||([[str substringWithRange:NSMakeRange(4, 2)] isEqualToString:@"02"]&&[[str substringWithRange:NSMakeRange(8, 4)] isEqualToString:@"5658"]))
    {
        return NO;
    }
    return YES;
}

-(void)read102CartoBlueTooth:(int)a
{
    NSString *zushu;
    NSString *newSection;
    if ([_WriteOrRead isEqualToString:@"读卡"])
    {
        zushu=[self.DNSResult substringWithRange:NSMakeRange(20, 2)];
        newSection=[self.DNSResult substringWithRange:NSMakeRange(22, self.DNSResult.length-26)];
    }
    else if ([_WriteOrRead isEqualToString:@"写卡"])
    {
        zushu=[self.DNSResult substringWithRange:NSMakeRange(34, 2)];
        newSection=[self.DNSResult substringWithRange:NSMakeRange(36, self.DNSResult.length-40)];
    }
    if ([zushu intValue]>a)
    {
        NSString *quhao=[newSection substringWithRange:NSMakeRange(a*6, 2)];
        NSString *weizhi=[newSection substringWithRange:NSMakeRange(a*6+2, 2)];
        NSString *changdu=[newSection substringWithRange:NSMakeRange(a*6+4, 2)];
        NSLog(@"--quhao: %@  weizhi:  %@  changdu:  %@",quhao,weizhi,changdu);
        NSString *str=[NSString stringWithFormat:@"0609%@00%@00%@",quhao,weizhi,changdu];
        int ResultNum=[self getSixteenAddResult:str];
        NSString *newStr=[self ToHex:ResultNum];
        NSString *charStr=[NSString stringWithFormat:@"%@%@",str,newStr];
        NSLog(@"charStr=%@",charStr);
        [self writeChar:charStr];
    }else
    {
        if ([_WriteOrRead isEqualToString:@"读卡"])
        {
            NSString *changjia=[self.DNSResult substringWithRange:NSMakeRange(10, 2)];
            NSString *shuzu=[self.DNSResult substringWithRange:NSMakeRange(20, 2)];
            //后台要求读取的数据，每组数据中间用|隔开
            NSMutableString *str=[[NSMutableString alloc] init];
            for (int i=0; i<self.DnsDataArr.count; i++)
            {
                [str appendString:[self.DnsDataArr objectAtIndex:i]];
                if (i!=_DnsDataArr.count-1)
                {
                    [str appendString:@"|"];
                }
            }
            NSString *changdu=[NSString stringWithFormat:@"%04zi",str.length];
            NSString *NewStr=[NSString stringWithFormat:@"683012%@%@%@%@AA16",changdu,changjia,shuzu,str];
            
            self.socket=[[AsyncSocket alloc] initWithDelegate:self];
            [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
            self.socket.delegate=self;
            [self.socket readDataWithTimeout:5 tag:2];
            NSData *dataStr=[NewStr dataUsingEncoding:NSUTF8StringEncoding];
            [self.socket writeData:dataStr withTimeout:5 tag:2];
        }
        else if ([_WriteOrRead isEqualToString:@"写卡"])
        {
            NSString *changjia=[self.DNSResult substringWithRange:NSMakeRange(10, 2)];
            //后台要求读取的数据，每组数据中间用|隔开
            NSMutableString *str=[[NSMutableString alloc] init];
            for (int i=0; i<self.DnsDataArr.count; i++)
            {
                [str appendString:[self.DnsDataArr objectAtIndex:i]];
                if (i!=_DnsDataArr.count-1)
                {
                    [str appendString:@"|"];
                }
            }
            NSString *changdu=[NSString stringWithFormat:@"%04zi",str.length];
            NSString *qiliang=self.writeView.JinElab.text;
            //test
//          NSString *qiliang=@"200";
            double a=[qiliang doubleValue];
            int b=(int)(a);
            int n1 = b/ 256 / 256 % 256;
            int n2 = b / 256 % 256;
            int n3 = b % 256;
            b=(int)(a*100)-b*100;
            qiliang=[NSString stringWithFormat:@"%02x%02x%02x%02x",n1,n2,n3,b];
            
            NSString *cishu=[self.DNSResult substringWithRange:NSMakeRange(30, 4)];
            NSString *shuzu=[self.DNSResult substringWithRange:NSMakeRange(34, 2)];
            NSString *NewStr=[NSString stringWithFormat:@"683013%@%@%@%@%@%@AA16",changdu,changjia,qiliang,cishu,shuzu,str];
            
            self.socket=[[AsyncSocket alloc] initWithDelegate:self];
            [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
            self.socket.delegate=self;
            [self.socket readDataWithTimeout:5 tag:3];
            NSData *dataStr=[NewStr dataUsingEncoding:NSUTF8StringEncoding];
            NSLog(@"----数据是:%@",NewStr);
            [NSThread sleepForTimeInterval:0.5];
            [self.socket writeData:dataStr withTimeout:5 tag:3];
        }
    }
}

//写卡
-(void)writeTocard:(int)a
{
    [NSThread sleepForTimeInterval:0.1];
    NSString *quhao;
    NSString *weizhi;
    NSString *changdu;
    NSString *jiaoyan;
    NSString *zushu=[self.DNSResult substringWithRange:NSMakeRange(10, 2)];
    if ([zushu intValue]>a)
    {
        NSString *resultStr=[self.DNSResult substringWithRange:NSMakeRange(12, self.DNSResult.length-16)];
        NSArray *arr=[resultStr componentsSeparatedByString:@"|"];
        NSString *StrArr=arr[a];
        quhao=[StrArr substringWithRange:NSMakeRange(0, 2)];
        weizhi=[StrArr substringWithRange:NSMakeRange(2, 2)];
        changdu=[StrArr substringWithRange:NSMakeRange(4, 2)];
        NSLog(@"---quhao:%@ weizhi: %@ changdu :%@",quhao,weizhi,changdu);
        NSString *str=[NSString stringWithFormat:@"060A%@00%@00%@",quhao,weizhi,changdu];
        
        int addStr=[self getSixteenAddResult:str];
        jiaoyan=[self ToHex:addStr];
        NSString *charStr=[NSString stringWithFormat:@"%@%@",str,jiaoyan];
//        //Test
//        charStr=@"060a010000000e1F";
        [NSThread sleepForTimeInterval:0.5];
        [self writeChar:charStr];
    }
    else
    {
        //写卡成功更新后台购气表
        [self ChangeDNsGasDBState:self.carNum];
    }
}

-(void)writeDataToBlueTooth:(int)a
{
    NSString *zushu=[self.DNSResult substringWithRange:NSMakeRange(10, 2)];
    
    if ([zushu intValue]>a)
    {
        _identify=@"写卡第二部，给卡上写数据";
        WriteTime=0;
        [self WriteCards:a];
    }
}

//视频卡协议
-(NSString *)movieXieyi:(NSString *)str
{
    NSMutableString *NewStr=[[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"0602%@",str]];
    NewStr=[NSMutableString stringWithFormat:@"%02x%@",(int)NewStr.length/2,NewStr];
    //校验和
    int jyhNum=0;
    for (int i=0; i<NewStr.length/2; i++)
    {
        NSString *k=[NewStr substringWithRange:NSMakeRange(i*2, 2)];
        NSLog(@"---k=%@",k);
        jyhNum+=[self getHexTen:k];
    }
    NSString *hexStr=[self ToHex:jyhNum];
    if (hexStr.length==1)
    {
        hexStr=[NSString stringWithFormat:@"0%@",hexStr];
    }
    else if (hexStr.length>2)
    {
        hexStr=[hexStr substringFromIndex:hexStr.length-2];
    }
    [NewStr appendString:hexStr];
    return NewStr;
}

static int  WriteTime=0;

-(void)WriteCards:(int)count
{
    NSString *str=[self.DNSResult substringWithRange:NSMakeRange(12, self.DNSResult.length-16)];
    NSLog(@"--str=%@",str);
    
    NSString *charStr=[str componentsSeparatedByString:@"|"][count];
    
    charStr=[NSString stringWithFormat:@"%02x%@",(int)[charStr substringFromIndex:6].length/2,[charStr substringFromIndex:6]];
    
    int jyhNum=0;
    for (int i=0; i<charStr.length/2; i++)
    {
        NSString *k=[charStr substringWithRange:NSMakeRange(i*2, 2)];
        NSLog(@"---k=%@",k);
        jyhNum+=[self getHexTen:k];
    }
    NSString *hexStr=[self ToHex:jyhNum];
    if (hexStr.length==1)
    {
        hexStr=[NSString stringWithFormat:@"0%@",hexStr];
    }
    else if (hexStr.length>2)
    {
        hexStr=[hexStr substringFromIndex:hexStr.length-2];
    }
    NSString *AddResult=hexStr;
    
    charStr=[NSString stringWithFormat:@"%@%@",charStr,AddResult];
    
    NSString *writeStr;
    int time;
    if (charStr.length%32==0)
    {
        time=(int)charStr.length/32;
    }
    else
    {
        time=(int)charStr.length/32+1;
    }
    
    if (WriteTime<time)
    {
        if (WriteTime==time-1)
        {
            _identify=@"写卡2";
            writeStr=[charStr substringFromIndex:WriteTime*32];
        }
        else
        {
            writeStr=[charStr substringWithRange:NSMakeRange(WriteTime*32, 32)];
        }
        [self TowriteWhenShouldToWriteCard:writeStr andAllBao:time andCurrentBao:WriteTime];
    }
}

#pragma mark 写数据
-(void)writeChar:(NSString *)str
{
    NSLog(@"---_writeCharacteristic＝%@",_writeCharacteristic);
    NSLog(@"---_discoveredPeripheral=%@",_discoveredPeripheral);
    if (_writeCharacteristic==nil)
    {
        NSLog(@"writeCharacteristic为空");
        return;
    }
    
    int a=(int)str.length/2/16;
    int b=(int)str.length/2%16;
    if (b==0)
    {
        a=a;
    }
    else
    {
        a+=1;
    }
    
    for (int i=0; i<a; i++)
    {
        NSData *myData=[self hexToBytes:[self getNewStr:str andCurrentNum:i]];
        [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
}

//写卡时候执行写写卡操作
-(void)TowriteWhenShouldToWriteCard:(NSString *)str andAllBao:(int)x andCurrentBao:(int)k
{
    if (_writeCharacteristic==nil)
    {
        NSLog(@"writeCharacteristic为空");
        return;
    }
    //当前包长度
    int LengthofPack=(int)str.length/2;
    //校验和
    int jyhNum=x+k+LengthofPack;
    for (int i=0; i<str.length/2; i++)
    {
        NSString *k=[str substringWithRange:NSMakeRange(i*2, 2)];
        NSLog(@"---k=%@",k);
        jyhNum+=[self getHexTen:k];
    }
    NSString *hexStr=[self ToHex:jyhNum];
    if (hexStr.length==1)
    {
        hexStr=[NSString stringWithFormat:@"0%@",hexStr];
    }
    else if (hexStr.length>2)
    {
        hexStr=[hexStr substringFromIndex:hexStr.length-2];
    }
    
    NSString *newStr=[NSString stringWithFormat:@"%02x%02x%02x%@%2@",x,k,LengthofPack,str,hexStr];
    NSData *myData=[self hexToBytes:newStr];
    
    NSLog(@"----Result==%@",myData);
    
    [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
}

-(NSData*) hexToBytes:(NSString *)str
{
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= str.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [str substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

//数据包总包数，当前数据包号，当前包长度，校验和
-(NSString *)getNewStr:(NSString *)str andCurrentNum:(int)num
{
//  数据总包数
    int a=(int)str.length/2/16;
    int b=(int)str.length/2%16;
    if (b==0)
    {
        a=a;
    }
    else
    {
        a+=1;
    }
    //当前数据包号 num
    //当前包长度
    int LengthofPack=(int)str.length/2;
    //校验和
    int jyhNum=a+num+LengthofPack;
    for (int i=0; i<str.length/2; i++)
    {
        NSString *k=[str substringWithRange:NSMakeRange(i*2, 2)];
        NSLog(@"---k=%@",k);
        jyhNum+=[self getHexTen:k];
    }
    NSString *hexStr=[self ToHex:jyhNum];
    if (hexStr.length==1)
    {
        hexStr=[NSString stringWithFormat:@"0%@",hexStr];
    }
    else if (hexStr.length>2)
    {
        hexStr=[hexStr substringFromIndex:hexStr.length-2];
    }
    
    NSString *newStr=[NSString stringWithFormat:@"%02x%02x%02x%@%2@",a,num,LengthofPack,str,hexStr];
    NSLog(@"----newStr=%@",newStr);
    return newStr;
}

//十进制转16进制
-(NSString *)ToHex:(int)tmpid
{
    NSString *nLetterValue;
    NSString *str =@"";
    long long int ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:nLetterValue=[[NSString alloc]initWithFormat:@"%lld",ttmpig];
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;  
        }  
        
    }  
    return str;  
}

//16进制转10进制
-(int)getHexTen:(NSString *)str
{
    int result=0;
    for (int i=0; i<str.length; i++)
    {
        NSString *ss=[str substringWithRange:NSMakeRange(i, 1)];
        int b=[self getNum:ss];
        if (b==0)
        {
            b=[ss intValue];
        }
        result+=[self getMiResult:16 andCount:(int)(str.length-i-1)]*b;
    }
    return result;
}

-(int)getNum:(NSString *)str
{
    int num=0;
    if ([str isEqualToString:@"A"]||[str isEqualToString:@"a"])
    {
        num=10;
    }
    else if ([str isEqualToString:@"B"]||[str isEqualToString:@"b"])
    {
        num=11;
    }
    else if ([str isEqualToString:@"C"]||[str isEqualToString:@"c"])
    {
        num=12;
    }
    else if ([str isEqualToString:@"D"]||[str isEqualToString:@"d"])
    {
        num=13;
    }
    else if ([str isEqualToString:@"E"]||[str isEqualToString:@"e"])
    {
        num=14;
    }
    else if ([str isEqualToString:@"F"]||[str isEqualToString:@"f"])
    {
        num=15;
    }
    return num;
}

//幂运算
-(int)getMiResult:(int)a andCount:(int)k
{
    int result=1;
    for (int i=0; i<k; i++) {
        result*=a;
    }
    return result;
}

#pragma mark 写数据后回调
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error writing characteristic value: %@",
              [error localizedDescription]);
        return;
    }
    NSLog(@"写入%@成功",characteristic);
}

#pragma mark -- ZSY代理
-(NSInteger)popoverListView:(ZSYPopoverListView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.peripherals.count;
}

-(UITableViewCell *)popoverListView:(ZSYPopoverListView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"identifier";
    UITableViewCell *cell = [tableView dequeueReusablePopoverCellWithIdentifier:identifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    NearByModal *model=(NearByModal *)[self.peripherals objectAtIndex:indexPath.row];
    cell.textLabel.text=model.name;
    return cell;
}

-(void)popoverListView:(ZSYPopoverListView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NearByModal *modal = self.peripherals[indexPath.row];
    _MacPosition=indexPath.row;
    [self stopScanss];
    SB_MBPHUD_SHOW(@"开始连接", self.m_Tableview, NO);
    
    if (self.mgr.state == CBCentralManagerStateUnsupported) {//设备不支持蓝牙
        SB_HUD_HIDE;
    }else{
        if (self.mgr.state == CBCentralManagerStatePoweredOn)
        {
            [self.mgr connectPeripheral:modal.Peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,CBConnectPeripheralOptionNotifyOnNotificationKey:@YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES}];
        }else
        {
            [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
        }
    }
}

-(void)popoverListView:(ZSYPopoverListView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==100)
    {
        NSString *str=configEmpty(xml[@"BundingKaHaoQResponse"][@"BundingKaHaoQResult"][@"text"]);
        NSArray *strArr=[str componentsSeparatedByString:@"|"];
        SB_HUD_HIDE;
        if ([str isEqualToString:@"1|0"])
        {
            //此用户不存在,可以绑定;
            [UIAlertView showAlertViewWithTitle:@"此用户不存在!" message:nil];
        }
        else if ([str isEqualToString:@"0|0"])
        {
            [UIAlertView showAlertViewWithTitle:@"连接服务器失败!" message:nil];
        }
        else if ([strArr[0] isEqualToString:@"2"]||[strArr[0] isEqualToString:@"4"])
        {
            self.name=strArr[1];
            self.carNumLab.text=self.name;
            NSLog(@"---name: %@",strArr[1]);
            self.Useraddress=strArr[2];
            
            //请求服务器判断此卡类型然后展示相应页面
            SB_MBPHUD_SHOW(@"请求中...", self.view, NO);
            NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
            _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
            NSMutableArray *arr=[NSMutableArray array];
            [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@$%@$%@",logerDic[@"phone"],self.carNum,@"民用",@""],@"strParm", nil]];
            NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"Query1"];
            [_helper asynServiceMethod:@"Query1" SoapMessage:soapMsg Tag:200];
        }
        else if ([strArr[0] isEqualToString:@"3"])
        {
            [UIAlertView showAlertViewWithTitle:@"此卡已经被其他账号绑定" message:nil];
        }
    }
    
    else if (request.tag==200)
    {
        SB_HUD_HIDE;
        NSString *str=configEmpty(xml[@"Query1Response"][@"Query1Result"][@"text"]);
        if ([str isEqualToString:@"0|0"])
        {
            [UIAlertView showAlertViewWithTitle:@"此用户不存在" message:nil];
        }
        else if ([str isEqualToString:@"1|0"])
        {
            [UIAlertView showAlertViewWithTitle:@"还没有绑定此卡" message:nil];
        }
        else if ([str isEqualToString:@"4|0"])
        {
            [UIAlertView showAlertViewWithTitle:@"针对无线远传表，此用户还没有抄表信息" message:nil];
        }
        else if ([str isEqualToString:@"5|0"])
        {
            [UIAlertView showAlertViewWithTitle:@"此用户已被其他账号绑定" message:nil];
        }
        else
        {
            SB_HUD_HIDE;
            
            NSArray *arr=[str componentsSeparatedByString:@"|"];
            NSString *carType=arr[36];
            self.Danjia=arr[37];
            self.rightBtB.hidden=YES;
            if ([carType intValue]==0)
            {
                //气量卡
                self.chargeDetailView=[[NSBundle mainBundle] loadNibNamed:@"ChargeDetailController" owner:self options:nil][0];
                self.CarType=0;
            }
            else if ([carType intValue]==1)
            {
                //金额卡
             self.chargeDetailView=[[NSBundle mainBundle] loadNibNamed:@"ChargeDetailController" owner:self options:nil][1];
                self.CarType=1;
            }
            else if ([carType intValue]==2)
            {
                //金额卡
             self.chargeDetailView=[[NSBundle mainBundle] loadNibNamed:@"ChargeDetailController" owner:self options:nil][2];
                self.CarType=2;
            }
            self.name=arr[3];
            self.carNumLab.text=self.name;
            self.Useraddress=arr[29];
            self.chargeDetailView.carNumlab.text=self.carNum;
            self.chargeDetailView.nameLab.text=self.name;
            self.chargeDetailView.userAddresslab.text=self.Useraddress;
            self.chargeDetailView.frame=CGRectMake(0, 65, winsize.width, winsize.height-65);
            self.chargeDetailView.moneyCountlab.text=self.jinEstr;

            
            __weak const UserChargeController *charVc=self;
            self.chargeDetailView.payBlock=^(int tag)
            {
                if (tag==100||tag==500)
                {
                    if (charVc.CarType==1)
                    {
                        [charVc showPayView];
                    }
                    else
                    {
                        [charVc getTotalMoney];
                    }
                }
            };
            
            
            
            /*
             判断是否写卡，如果不写卡跑到充值界面，否则写卡
             */
            _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
            NSMutableArray *Arr=[NSMutableArray array];
            [Arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:self.carNum,@"strParm",nil]];
            NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:Arr methodName:@"IsWriteC"];
            [_helper asynServiceMethod:@"IsWriteC" SoapMessage:soapMsg Tag:400];
        }
    }
    
    else if (request.tag==300)
    {
        [SBPublicAlert hideMBprogressHUD:self.chargeDetailView];
        NSString *result=configEmpty(xml[@"ComGasResponse"][@"ComGasResult"][@"text"]);
        NSArray *resultArr=[result componentsSeparatedByString:@"|"];
        if (resultArr.count<10) {
            return;
        }
        [self.chargeDetailView.gouqiLab setTitle:resultArr[1] forState:UIControlStateNormal];
        [self.chargeDetailView.shangbiaoBtn setTitle:resultArr[8] forState:UIControlStateNormal];
        [self.chargeDetailView.buchaBtn setTitle:resultArr[9] forState:UIControlStateNormal];
        [self showPayView];
        
        [self.DataArr removeAllObjects];
        [self.DataArr addObject:resultArr[8]];
        [self.DataArr addObject:resultArr[9]];
        [self.DataArr addObject:resultArr[17]];
        [self.DataArr addObject:resultArr[18]];
        [self.DataArr addObject:resultArr[19]];
        [self.DataArr addObject:resultArr[20]];
        [self.DataArr addObject:resultArr[21]];
        [self.DataArr addObject:resultArr[22]];
        [self.DataArr addObject:resultArr[2]];
        [self.DataArr addObject:resultArr[3]];
        [self.DataArr addObject:resultArr[4]];
        [self.DataArr addObject:resultArr[10]];
        [self.DataArr addObject:resultArr[11]];
        [self.DataArr addObject:resultArr[12]];
        [self.DataArr addObject:resultArr[5]];
        [self.DataArr addObject:resultArr[6]];
        [self.DataArr addObject:resultArr[7]];
        [self.DataArr addObject:resultArr[13]];
        [self.DataArr addObject:resultArr[14]];
        [self.DataArr addObject:resultArr[15]];
    }
    
    else if (request.tag==400)
    {
        NSDictionary *strDic=xml[@"IsWriteCResponse"][@"IsWriteCResult"][@"UserModel"];
        if (strDic.count==0)
        {
            //转跳支付页面
            [self.view addSubview:self.chargeDetailView];
        }
        else
        {
            //转跳写卡页面
            NSString *str;
            if (self.CarType==0)
            {
                self.writeView.KindLab.text=@"气   量";
                self.chargeDetailView.qiliangText.text=strDic[@"qiliang1"][@"text"];
                str=[NSString stringWithFormat:@"您上次未充卡气量为%@方",self.chargeDetailView.qiliangText.text];
            }
            else if (self.CarType==1)
            {
                self.writeView.KindLab.text=@"金   额";
                self.chargeDetailView.buyGasCountLab.text=strDic[@"ranqifei1"][@"text"];
                str=[NSString stringWithFormat:@"您上次未充卡金额为%@元",self.chargeDetailView.buyGasCountLab.text];
            }
            else if (self.CarType==2)
            {
                self.writeView.KindLab.text=@"金   额";
                self.chargeDetailView.shangbiaoBtn.titleLabel.text=strDic[@"SBiaoje"][@"text"];
                 str=[NSString stringWithFormat:@"您上次未充卡金额为%@元",self.chargeDetailView.shangbiaoBtn.titleLabel.text];
            }
            KDXAlertView *alert=[[KDXAlertView alloc] initWithTitle:str message:nil cancelButtonTitle:@"前往充值" cancelBlock:^{
                [self turnToWriteView];
            }];
            [alert show];
        }
    }
    
    else if (request.tag==1000)
    {
        NSString *resultStr=configEmpty(xml[@"UnionPayResponse"][@"UnionPayResult"][@"text"]);
        [SBPublicAlert hideMBprogressHUD:self.chargeDetailView];
        if (resultStr.length>0)
        {
            [[UPPaymentControl defaultControl] startPay:resultStr fromScheme:@"ylhappylife" mode:@"00" viewController:self];
        }
        SB_HUD_HIDE;
    }
    
    else if (request.tag==2000)
    {
        NSString *str=xml[@"WeiXinPayResponse"][@"WeiXinPayResult"][@"text"];
        NSArray *arr=[str componentsSeparatedByString:@"$"];
        NSString *Str0=arr[0];
        NSXMLParser *parse=[[NSXMLParser alloc] initWithData:[Str0 dataUsingEncoding:NSUTF8StringEncoding]];
        self.hank=1;
        [parse setDelegate:self];
        [parse parse];
        SB_HUD_HIDE;
    }
    
    else if (request.tag==3000)
    {
        [SBPublicAlert hideMBprogressHUD:self.chargeDetailView];
        [self ZfbAction];
    }
    else if (request.tag==4000)
    {
        NSString *str=xml[@"PurchaseGasResponse"][@"PurchaseGasResult"][@"text"];
        [self insertToDB:[str componentsSeparatedByString:@"|"][1]];
    }
    else if (request.tag==5000)
    {
        _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:self.carNum,@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"GouQiU"];
        [_helper asynServiceMethod:@"GouQiU" SoapMessage:soapMsg Tag:7000];
    }
    
    else if (request.tag==6000)
    {
        [self.chargeDetailView removeFromSuperview];
        [self turnToWriteView];
    }
    
    else if (request.tag==7000)
    {
        SB_HUD_HIDE;
        KDXAlertView *alert=[[KDXAlertView alloc] initWithTitle:@"写卡成功" message:nil
                                              cancelButtonTitle:@"ok" cancelBlock:^{
                                                  [self.navigationController popToRootViewControllerAnimated:YES];
                                              }];
        [alert show];

    }
}

-(void)showPayView
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    KDXActionSheet *actionSheet=[[KDXActionSheet alloc] initWithTitle:@"快捷支付" cancelButtonTitle:@"取消" cancelActionBlock:nil destructiveButtonTitle:nil destructiveActionBlock:nil];
    [actionSheet addButtonWithTitle:@"支付宝" actionBlock:^{
        [self ZfbPost];
    }];
    [actionSheet addButtonWithTitle:@"微信" actionBlock:^{
        [self WeChat];
    }];
    [actionSheet addButtonWithTitle:@"银联支付" actionBlock:^
     {
         [self Yinlian];
     }];
    [actionSheet showInView:self.chargeDetailView ];
}

-(void)getTotalMoney
{
    //非金额表购气
    SB_MBPHUD_SHOW(@"正在获取参数", self.chargeDetailView, NO);
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",self.chargeDetailView.carNumlab.text,self.chargeDetailView.qiliangText.text],@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"ComGas"];
    [self.helper asynServiceMethod:@"ComGas" SoapMessage:soapMsg Tag:300];
}

//主动断开设备
-(void)disConnect
{
    if (_discoveredPeripheral != nil)
    {
        NSLog(@"disConnect start");
        [self.mgr cancelPeripheralConnection:_discoveredPeripheral];
    }
}

//-(void)viewWillDisappear:(BOOL)animated
//{
//    [self disConnect];
//}


-(void)setArr:(NSString *)str
{
    NSString *xieyiStr=[self movieXieyi:str];
    
    NSString *strs=xieyiStr;
    int cCount;
    int ci=(int)strs.length/32;
    int bi=strs.length%32;
    if (ci==0)
    {
        cCount=1;
    }
    else if (bi!=0)
    {
        cCount=ci+1;
    }
    else
    {
        cCount=ci;
    }
    for (int i=0; i<cCount; i++)
    {
        NSString *arrStr;
        if (i!=cCount-1)
        {
            arrStr=[strs substringWithRange:NSMakeRange(i*32, 32)];
        }
        else
        {
            arrStr=[strs substringWithRange:NSMakeRange(i*32, strs.length-i*32)];
        }
        [_ReadArr addObject:arrStr];
    }
}

#pragma mark    ------SOcketMethod

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    NSLog(@"did connect to host");
}

int     WriteCount;
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"did read data");
    if (tag==1)
    {
        self.DNSResult=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        //效验密码,05 04 00 8961 cc
        _identify=@"效验密码";
        NSString *passWord=[self.DNSResult substringWithRange:NSMakeRange(12, 4)];
        NSString *String2=[self.DNSResult substringWithRange:NSMakeRange(16, 4)];
        if ([String2 isEqualToString:@"0000"])
        {
            passWord=[NSString stringWithFormat:@"050400%@cc",passWord];
        }
        else
        {
            passWord=[NSString stringWithFormat:@"070400%@%@cc",passWord,String2];
        }
        int ResultNum=[self getSixteenAddResult:passWord];
        NSString *newStr=[self ToHex:ResultNum];
        if (newStr.length>2)
        {
            newStr=[newStr substringFromIndex:1];
        }
        [self writeChar:[NSString stringWithFormat:@"%@%@",passWord,newStr]];
    }
    else if (tag==2)
    {
        self.DNSResult=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        /*
         写卡的代码
         */
        _identify=@"读卡";
        [_DnsDataArr removeAllObjects];
        
        //卡号
 
        self.carNum=[self.DNSResult substringWithRange:NSMakeRange(20, 10)];
        self.AddressLab.text=self.carNum;
        [self getjineACtion:[self.DNSResult substringWithRange:NSMakeRange(10, 2)] andStr:self.DNSResult];
        
        //读卡成功后，查询此卡在档案信息中是否存在
        NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
        _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",self.carNum,logerDic[@"phone"]],@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"BundingKaHaoQ"];
        [_helper asynServiceMethod:@"BundingKaHaoQ" SoapMessage:soapMsg Tag:100];

        /*
         写卡
         */
//        priceCount=0;
//        _WriteOrRead=@"写卡";
//        [self read102CartoBlueTooth:priceCount];
    }
    
    else if (tag==3)
    {
        self.DNSResult=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"---result=%@",self.DNSResult);
        WriteCount=0;
        [NSThread sleepForTimeInterval:0.5];
        _identify=@"写卡";
        [self writeTocard:WriteCount];
    }
    
    else if (tag==4)
    {
        self.DNSResult=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![self.DNSResult containsString:@"683081"]||![self.DNSResult containsString:@";"])
        {
            [UIAlertView showAlertViewWithTitle:@"写卡错误" message:nil];
        }
        else
        {
            self.DNSResult=[self.DNSResult substringWithRange:NSMakeRange(10, self.DNSResult.length-16)];
            _identify=@"写卡10";
            [self writeChar:[self movieXieyi:@"0084000008"]];
        }
    }
    
    else if (tag==5)
    {
        NSString *str=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![str containsString:@"683082"]||![str containsString:@";"])
        {
            [UIAlertView showAlertViewWithTitle:@"写卡错误" message:nil];
        }
        else
        {
            str=[str substringWithRange:NSMakeRange(10, str.length-16)];
            
            NSString *xieyiStr=[self movieXieyi:str];
            _ReadArr=[NSMutableArray array];
            
            NSString *strs=xieyiStr;
            int cCount;
            int ci=(int)strs.length/32;
            int bi=strs.length%32;
            if (ci==0)
            {
                cCount=1;
            }
            else if (bi!=0)
            {
                cCount=ci+1;
            }
            else
            {
                cCount=ci;
            }
            for (int i=0; i<cCount; i++)
            {
                NSString *arrStr;
                if (i!=cCount-1)
                {
                    arrStr=[strs substringWithRange:NSMakeRange(i*32, 32)];
                }
                else
                {
                    arrStr=[strs substringWithRange:NSMakeRange(i*32, strs.length-i*32)];
                }
                [_ReadArr addObject:arrStr];
            }
         
            priceCount=0;
            _identify=@"写卡11";
            [self writeChar:@"a5"];

            NSData *myData=[self hexToBytes:[self getNewNStr:_ReadArr[priceCount] andCom:priceCount]];
            [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
            [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
        }
    }
    
    else if (tag==6)
    {
        NSString *str=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![str containsString:@"683084"]||![str containsString:@";"])
        {
            [UIAlertView showAlertViewWithTitle:@"写卡错误" message:nil];
        }
        else
        {
            str=[str substringWithRange:NSMakeRange(10, str.length-16)];
            
            _identify=@"下电前一步";
            [self writeChar:[self movieXieyi:str]];
        }
    }
    
    else if (tag==7)
    {
        NSString *str=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![str containsString:@"683083"]||![str containsString:@";"])
        {
            [UIAlertView showAlertViewWithTitle:@"写卡错误" message:nil];
        }
        else
        {
            str=[str substringWithRange:NSMakeRange(10, str.length-16)];
            
            NSString *xieyiStr=[self movieXieyi:str];
            _ReadArr=[NSMutableArray array];
            
            NSString *strs=xieyiStr;
            int cCount;
            int ci=(int)strs.length/32;
            int bi=strs.length%32;
            if (ci==0)
            {
                cCount=1;
            }
            else if (bi!=0)
            {
                cCount=ci+1;
            }
            else
            {
                cCount=ci;
            }
            for (int i=0; i<cCount; i++)
            {
                NSString *arrStr;
                if (i!=cCount-1)
                {
                    arrStr=[strs substringWithRange:NSMakeRange(i*32, 32)];
                }
                else
                {
                    arrStr=[strs substringWithRange:NSMakeRange(i*32, strs.length-i*32)];
                }
                [_ReadArr addObject:arrStr];
            }
            
            priceCount=0;
            _identify=@"下电前一步";
            [self writeChar:@"a5"];
            
            NSData *myData=[self hexToBytes:[self getNewNStr:_ReadArr[priceCount] andCom:priceCount]];
            [_discoveredPeripheral writeValue:myData forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
            [_discoveredPeripheral readValueForCharacteristic:_A29Characteristric];
        }
    }
    
}

-(NSString *)getNewNStr:(NSString *)str andCom:(int)i
{
    //数据总包数
    int a=(int)_ReadArr.count;
    //当前数据包号
    int num=i;
    //当前包长度
    int LengthofPack=(int)str.length/2;
    //校验和
    int jyhNum=a+num+LengthofPack;
    for (int i=0; i<str.length/2; i++)
    {
        NSString *k=[str substringWithRange:NSMakeRange(i*2, 2)];
        NSLog(@"---k=%@",k);
        jyhNum+=[self getHexTen:k];
    }
    NSString *hexStr=[self ToHex:jyhNum];
    if (hexStr.length==1)
    {
        hexStr=[NSString stringWithFormat:@"0%@",hexStr];
    }
    else if (hexStr.length>2)
    {
        hexStr=[hexStr substringFromIndex:hexStr.length-2];
    }
    
    NSString *newStr=[NSString stringWithFormat:@"%02x%02x%02x%@%2@",a,num,LengthofPack,str,hexStr];
    return newStr;
}

-(int)getSixteenAddResult:(NSString *)str
{
    int ResultNum=0;
    for (int i=0; i<str.length/2; i++)
    {
        NSString *k=[str substringWithRange:NSMakeRange(i*2, 2)];
        ResultNum+=[self getHexTen:k];
    }
    return ResultNum;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

#pragma mark ---支付功能

-(void)ZfbPost
{
    SB_MBPHUD_SHOW(@"正在接入支付宝支付", self.chargeDetailView,NO);
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSString *strKahao=self.chargeDetailView.carNumlab.text;
    NSString *strPay;
    NSString *strCapacity;
    NSString *price=@"1";
    if (self.CarType==0||self.CarType==2)
    {
        strPay=self.chargeDetailView.gouqiLab.titleLabel.text;
        strCapacity=self.chargeDetailView.qiliangText.text;
    }
    else
    {
        strPay =self.chargeDetailView.buyGasCountLab.text;
        strCapacity=[NSString stringWithFormat:@"%lf",(double)([self.chargeDetailView.buyGasCountLab.text doubleValue]/[price doubleValue])];
        price=self.Danjia;
    }
    //购气次数
    NSString *buyGasTime=[self.DNSResult substringWithRange:NSMakeRange(30, 4)];
    NSMutableString *strIn0=[[NSMutableString alloc] init];
    for (int i=0; i<20; i++)
    {
        if (i==19)
        {
            [strIn0 appendString:self.DataArr[19]];
        }
        else
        {
            [strIn0 appendString:[NSString stringWithFormat:@"%@$",self.DataArr[i]]];
        }
    }
    
    /*
     支付宝支付
     [WebMethod(Description = "支付宝支付")]
     public int AlipayPay(string strParm)
     功    能：支付宝支付下订单 并将订单存入订单表中
     
     输入参数：strKahao（卡号） + strPay （金额）+ "1" （单价）+ strCapacity（气量）+ c（购气次数）+OrderN（订单号）+"民用"（用户类型）+"卡类型"+strSBiaoje（上表金额）+strBChaje（补差金额）+"$"+danjia+"$"+danjia2+"$"+danjia3+"$"+danjia4+"$"+danjia5+"$"+danjia6+"$"+Sg1+"$"+Sg2+"$"+Sg3+"$"+Sg4+"$"+Sg5+"$"+Sg6+"$"+Sm1+"$"+Sm2+"$"+Sm3+"$"+Sm4+"$"+Sm5+"$"+Sm6;
     */
    _tradeNo=[self generateTradeNO];
    _ChargeStr=strIn0;
    NSString *strIn=[NSString stringWithFormat:@"%@$%@$%@$%@$%d$%@$%@$%@$%@",strKahao,strPay,price,strCapacity,[self getHexTen:buyGasTime],_tradeNo,@"民用",@"102",strIn0];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:strIn,@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"AlipayPay"];
    [_helper asynServiceMethod:@"AlipayPay" SoapMessage:soapMsg Tag:3000];
}

-(void)ZfbAction
{
    NSString *partner =PartnerID;
    NSString *seller =SellerID;
    NSString *privateKey = PartnerPrivKey;
    
    /*
     *生成订单信息及签名
     */
    //将商品信息赋予AlixPayOrder的成员变量
    
    Order *order = [[Order alloc] init];
    order.partner = partner;
    order.seller = seller;
    order.tradeNO=_tradeNo;
    
    order.productName =@"燃气费充值"; //商品标题
    order.productDescription =@"kktt"; //商品描述
    if (self.CarType==0)
    {
        order.amount =self.chargeDetailView.gouqiLab.titleLabel.text; //商品价格
    }
    else if (self.CarType==2)
    {
        order.amount=[NSString stringWithFormat:@"%.2lf",[self.chargeDetailView.gouqiLab.titleLabel.text doubleValue]-[self.chargeDetailView.moneyCountlab.text doubleValue]];
    }
    else
    {
        order.amount =self.chargeDetailView.buyGasCountLab.text; //商品价格
    }
    
    order.notifyURL =@"http://125.76.225.60/PayNotifySer/BackRcvAlipay.aspx"; //回调URL
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showUrl = @"http://125.76.225.60/PayNotifySer/BackRcvAlipay.aspx";
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"com.easylif.cn";
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
//            支付成功
            if ([configEmpty(resultDic[@"resultStatus"]) isEqualToString:@"9000"])
            {
                _payMetohd=@"支付宝支付";
                [self ChargeSuccessful];
            }
            
        }];
    }
}

-(void)ChargeSuccessful
{
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSString *strKahao=self.chargeDetailView.carNumlab.text;
    NSString *strPay;
    NSString *strCapacity;
    NSString *price=@"1";
    if (self.CarType==0||self.CarType==2)
    {
        strPay=self.chargeDetailView.gouqiLab.titleLabel.text;
        strCapacity=self.chargeDetailView.qiliangText.text;
    }
    else
    {
        strPay =self.chargeDetailView.buyGasCountLab.text;
        strCapacity=[NSString stringWithFormat:@"%lf",(double)([self.chargeDetailView.buyGasCountLab.text doubleValue]/[price doubleValue])];
        price=self.Danjia;
    }
    //购气次数
    NSString *buyGasTime=[self.DNSResult substringWithRange:NSMakeRange(30, 4)];
        /*
     支付成功结果上传
     
     strKahao + "$" + strPay + "$"+ danjia + "$" + strCapacity + "$" + 够气次数+"$"+支付方式+"$"+OrderN+"$"+民用+"$"+"102"+"$"+strSBiaoje+"$"+strBChaje
     +"$"+danjia+"$"+danjia2+"$"+danjia3+"$"+danjia4+"$"+danjia5+"$"+danjia6+"$"+Sg1+"$"+Sg2+"$"+Sg3+"$"+Sg4+"$"+Sg5+"$"+Sg6
     +"$"+Sm1+"$"+Sm2+"$"+Sm3+"$"+Sm4+"$"+Sm5+"$"+Sm6;
     */
    
    NSString *strIn=[NSString stringWithFormat:@"%@$%@$%@$%@$%d$%@$%@$%@$%@$%@",strKahao,strPay,price,strCapacity,[self getHexTen:buyGasTime],_payMetohd,_tradeNo,@"民用",@"102",_ChargeStr];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:strIn,@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"PurchaseGas"];
    [_helper asynServiceMethod:@"PurchaseGas" SoapMessage:soapMsg Tag:4000];
}

-(void)insertToDB:(NSString *)time
{
//    strKahao（卡号）+ strM（金额）+ strDat（日期）+ strCardType（卡类型）+ PaymentMe（支付方式）+ OrderN（订单号）
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSString *strKahao=self.chargeDetailView.carNumlab.text;
    NSString *strPay;
    if (self.CarType==0||self.CarType==2)
    {
        strPay=self.chargeDetailView.gouqiLab.titleLabel.text;
    }
    else
    {
        strPay =self.chargeDetailView.buyGasCountLab.text;
    }
    NSString *strIn=[NSString stringWithFormat:@"%@$%@$%@$%@$%@$%@",strKahao,strPay,time,@"102",_payMetohd,_tradeNo];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:strIn,@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"PurchaseGas"];
    [_helper asynServiceMethod:@"PurchaseGas" SoapMessage:soapMsg Tag:6000];
}

-(void)turnToWriteView
{
    self.writeView=[[NSBundle mainBundle] loadNibNamed:@"WriteCardView" owner:self options:nil][0];
    self.writeView.frame=CGRectMake(0, 65, winsize.width, winsize.height-65);
    [self.view addSubview:self.writeView];
    self.writeView.carLab.text=self.carNum;
    if (self.CarType==0)
    {
        self.writeView.KindLab.text=@"气   量";
        self.writeView.JinElab.text=self.chargeDetailView.qiliangText.text;
    }
    else if (self.CarType==1)
    {
        self.writeView.KindLab.text=@"金   额";
        self.writeView.JinElab.text=self.chargeDetailView.buyGasCountLab.text;
    }
    else if (self.CarType==2)
    {
        self.writeView.KindLab.text=@"气   量";
        self.writeView.JinElab.text=self.chargeDetailView.shangbiaoBtn.titleLabel.text;
    }
    [self.writeView.writeBtn addTarget:self action:@selector(writeCard) forControlEvents:UIControlEventTouchUpInside];
}

-(void)writeCard
{
    /*
     写卡
     */
    SB_MBPHUD_SHOW(@"正在写卡", self.view, NO);
    if (_is102Card)
    {
        priceCount=0;
        _WriteOrRead=@"写卡";
        [self read102CartoBlueTooth:priceCount];
    }
    else
    {
        _WriteOrRead=@"写卡";
        _identify=@"写卡1";
        NSString *writeStr=@"010203";
        [self writeChar:writeStr];
    }
}

-
(void)WeChat
{
    [self WeChatPay];
}

-(void)WeChatPay
{
    SB_MBPHUD_SHOW(@"加载中...", self.view, NO);
    //请求后台获取微信支付参数
    NSString *strKahao=self.chargeDetailView.carNumlab.text;
    NSString *strPay;
    NSString *strCapacity;
    NSString *price=@"1";
    if (self.CarType==0||self.CarType==2)
    {
        strPay=self.chargeDetailView.gouqiLab.titleLabel.text;
        strCapacity=self.chargeDetailView.qiliangText.text;
    }
    else
    {
        strPay =self.chargeDetailView.buyGasCountLab.text;
        strCapacity=[NSString stringWithFormat:@"%lf",(double)([self.chargeDetailView.buyGasCountLab.text doubleValue]/[price doubleValue])];
        price=self.Danjia;
    }
    NSString *buyGasTime=[self.DNSResult substringWithRange:NSMakeRange(30, 4)];
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    
    
    //    strKahao（卡号） + strPay （金额）+ "1" （单价）+ strCapacity（气量）+ c（购气次数）+"民用"（用户类型）+"卡类型"+strSBiaoje（上表金额）+strBChaje（补差金额）+"$"+danjia+"$"+danjia2+"$"+danjia3+"$"+danjia4+"$"+danjia5+"$"+danjia6+"$"+Sg1+"$"+Sg2+"$"+Sg3+"$"+Sg4+"$"+Sg5+"$"+Sg6+"$"+Sm1+"$"+Sm2+"$"+Sm3+"$"+Sm4+"$"+Sm5+"$"+Sm6;

    NSMutableString *strIn0=[[NSMutableString alloc] init];
    for (int i=0; i<20; i++)
    {
        if (i==19)
        {
            [strIn0 appendString:self.DataArr[19]];
        }
        else
        {
            [strIn0 appendString:[NSString stringWithFormat:@"%@$",self.DataArr[i]]];
        }
    }
    
    NSString *strIn=[NSString stringWithFormat:@"%@$%@$%@$%@$%d$%@$%@$%@",strKahao,strPay,price,strCapacity,[self getHexTen:buyGasTime],@"民用",@"102",strIn0];
    
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:strIn,@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"WeiXinPay"];
    [_helper asynServiceMethod:@"WeiXinPay" SoapMessage:soapMsg Tag:2000];
}

-(void)Yinlian
{
//    输入参数：strKahao（卡号） + strPay （金额）+ "1" （单价）+ strCapacity（气量）+ c（购气次数）+OrderN（订单号）+"民用"（用户类型）+"卡类型"+strDate（订单日期）;
    //    参数之间用$隔开
    
    SB_MBPHUD_SHOW(@"正在接入银联支付", self.chargeDetailView, NO);
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    
    NSString *strKahao=self.chargeDetailView.carNumlab.text;
    NSString *strPay;
    NSString *strCapacity;
    NSString *price=@"1";
    if (self.CarType==0||self.CarType==2)
    {
        strPay=self.chargeDetailView.gouqiLab.titleLabel.text;
        strCapacity=self.chargeDetailView.qiliangText.text;
    }
    else
    {
        strPay =self.chargeDetailView.buyGasCountLab.text;
        strCapacity=[NSString stringWithFormat:@"%lf",(double)([self.chargeDetailView.buyGasCountLab.text doubleValue]/[price doubleValue])];
        price=self.Danjia;
    }
    //购气次数
    NSString *buyGasTime=[self.DNSResult substringWithRange:NSMakeRange(30, 4)];
    NSDateFormatter *dateformat=[[NSDateFormatter alloc] init];
    dateformat.dateFormat=@"yyyyMMddHHmmss";
    NSString *date=[dateformat stringFromDate:[NSDate date]];
    
   //   strKahao（卡号） + strPay （金额）+ "1" （单价）+ strCapacity（气量）+ c（购气次数）+OrderN（订单号）+"民用"（用户类型）+"卡类型"+strDate（订单发送日期）+strSBiaoje（上表金额）+strBChaje（补差金额）+"$"+danjia+"$"+danjia2+"$"+danjia3+"$"+danjia4+"$"+danjia5+"$"+danjia6+"$"+Sg1+"$"+Sg2+"$"+Sg3+"$"+Sg4+"$"+Sg5+"$"+Sg6+"$"+Sm1+"$"+Sm2+"$"+Sm3+"$"+Sm4+"$"+Sm5+"$"+Sm6;
    NSMutableString *strIn0=[[NSMutableString alloc] init];
    for (int i=0; i<20; i++)
    {
        if (i==19)
        {
            [strIn0 appendString:self.DataArr[19]];
        }
        else
        {
            [strIn0 appendString:[NSString stringWithFormat:@"%@$",self.DataArr[i]]];
        }
    }
    _tradeNo=[self generateTradeNO];
    NSString *strIn=[NSString stringWithFormat:@"%@$%@$%@$%@$%d$%@$%@$%@$%@$%@",strKahao,strPay,price,strCapacity,[self getHexTen:buyGasTime],_tradeNo,@"民用",@"102",date,strIn0];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:strIn,@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"UnionPay"];
    [_helper asynServiceMethod:@"UnionPay" SoapMessage:soapMsg Tag:1000];
}

- (NSString *)generateTradeNO
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    for (int i = 0; i < kNumber; i++)
    {
        long index = random()%[sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    NSLog(@"===订单号:%@",resultStr);
    return resultStr;
}

//微信支付结果回调
-(void)yinlianPayResult:(NSNotification *)obj
{
    //1的时候是成功，2失败,3取消
    int a=[[NSString stringWithFormat:@"%@",[obj object]] intValue];
    if (a==1)
    {
        _payMetohd=@"银行卡支付";
        [self ChargeSuccessful];
    }
    else if (a==2)
    {
        [UIAlertView showAlertViewWithTitle:@"支付失败" message:nil];
    }
    else
    {
//        [UIAlertView showAlertViewWithTitle:@"支付取消" message:nil];
        //支付取消
    }
}

- (void)dealloc
{
    NSLog(@"-CANCEL_REQUEST");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CANCEL_REQUEST;
}

/*
 金额
*/
-(void)getjineACtion:(NSString *)num andStr:(NSString *)str
{
    if ([num intValue]==01)
    {
        //气量
        self.jinEstr=[self getRecentTotalMoney:[str substringWithRange:NSMakeRange(12, 8)]];
    }
    else if ([num intValue]==02)
    {
        //金额
        self.jinEstr=[self getRecentTotalMoney:[str substringWithRange:NSMakeRange(12, 8)]];
    }
    else if ([num intValue]==03)
    {
        //气量
        self.jinEstr=[self getRecentTotalMoney:[str substringWithRange:NSMakeRange(12, 8)]];
    }
    else if ([num intValue]==04)
    {
        //金额
        self.jinEstr=[self getRecentTotalMoney:[str substringWithRange:NSMakeRange(12, 8)]];
    }
}
-(NSString *)getRecentTotalMoney:(NSString *)str
{
    int TotalCount=0;
    for (int i=0; i<4; i++)
    {
        NSString *num=[str substringWithRange:NSMakeRange(i*2, 2)];
        NSLog(@"---Result==%@",num);
        if (i<2)
        {
            TotalCount+=[self getResult:[num intValue] andCount:(2-i)];
        }
        else if (i==2)
        {
            TotalCount+=[self getHexTen:num];
        }
        else
        {
            int number=[self getHexTen:num]*0.1;
            TotalCount+=number;
        }
    }
    return [NSString stringWithFormat:@"%d",TotalCount];
}


//幂运算
-(int)getResult:(int)a andCount:(int)k
{
    int result=a;
    for (int i=0; i<k; i++) {
        result*=256;
    }
    return result;
}


#pragma mark ----XMl解析

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    parserObjects = [[NSMutableArray alloc]init];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
        NSLog(@"www---%@",NSStringFromSelector(_cmd) );
    
    if ([elementName isEqualToString:@"item"]) {
        NSMutableDictionary *newNode = [[ NSMutableDictionary alloc ] initWithCapacity : 0 ];
        [parserObjects addObject :newNode];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSLog(@"-----首节点内容:%@",NSStringFromSelector(_cmd) );
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSLog(@"----解析完节点: %@",NSStringFromSelector(_cmd) );
}  

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    
}
//获取cdata块数据
- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    NSString *str=[[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    NSLog(@"--Str=%@",str);
    if (self.hank==5)
    {
        self.WeChatnonceStr=str;
    }
    if (self.hank==6)
    {
        self.WeChatSign=str;
    }
    else if (self.hank==8)
    {
        self.PreayId=str;
        PayReq* req             = [[PayReq alloc] init];
        req.openID=@"wx33467def475933e7";
        req.partnerId = @"1319731201";
        req.prepayId= str;
        req.package =@"Sign=WXPay";
        req.timeStamp=[[NSDate date] timeIntervalSince1970];
        req.nonceStr= self.WeChatnonceStr;
        req.sign=[self createMD5SingForPayWithAppID:@"wx33467def475933e7" partnerid:@"1319731201" prepayid:str package:@"Sign=WXPay" noncestr:req.nonceStr timestamp:req.timeStamp];
        [WXApi sendReq:req];
    }
    self.hank++;
}

//写卡成功后更新购气表状态
-(void)ChangeDNsGasDBState:(NSString *)str
{
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:str,@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"GouQiU"];
    [_helper asynServiceMethod:@"GouQiU" SoapMessage:soapMsg Tag:5000];
}

-(NSString *)createMD5SingForPayWithAppID:(NSString *)appid_key partnerid:(NSString *)partnerid_key prepayid:(NSString *)prepayid_key package:(NSString *)package_key noncestr:(NSString *)noncestr_key timestamp:(UInt32)timestamp_key
{
    NSMutableDictionary *signParams = [NSMutableDictionary dictionary];
    [signParams setObject:appid_key forKey:@"appid"];//微信appid 例如wxfb132134e5342
    [signParams setObject:noncestr_key forKey:@"noncestr"];//随机字符串
    [signParams setObject:package_key forKey:@"package"];//扩展字段  参数为 Sign=WXPay
    [signParams setObject:partnerid_key forKey:@"partnerid"];//商户账号
    [signParams setObject:prepayid_key forKey:@"prepayid"];//此处为统一下单接口返回的预支付订单号
    [signParams setObject:[NSString stringWithFormat:@"%u",timestamp_key] forKey:@"timestamp"];//时间戳
    
    NSMutableString *contentString  =[NSMutableString string];
    NSArray *keys = [signParams allKeys];
    //按字母顺序排序
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接字符串
    for (NSString *categoryId in sortedArray) {
        if (   ![[signParams objectForKey:categoryId] isEqualToString:@""]
            && ![[signParams objectForKey:categoryId] isEqualToString:@"sign"]
            && ![[signParams objectForKey:categoryId] isEqualToString:@"key"]
            )
        {
            [contentString appendFormat:@"%@=%@&", categoryId, [signParams objectForKey:categoryId]];
        }
    }
    //添加商户密钥key字段  API 密钥
    [contentString appendFormat:@"key=%@", WX_API_KEY];
    NSString *result = [self md5String:contentString];//md5加密
    return result;
}

/**
 *  MD5 加密
 *
 *  @return 加密后字符串
 */
- (NSString *)md5String:(NSString *)str
{
    if(str == nil || [str length] == 0) return nil;
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([str UTF8String], (int)[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    NSMutableString *ms = [NSMutableString string];
    for(i=0;i<CC_MD5_DIGEST_LENGTH;i++)
    {
        [ms appendFormat: @"%02x", (int)(digest[i])];
    }
    return [ms copy];
}


//将字符串进行MD5加密，返回加密后的字符串
-(NSString *) md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (unsigned int)strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02X", digest[i]];
    
    return output;
}


@end




