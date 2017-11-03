//
//  do_Unionpay_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Unionpay_App.h"
#import "UPPaymentControl.h"

static do_Unionpay_App* instance;
@implementation do_Unionpay_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Unionpay_App alloc]init];
    return instance;
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([self.unionpayDelegate respondsToSelector:@selector(didFinish:)]) {
        [self.unionpayDelegate didFinish:url];
    }
    return YES;
}


@end
