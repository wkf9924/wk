//
//  BdViewController.m
//  HappyLife
//
//  Created by mac on 16/4/11.
//  Copyright © 2016年 mac. All rights reserved.
//
#import "AsyncSocket.h"
#import "BdViewController.h"
#import "NearByModal.h"

#define ScanTimeInterval 1.0

#define POSTNUMURL      @"www.prmt.cn"

@interface BdViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate,ZSYPopoverListDelegate,ZSYPopoverListDatasource,AsyncSocketDelegate>

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
@property (nonatomic,copy)NSMutableString          *litterString;

//是否是102卡
@property (nonatomic,assign)    BOOL               is102Card;

@property (nonatomic,copy)     NSString             *WriteOrRead;

@property (nonatomic,assign)     BOOL                 AlreadyBanding;

@property (nonatomic,copy)     NSString              *CarTypeStr;

@property (nonatomic,copy)     NSMutableString       *ShipinStr;//写00b000002A命令时候拼接的字符串

@end

@implementation BdViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"添加燃气表";
    [self setBackBarButton];
    [self setDoneBarButtonWithSelector:@selector(SearchBlueTooth) andTitle:@"搜索"];
    NSString *state=[[Config Instance] getBandingStatus][@"state"];
    self.AlreadyBanding=[state intValue]==1?YES:NO;
//    if (self.AlreadyBanding)
//    {
//        [self startSearch];
//    }
    BOOL toolState=[[Config Instance] getBlutToothConnectState];
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
        self.BlueToothLab.text=[[Config Instance] getBlutToothNo];
    }
    _m_Tableview=[[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 250, 200)];
    _m_Tableview.titleName.text=@"搜索到的设备";
    _m_Tableview.delegate=self;
    _m_Tableview.datasource=self;
    [_m_Tableview dismiss];
    _DnsDataArr=[NSMutableArray array];
    _litterString=[[NSMutableString alloc] init];
    _is102Card=NO;
}

-(void)SearchBlueTooth
{
    [self startSearch];
}

-(IBAction)ReadUserdofblueTooth:(id)sender
{
    if (_BlueToothLab.text.length==0&&![[Config Instance] getBlutToothConnectState])
    {
        return;
    }
    if (_is102Card)
    {
        SB_SHOW_Time_HIDE(@"读卡中..", self.view, 5);
        _identify=@"选择卡类型";
        NSString *writeStr=@"02010003";
        [self writeChar:writeStr];
    }
    
    else
    {
        SB_SHOW_Time_HIDE(@"读卡中..", self.view, 5);
        _identify=@"选择卡类型";
        NSString *writeStr=@"010203";
        [self writeChar:writeStr];
    }
}

-(IBAction)gotoBangdingAction:(id)sender
{
    if (_bangdingState==NO_PERSON)
    {
        [UIAlertView showAlertViewWithTitle:@"此用户不存在!" message:nil];
        return;
    }
    else if (_bangdingState==OUT_NETWORK)
    {
        [UIAlertView showAlertViewWithTitle:@"连接服务器失败!" message:nil];
        return;
    }
    
    else if (_bangdingState==ALREADY_EXIST)
    {
        [UIAlertView showAlertViewWithTitle:@"此卡已经绑定" message:nil];
        return;
    }
    else if (_bangdingState==BEN_BANDING)
    {
        [UIAlertView showAlertViewWithTitle:@"此卡已经被其他账号绑定" message:nil];
        return;
    }
    
    NSString *state=[[Config Instance] getBandingStatus][@"state"];
    
    SB_MBPHUD_SHOW(@"正在绑定", self.view, NO);
    NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@$%@$%@$%@$%@",logerDic[@"phone"],self.carNumLab.text,self.BlueToothLab.text,state,@"民用",@"卡类型"],@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"Bunding"];
    [_helper asynServiceMethod:@"Bunding" SoapMessage:soapMsg Tag:300];
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

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
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
    self.BlueToothLab.text=modal.macAddress;
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
    NSLog(@"已失去连接 %@",peripheral);
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
            [CentralManager Instance].writeCharacteristic=_writeCharacteristic;
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
int     priceCounts;
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
        
        if (_is102Card)
        {
            if ([newStr isEqualToString:@"aa"]&&[_identify isEqualToString:@"选择卡类型"])
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
                priceCounts=0;
                _WriteOrRead=@"读卡";
                [self read102CartoBlueTooth:priceCounts];
            }
            
            if ([_identify isEqualToString:@"读卡"]&&str.length>17)
            {
                NSString *baoshu=[str substringWithRange:NSMakeRange(1, 2)];
                NSString *currentBaoshu=[str substringWithRange:NSMakeRange(3, 2)];
                NSMutableString *shuju=[[NSMutableString alloc]initWithString:[str substringWithRange:NSMakeRange(7, str.length-10)]];
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
                    priceCounts+=1;
                    [self read102CartoBlueTooth:priceCounts];
                }
                [self writeChar:@"a5"];
            }
            
            if ([_identify isEqualToString:@"写卡"]&&[newStr1 isEqualToString:@"aa 00"])
            {
                [self writeChar:@"a5"];
                [self writeDataToBlueTooth:WriteCounts];
            }
            if ([_identify isEqualToString:@"写卡第二部，给卡上写数据"]&&[newStr1 isEqualToString:@"aa 00"])
            {
                NSLog(@"----写卡成功----");
                [self writeChar:@"a5"];
                WriteCounts++;
                _identify=@"写卡";
                [self writeTocard:WriteCounts];
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
                    [self ReadUserdofblueTooth:nil];
                }
                else
                {
                    if (RangeStr.length<32)
                    {
                        _identify=@"卡上公用区22个数据";
                        priceCounts=0;
                        [self writeChar:[self movieXieyi:@"00a40000023f01"]];
                    }
                }
            }
            
            else  if ([_identify isEqualToString:@"卡上公用区22个数据"])
            {
                if (priceCounts==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                priceCounts++;
                NSString *count=[str substringWithRange:NSMakeRange(2, 1)];
                if ([count intValue]>priceCounts)
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
                priceCounts=0;
                _DNSdataStr=[[NSMutableString alloc] init];
                _CarTypeStr=[[NSString alloc] init];
                [self writeChar:[self movieXieyi:@"00b000000c"]];
            }
            
           else if ([_identify isEqualToString:@"视频卡2"])
            {
                NSMutableString *RangeStr;
                if (priceCounts==0)
                {
                    if (![newStr isEqualToString:@"aa"])
                    {
                        return;
                    }
                    else
                    {
                        RangeStr=[[NSMutableString alloc] initWithString:str];
                        [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                        
                        self.carNumLab.text=[RangeStr substringWithRange:NSMakeRange(15, 10)];
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
                    priceCounts++;
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
                        priceCounts=0;
                        _DNSdataStr=[[NSMutableString alloc] init];
                        [self writeChar:@"a5"];
                        [self writeChar:[self movieXieyi:@"00b000002A"]];
                    }
                    else
                    {
                        _identify=@"不包含9000步骤1";
                        priceCounts=0;
                        [self writeChar:@"a5"];
                        _ShipinStr=[[NSMutableString alloc] init];
                        [self writeChar:[self movieXieyi:@"00a40000020007"]];
                    }
                }
                else
                {
                    priceCounts++;
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
            }
            
            else if ([_identify isEqualToString:@"包含9000步骤1"])
            {
                if (priceCounts==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceCounts++;
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                if (RangeStr.length<42)
                {
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    [_DNSdataStr replaceCharactersInRange:NSMakeRange(0, 8) withString:@""];
                    [_DNSdataStr replaceCharactersInRange:NSMakeRange(_DNSdataStr.length-6, 6) withString:@""];
                    _identify=@"包含9000步骤2";
                    priceCounts=0;
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
                if (priceCounts==0)
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
                        priceCounts=0;
                        _DNSdataStr=[[NSMutableString alloc] init];
                        [self writeChar:[self movieXieyi:@"00b0000028"]];
                    }
                }
                else
                {
                    priceCounts++;
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                }
            }
            
            else if ([_identify isEqualToString:@"包含9000步骤2"])
            {
                if (priceCounts==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceCounts++;
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                if (RangeStr.length<42)
                {
                    [_ShipinStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    [_ShipinStr replaceCharactersInRange:NSMakeRange(0, 8) withString:@""];
                    [_ShipinStr replaceCharactersInRange:NSMakeRange(_ShipinStr.length-6, 6) withString:@""];
                    [_DNSdataStr appendString:_ShipinStr];
                    _identify=@"包含9000步骤3";
                    priceCounts=0;
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
                if (priceCounts==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceCounts++;
                NSMutableString * RangeStr=[[NSMutableString alloc] initWithString:str];
                [RangeStr replaceOccurrencesOfString:@" " withString:@"" options:1 range:NSMakeRange(0, RangeStr.length)];
                if (RangeStr.length<42)
                {
                    [_DNSdataStr appendString:[RangeStr substringWithRange:NSMakeRange(7, RangeStr.length-10)]];
                    [_DNSdataStr replaceCharactersInRange:NSMakeRange(0, 8) withString:@""];
                    [_DNSdataStr replaceCharactersInRange:NSMakeRange(_DNSdataStr.length-6, 6) withString:@""];
                    _identify=@"不包含9000步骤3";
                    priceCounts=0;
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
                if (priceCounts==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceCounts++;
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
                if (priceCounts==0&&![newStr isEqualToString:@"aa"])
                {
                    return;
                }
                [self writeChar:@"a5"];
                priceCounts++;
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
                priceCounts=0;
                [self writeChar:[self movieXieyi:@"010809"]];
            }
            
            else if ([_identify isEqualToString:@"步骤11"]&&![newStr isEqualToString:@"aa"])
            {
                //读卡完毕
                if (priceCounts==0)
                {
                    //读卡成功后，查询此卡在档案信息中是否存在
                    NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
                    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
                    NSMutableArray *arr=[NSMutableArray array];
                    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",self.carNumLab.text,logerDic[@"phone"]],@"strParm", nil]];
                    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"BundingKaHaoQ"];
                    [_helper asynServiceMethod:@"BundingKaHaoQ" SoapMessage:soapMsg Tag:200];
                }
                priceCounts++;
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
            //        后台要求读取的数据，每组数据中间用|隔开
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
            NSString *qiliang=[NSString stringWithFormat:@"%@",[self.DNSResult substringWithRange:NSMakeRange(12, 8)]];
            NSString *cishu=[self.DNSResult substringWithRange:NSMakeRange(30, 4)];
            NSString *shuzu=[self.DNSResult substringWithRange:NSMakeRange(34, 2)];
            NSString *NewStr=[NSString stringWithFormat:@"683013%@%@%@%@%@%@AA16",changdu,changjia,qiliang,cishu,shuzu,str];
            
            self.socket=[[AsyncSocket alloc] initWithDelegate:self];
            [self.socket connectToHost:POSTNUMURL onPort:5002 error:nil];
            self.socket.delegate=self;
            [self.socket readDataWithTimeout:5 tag:3];
            NSData *dataStr=[NewStr dataUsingEncoding:NSUTF8StringEncoding];
            [self.socket writeData:dataStr withTimeout:5 tag:3];
        }
    }
}

//写卡
-(void)writeTocard:(int)a
{
    NSString *quhao;
    NSString *weizhi;
    NSString *changdu;
    NSString *jiaoyan;
    NSString *zushu=[self.DNSResult substringWithRange:NSMakeRange(10, 2)];
    if ([zushu intValue]>a)
    {
        quhao=[self.DNSResult substringWithRange:NSMakeRange(12+a*6, 2)];
        weizhi=[self.DNSResult substringWithRange:NSMakeRange(14+a*6, 2)];
        changdu=[self.DNSResult substringWithRange:NSMakeRange(16+a*6, 2)];
        NSLog(@"---quhao:%@ weizhi: %@ changdu :%@",quhao,weizhi,changdu);
        NSString *str=[NSString stringWithFormat:@"060A%@00%@00%@",quhao,weizhi,changdu];
        int addStr=[self getSixteenAddResult:str];
        jiaoyan=[self ToHex:addStr];
        NSString *charStr=[NSString stringWithFormat:@"%@%@",str,jiaoyan];
        [self writeChar:charStr];
    }
}


-(void)writeDataToBlueTooth:(int)a
{
    NSString *zushu=[self.DNSResult substringWithRange:NSMakeRange(10, 2)];
    if ([zushu intValue]>a)
    {
        _identify=@"写卡第二部，给卡上写数据";
        NSString *str=[self.DNSResult substringWithRange:NSMakeRange(12+6*[zushu intValue], self.DNSResult.length-(12+6*[zushu intValue]))];
        NSLog(@"--str=%@",str);
        NSString *charStr=[str componentsSeparatedByString:@"|"][a];
        [self writeChar:charStr];
    }
}

//视频卡协议
-(NSString *)movieXieyi:(NSString *)str
{
    NSMutableString *NewStr=[[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"0602%@",str]];
    NewStr=[NSMutableString stringWithFormat:@"%02d%@",(int)NewStr.length/2,NewStr];
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
    [self judjeIfBlueToothisBanding:modal.macAddress];
}

-(void)popoverListView:(ZSYPopoverListView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

-(void)judjeIfBlueToothisBanding:(NSString *)Mac
{
    _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:Mac,@"strParm",nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"BluetoothOrConnection"];
    [_helper asynServiceMethod:@"BluetoothOrConnection" SoapMessage:soapMsg Tag:100];
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==100)
    {
        NSString *resultStr=xml[@"BluetoothOrConnectionResponse"][@"BluetoothOrConnectionResult"][@"text"];
        if ([resultStr intValue]==-1)
        {
            SB_MBPHUD_HIDE(@"已被绑定", 3);
            [self.m_Tableview dismiss];
        }
        else if ([resultStr intValue]==0)
        {
            SB_MBPHUD_HIDE(@"连接服务器失败", 3);
            [self.m_Tableview dismiss];
        }
        else if ([resultStr intValue]==1)
        {
            
            NearByModal *modal = self.peripherals[_MacPosition];
            
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
    }
    else if (request.tag==200)
    {
        NSString *str=configEmpty(xml[@"BundingKaHaoQResponse"][@"BundingKaHaoQResult"][@"text"]);
        NSArray *strArr=[str componentsSeparatedByString:@"|"];
        SB_HUD_HIDE;
        if ([str isEqualToString:@"1|0"])
        {
            //此用户不存在,可以绑定;
            [UIAlertView showAlertViewWithTitle:@"此用户不存在!" message:nil];
            _bangdingState=NO_PERSON;
        }
        else if ([str isEqualToString:@"0|0"])
        {
            [UIAlertView showAlertViewWithTitle:@"连接服务器失败!" message:nil];
            _bangdingState=OUT_NETWORK;
        }
        else if ([strArr[0] isEqualToString:@"2"])
        {
            self.nameLab.text=strArr[1];
            self.AddressLab.text=strArr[2];
            _bangdingState=ALREADY_EXIST;
        }
        else if ([strArr[0] isEqualToString:@"3"])
        {
            [UIAlertView showAlertViewWithTitle:@"此卡已经被其他账号绑定" message:nil];
            _bangdingState=BEN_BANDING;
        }
        else if ([strArr[0] isEqualToString:@"4"])
        {
            self.nameLab.text=strArr[1];
            self.AddressLab.text=strArr[2];
            _bangdingState=COULD_BANDING;
        }
    }
    else if (request.tag==300)
    {
        NSString *str=configEmpty(xml[@"BundingResponse"][@"BundingResult"][@"text"]);
        NSArray *strArr=[str componentsSeparatedByString:@"|"];
        NSString *str0=strArr[0];
        if ([str0 isEqualToString:@"-3"])
        {
            SB_MBPHUD_HIDE(@"蓝牙设备失效", 3);
        }
        else if ([str0 isEqualToString:@"-2"])
        {
            SB_MBPHUD_HIDE(@"绑定失败", 3);
        }
        else if ([str0 isEqualToString:@"-1"])
        {
            SB_MBPHUD_HIDE(@"此用户不存在", 3);
        }
        else if ([str0 isEqualToString:@"0"])
        {
            SB_MBPHUD_HIDE(@"连接服务器失败", 3);
        }
        else if ([str0 isEqualToString:@"1"])
        {
//             1|userType|MeterType|CardTypeD|strTel|strDate 绑定成功
            SB_MBPHUD_HIDE(@"绑定成功", 1);
            [[Config Instance] judjeIfBlueToothisBanging:@{@"state":@"1",@"num":self.BlueToothLab.text}];
            
            NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
            NSString *state=[[Config Instance] getBandingStatus][@"state"];
            _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
            NSMutableArray *arr=[NSMutableArray array];
            [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@$%@$%@$%@$%@",logerDic[@"phone"],self.carNumLab.text,self.BlueToothLab.text,state,@"民用",@"卡类型"],@"strParm", nil]];
            NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"Bunding"];
            [_helper asynServiceMethod:@"Bunding" SoapMessage:soapMsg Tag:400];
        }
        
        else if ([str0 isEqualToString:@"5"])
        {
            SB_MBPHUD_HIDE(@"最多只可以绑定5个用户", 3);
        }
        else if ([str0 isEqualToString:@"8"])
        {
            SB_MBPHUD_HIDE(@"此用户已被绑定", 3);
        }
    }
}

-(void)finishFailRequest:(NSError*)error
{
    NSLog(@"异步请发生失败:%@\n",[error description]);
    SB_MBPHUD_HIDE(@"请检查网络", 3)
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


#pragma mark    ------SOcketMethod

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    NSLog(@"did connect to host");
}

int     WriteCounts;
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
        self.carNumLab.text=[self.DNSResult substringWithRange:NSMakeRange(20, 10)];
        
        //读卡成功后，查询此卡在档案信息中是否存在
        NSDictionary *logerDic=[[Config Instance] getPhoneAndPass];
        _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",self.carNumLab.text,logerDic[@"phone"]],@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"BundingKaHaoQ"];
        [_helper asynServiceMethod:@"BundingKaHaoQ" SoapMessage:soapMsg Tag:200];
    }
    
    else if (tag==3)
    {
        self.DNSResult=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        WriteCounts=0;
        _identify=@"写卡";
        [self writeTocard:WriteCounts];
    }
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

- (void)dealloc
{
    CANCEL_REQUEST
}

@end

