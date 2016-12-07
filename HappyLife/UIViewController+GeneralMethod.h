//
//  UIViewController+ViewControllerGeneralMethod.h
//  Golf
//
//  Created by Blankwonder on 6/4/13.
//  Copyright (c) 2013 Suixing Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (GeneralMethod)

- (void)popViewController;
- (void)dismissViewController;

- (void)setBackBarButton;
- (void)setDismissBarButton;
- (void)setDoneBarButtonWithSelector:(SEL)selector andTitle:(NSString *)title;
- (void)setRefreshBarButtonWithSelector:(SEL)selector andTitle:(NSString *)title;

@end
