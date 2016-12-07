//
//  PurchaseGasController.m
//  HappyLife
//
//  Created by mac on 16/3/24.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "PurchaseGasController.h"
#import "MyTableViewCell.h"
#import "GasQueryController.h"

@interface PurchaseGasController ()
{
    //所有数据的数组
    NSMutableArray*_array;
    
    //是否展开二级菜单,存储五个section是否开启二级菜单的状态
    NSMutableArray *isShowNextArr;
    
    NSMutableArray *headViewArr;
}
@end

@implementation PurchaseGasController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"购气查询";
    [self setBackBarButton];
    [self QueryAllcardNum];
    self.CarNumArr=[NSMutableArray array];
    _array = [NSMutableArray array];
    isShowNextArr=[NSMutableArray arrayWithObjects:@"NO",@"NO",@"NO",@"NO",@"NO", nil];
    headViewArr=[NSMutableArray array];
    for (int i=0; i<5; i++)
    {
        HeaderView *Hview=[[NSBundle mainBundle] loadNibNamed:@"HeaderView" owner:self options:nil][0];
        [headViewArr addObject:Hview];
    }
    [self setTime];
}

-(void)setTime
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *dateComponent = [calendar components:unitFlags fromDate:[NSDate date]];
    
    NSInteger year = [dateComponent year];
    NSInteger month = [dateComponent month];
    NSInteger day = [dateComponent day];
    
    [_startBtn setTitle:[NSString stringWithFormat:@"%zi-%02zi-01",year,month] forState:UIControlStateNormal];
    [_endBtn setTitle:[NSString stringWithFormat:@"%zi-%02zi-%02zi",year,month,day] forState:UIControlStateNormal];
    
}

-(void)QueryAllcardNum
{
    self.helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@",[[Config Instance] getPhoneAndPass][@"phone"],@"普通表"],@"strParm", nil]];
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"QueryKahao"];
    [self.helper asynServiceMethod:@"QueryKahao" SoapMessage:soapMsg Tag:100];
}

-(void)QueryGasRecord:(NSInteger)carNum
{
    NSString *CardName=configEmpty(self.CarNumArr[carNum][@"kahao1"][@"text"]);
    self.helper=[[ServiceHelper alloc] initWithQueueDelegate:self];
    NSMutableArray *arr=[NSMutableArray array];
    [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@$%@$%@",CardName,self.startBtn.titleLabel.text,self.endBtn.titleLabel.text],@"strParm", nil]];
    NSLog(@"---arr=%@",arr);
    NSString *soapMsg=[SoapHelper arrayToDefaultSoapMessage:arr methodName:@"PurchaseQuery"];
    [self.helper asynServiceMethod:@"PurchaseQuery" SoapMessage:soapMsg Tag:carNum];
}

#pragma mark 异步请求结果
-(void)finishSuccessRequest:(NSDictionary*)xml ASIRequest:(ASIHTTPRequest *)request
{
    if (request.tag==100)
    {
        id resultObj=xml[@"QueryKahaoResponse"][@"QueryKahaoResult"][@"UserModel"];
        if ([resultObj isKindOfClass:[NSDictionary class]])
        {
            [self.CarNumArr addObject:resultObj];
        }
        else if ([resultObj isKindOfClass:[NSArray class]])
        {
            [self.CarNumArr addObjectsFromArray:(NSArray *)resultObj];
        }
    }
    else
    {
        id QueryGasResultObj=xml[@"PurchaseQueryResponse"][@"PurchaseQueryResult"][@"UserModel"];
        NSMutableArray *resultArr=[NSMutableArray array];
        if ([QueryGasResultObj isKindOfClass:[NSArray class]])
        {
            [resultArr addObjectsFromArray:(NSArray *)QueryGasResultObj];
            [_array addObject:resultArr];
        }
        else if ([QueryGasResultObj isKindOfClass:[NSDictionary class]])
        {
            [resultArr addObject:QueryGasResultObj];
            [_array addObject:resultArr];
        }
        NSInteger index=request.tag;
        NSLog(@"---index=%zi andSele.CarNumArr.count=%ld",index,self.CarNumArr.count);
        if (index+1<self.CarNumArr.count)
        {
            [self QueryGasRecord:index+1];
        }
        else
        {
            [self.bigTableView reloadData];
            SB_HUD_HIDE;
        }
    }
}

-(void)finishFailRequest:(NSError*)error
{
    NSLog(@"异步请发生失败:%@\n",[error description]);
    SB_MBPHUD_HIDE(@"请检查网络", 3)
}

-(IBAction)StartDate:(UIButton *)sender
{
    [[UserDatePicker UserDatePicker] setTitle:@"起始时间" Delegate:self Src:sender];
}

-(IBAction)EndData:(UIButton *)sender
{
    [[UserDatePicker UserDatePicker] setTitle:@"截至时间" Delegate:self Src:sender];
}

-(IBAction)Query:(id)sender
{
    [_array removeAllObjects];
    //购气查询
    if (self.CarNumArr.count>0)
    {
        SB_MBPHUD_SHOW(@"查询中 ...", self.view, NO);
        [self  QueryGasRecord:0];
    }
}

#pragma mark --UserDatePickerDelegate
-(void)didUserDatePickerDelegate:(UserDatePicker *)picker Date:(NSString *)date uploadDate:(NSString *)udate
{
    if (picker.m_Src==self.startBtn)
    {
        [self.startBtn setTitle:date forState:UIControlStateNormal];
    }
    else
    {
        [self.endBtn setTitle:date forState:UIControlStateNormal];
    }
}

#pragma mark - tableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.CarNumArr.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static  NSString *cellIdentifier = @"MyTableViewCell";
    
    MyTableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        [tableView registerNib:[UINib nibWithNibName:@"MyTableViewCell" bundle:nil] forCellReuseIdentifier:@"MyTableViewCell"];
        cell=[tableView dequeueReusableCellWithIdentifier:@"MyTableViewCell"];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    NSArray *dataArr=_array[indexPath.section];
    NSDictionary *dataDic=dataArr[indexPath.row];
    cell.dateLab.text=[NSString stringWithFormat:@"   日期: %@",configEmpty(dataDic[@"pdate1"][@"text"])];
    cell.gasCountlab.text=[NSString stringWithFormat:@"   气量: %@ 燃气费:%@",configEmpty(dataDic[@"qiliang1"][@"text"]),configEmpty(dataDic[@"ranqifei1"][@"text"])];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *state=[isShowNextArr objectAtIndex:section];
    if ([state isEqualToString:@"NO"])
    {
        return 0;
    }
    else if (_array.count==0||_array.count<=section)
    {
        return 0;
    }
    return  [[_array objectAtIndex:section] count];
}

//设置区头高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return   60;
}

//自定义区头 把区头model 创建的view写这里
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    HeaderView *Hview=headViewArr[section];
    Hview.section=section;
    NSDictionary *dic=self.CarNumArr[section];
    Hview.carNum.text=dic[@"kahao1"][@"text"];
    Hview.NumLab.text=dic[@"name1"][@"text"];
    __weak const HeaderView *views=Hview;
    views.btnSelectblock=^(NSInteger sections)
    {
        NSString *State=isShowNextArr[sections];
        
        if ([State isEqualToString:@"NO"])
        {
            State=@"YES";
            [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                views.leftImg.layer.transform = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
            } completion:NULL];
        }
        else
        {
            State=@"NO";
            [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                views.leftImg.layer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
            } completion:NULL];
        }
        [isShowNextArr replaceObjectAtIndex:sections withObject:State];
        [self.bigTableView reloadData];
    };
    return Hview;
}

- (void)dealloc
{
    CANCEL_REQUEST
}


@end
