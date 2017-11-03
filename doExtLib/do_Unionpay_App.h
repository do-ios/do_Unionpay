//
//  do_Unionpay_App.h
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "doIAppDelegate.h"

@protocol do_Unionpay_AppDelegate <NSObject>

@optional
-(void)didFinish:(NSURL *)url;
@end

@interface do_Unionpay_App : NSObject<doIAppDelegate>
@property (nonatomic,assign) id<do_Unionpay_AppDelegate>unionpayDelegate;
+(id) Instance;
@end
