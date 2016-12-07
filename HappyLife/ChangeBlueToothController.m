//
//  ChangeBlueToothController.m
//  HappyLife
//
//  Created by mac on 16/5/18.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "ChangeBlueToothController.h"
#import "NearByModal.h"
#define ScanTimeInterval 1.0

@interface ChangeBlueToothController ()<CBCentralManagerDelegate,CBPeripheralDelegate,ZSYPopoverListDelegate,ZSYPopoverListDatasource>

@property (nonatomic,strong)ZSYPopoverListView *m_Tableview;
// 中央设备
@property (nonatomic, strong) CBCentralManager *mgr;
// 外部设备
@property (nonatomic, strong) NSMutableArray *peripherals;

@property (nonatomic, strong) NSTimer *timer;

//被连接蓝牙设备在数组中的位置
@property (nonatomic, assign) NSInteger        MacPosition;

@end

@implementation ChangeBlueToothController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"更换蓝牙设备";
    [self setBackBarButton];
    [self setDoneBarButtonWithSelector:@selector(SearchBlueTooth) andTitle:@"搜索"];
    
    _m_Tableview=[[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 270, 200)];
    _m_Tableview.titleName.text=@"搜索到的设备";
    _m_Tableview.delegate=self;
    _m_Tableview.datasource=self;
    [self startSearch];
}

-(void)SearchBlueTooth
{
    [self startSearch];
}

/*
 更换蓝牙设备
 */
-(IBAction)ChangeBlueToothBtn:(id)sender
{
    if (self.textfield.text.length<5)
    {
        return;
    }
    
    KDXAlertView *alert=[[KDXAlertView alloc] initWithTitle:@"确认更换蓝牙设备" message:nil cancelButtonTitle:@"确定" cancelBlock:^
    {
        SB_MBPHUD_SHOW(@"正在更换...", self.view, NO);
        
        _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
        NSMutableArray *arr=[NSMutableArray array];
        [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",[[Config Instance] getPhoneAndPass][@"phone"],self.textfield.text],@"strParm", nil]];
        NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"ChangeB"];
        [_helper asynServiceMethod:@"ChangeB" SoapMessage:soapMsg Tag:200];
    }];
    [alert addButtonWithTitle:@"取消 " actionBlock:nil];
    [alert show];
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
    SB_MBPHUD_SHOW(@"搜索中...", self.m_Tableview, NO);
    [self.m_Tableview show];
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

- (void)stopScanss
{
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
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    [SBPublicAlert hideMBprogressHUD:self.m_Tableview];
    BOOL isExist = NO;
    if (!([peripheral.name isEqual:@"(null)"] || peripheral.name == nil))
    {
        // 添加外部设备
        NearByModal *modal = [[NearByModal alloc]init];
        NSString *strs=[configEmpty(advertisementData[@"kCBAdvDataManufacturerData"]) description];
        NSMutableString *macAddress=[[NSMutableString alloc] init];
        
        if (strs.length>6)
        {
            [macAddress appendString:[strs substringWithRange:NSMakeRange(5, strs.length-6)]];
        }
        
        
        //        NSMutableString *macAddress=[[NSMutableString alloc] initWithString:[strs substringWithRange:NSMakeRange(5, strs.length-6)]];
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
        [_m_Tableview.mainPopoverListView reloadData];
        NSLog(@"peripheral--%@ advertisementData--%@    RSSI--%@",peripheral,advertisementData,RSSI);
    }
}

// 连接到外设
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    SB_MBPHUD_HIDE(@"连接成功", 1);
    [[Config Instance] isBlueToothConnect:@"02"];
    NearByModal *modal = self.peripherals[_MacPosition];
    self.textfield.text=modal.macAddress;
    NSString *Str = [NSString stringWithFormat:@"%@",peripheral];
    _discoveredPeripheral=peripheral;
    NSLog(@"----Str=%@",Str);
    [self.m_Tableview dismiss];
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
    SB_MBPHUD_HIDE(@"与外部设备失去连接!", 3);
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
            SB_MBPHUD_HIDE(@"已被绑定", 2);
            [UIView animateWithDuration:1 animations:^{
                [self.m_Tableview dismiss];
            }];
        }
        else if ([resultStr intValue]==0)
        {
            SB_MBPHUD_HIDE(@"连接服务器失败", 3);
            [UIView animateWithDuration:1 animations:^{
                [self.m_Tableview dismiss];
            }];
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
        NSString *result=xml[@"ChangeBResponse"][@"ChangeBResult"][@"text"];
        if ([result intValue]==1)
        {
            SB_MBPHUD_HIDE(@"成功", 1);
            [[Config Instance] isBlueToothConnect:@"0"];
            _helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
            NSMutableArray *arr=[NSMutableArray array];
            [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",[[Config Instance] getPhoneAndPass][@"phone"],self.textfield.text],@"strParm", nil]];
            NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"ChangeB"];
            [_helper asynServiceMethod:@"ChangeB" SoapMessage:soapMsg Tag:300];
        }
        else if ([result intValue]==-1)
        {
            SB_MBPHUD_HIDE(@"蓝牙设备失效", 3);
        }
        else if ([result intValue]==0)
        {
            SB_MBPHUD_HIDE(@"连接服务器失败", 3);
        }
    }
    if (request.tag==300)
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

-(void)finishFailRequest:(NSError*)error
{
    NSLog(@"异步请发生失败:%@\n",[error description]);
    SB_MBPHUD_HIDE(@"请检查网络", 3)
}

- (void)dealloc
{
    CANCEL_REQUEST
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self disConnect];
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

@end
