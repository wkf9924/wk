//
//  AppDelegate.m
//  HappyLife
//
//  Created by mac on 16/3/17.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "UserDatePicker.h"

@implementation UserDatePicker

static UserDatePicker* g_instance = nil;

@synthesize _delegate;
@synthesize m_Commit;
@synthesize m_Picker;
@synthesize m_Title;
@synthesize m_Src;

@synthesize m_Shadow;

- (void)dealloc
{

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ([super initWithCoder:aDecoder])
    {
        _delegate = nil;
        
        return self;
    }
    
    return nil;
}

- (IBAction)OnCommitDown:(UIButton*)sender
{
    [self hiddeUserDatePicker];
    
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    
    [format setDateFormat:@"yyyy-MM-dd"];
    NSString* date = [format stringFromDate:m_Picker.date];
    [format setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSString* udate = [format stringFromDate:m_Picker.date];
    
    if ([_delegate respondsToSelector:@selector(didUserDatePickerDelegate:Date:uploadDate:)]) [_delegate didUserDatePickerDelegate:self Date:date uploadDate:udate];
    
    _delegate = nil;
    m_Src     = nil;
    m_Title.text = nil;
}

+ (UserDatePicker*)UserDatePicker
{
    if (!g_instance)
    {
        g_instance = [[[NSBundle mainBundle] loadNibNamed:@"UserDatePicker" owner:self options:nil] objectAtIndex:0];
        g_instance.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, g_instance.frame.size.height);
    
        g_instance.m_Commit.layer.cornerRadius = 3;
        g_instance.m_Picker.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
        g_instance.m_Picker.datePickerMode = UIDatePickerModeDate;
        g_instance.m_Shadow = nil;
        
        UIWindow* window = [[[UIApplication sharedApplication] windows] firstObject];
        
        g_instance.m_Shadow = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        g_instance.m_Shadow.backgroundColor = [UIColor blackColor];
        g_instance.m_Shadow.alpha = 0.0;
        [window addSubview:g_instance.m_Shadow];
        
        [window addSubview:g_instance];
    }
    
    return g_instance;
}

+ (void)DestoryUserPicker
{
    g_instance = nil;
}

- (void)setTitle:(NSString*)title Delegate:(id)delegate Src:(id)src
{
    m_Title.text = title;
    _delegate    = delegate;
    m_Src        = src;
    
    [self showUserDatePicker];
}

- (void)showUserDatePicker
{
    [UIView beginAnimations:nil context:nil];
    m_Shadow.alpha = 0.6;
    self.center = CGPointMake(self.center.x, [UIScreen mainScreen].bounds.size.height - self.frame.size.height / 2);
    [UIView commitAnimations];
}

- (void)hiddeUserDatePicker
{
    [UIView beginAnimations:nil context:nil];
    m_Shadow.alpha = 0.0;
    self.center = CGPointMake(self.center.x, [UIScreen mainScreen].bounds.size.height + self.frame.size.height / 2);
    [UIView commitAnimations];
}

@end
