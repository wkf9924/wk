//
//  GEAlertView.m
//  Grouvent
//
//  Created by Blankwonder on 11/17/12.
//  Copyright (c) 2012 Suixing Tech. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "KDXAlertView.h"
@interface KDXAlertView(){
    NSMutableArray *_buttonTitleArray;
    NSMutableArray *_buttonActionBlockArray;
    
    NSString *_cancelButtonTitle;
    void (^_cancelBlock)();
    
    NSString *_title, *_message;
}
@end

static NSMutableArray *ActiveInstances = nil;

@implementation KDXAlertView

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
        cancelBlock:(void ( ^)())cancelBlock {

    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        ActiveInstances = [NSMutableArray array];
    });

    self = [self init];
    if (self) {
        _buttonTitleArray = [NSMutableArray array];
        _buttonActionBlockArray = [NSMutableArray array];
        _cancelButtonTitle = cancelButtonTitle;
        _cancelBlock = cancelBlock;
        
        _title = title;
        _message = message;
    }
    return self;
}

- (void)addButtonWithTitle:(NSString *)title actionBlock:(void ( ^)())actionBlock {
    NSAssert(title, @"Title cannot be nil.");
    [_buttonTitleArray addObject:title];
    if (actionBlock) {
        [_buttonActionBlockArray addObject:actionBlock];
    } else {
        [_buttonActionBlockArray addObject:[NSNull null]];
    }
}

- (void)show {
    [ActiveInstances addObject:self];
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:_title message:_message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    for (NSString *title in _buttonTitleArray) {
        [av addButtonWithTitle:title];
    }
    if (_cancelButtonTitle) {
        av.cancelButtonIndex = [av addButtonWithTitle:_cancelButtonTitle];
    }
    [av show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        if (_cancelBlock)
            _cancelBlock();
    } else {
        id actionBlock = _buttonActionBlockArray[buttonIndex];
        if (actionBlock && actionBlock != [NSNull null]) {
            void (^block)() = actionBlock;
            block();
        }
    }
    alertView.delegate = nil;
    [ActiveInstances removeObject:self];
}


@end
