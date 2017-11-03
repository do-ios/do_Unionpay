//
//  do_Unionpay_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Unionpay_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import <UIKit/UIKit.h>
#import "doIPage.h"
#import "UPPaymentControl.h"
#import "do_Unionpay_App.h"

static NSString *urlScheme = @"UnionWakeupID";

@interface do_Unionpay_SM()<do_Unionpay_AppDelegate>

@end
@implementation do_Unionpay_SM
{
    NSString *_orderInfo;
    NSString *_mode;
    NSString *_verifyUrl;
    id<doIScriptEngine> _scritEngine;
    NSString *_callbackName;
}
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
//同步
//异步
- (void)startPay:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    _orderInfo = [doJsonHelper GetOneText:_dictParas :@"orderInfo" :@""];
    _mode = [doJsonHelper GetOneText:_dictParas :@"mode" :@""];
    _verifyUrl = [doJsonHelper GetOneText:_dictParas :@"verifyUrl" :@""];
    
    id<doIPage>pageModel = _scritEngine.CurrentPage;
    UIViewController *currentVC = (UIViewController *)pageModel.PageView;
    
    _callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    //_invokeResult设置返回值
    
    __block NSString *scheme = @"";
    NSArray *schemeArray = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    if (schemeArray.count > 0) {
        for (NSDictionary *dict in schemeArray) {
            NSString *name = [dict objectForKey:@"CFBundleURLName"];
            if (name.length > 0 && [name isEqualToString:urlScheme]) {
                scheme = [((NSArray *)[dict objectForKey:@"CFBundleURLSchemes"]) firstObject];
                break;
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UPPaymentControl defaultControl] startPay:_orderInfo fromScheme:scheme mode:_mode viewController:currentVC];
    });
    do_Unionpay_App *app = [do_Unionpay_App Instance];
    app.unionpayDelegate = self;
    app.OpenURLScheme = scheme;
}
- (void)didFinish:(NSURL *)url
{
    [[UPPaymentControl defaultControl] handlePaymentResult:url completeBlock:^(NSString *code, NSDictionary *data) {
        NSString *resultCode;
        NSString *msg;
        //结果code为成功时，先校验签名，校验成功后做后续处理
        if([code isEqualToString:@"success"]) {
            
            //判断签名数据是否存在
            if(data == nil){
                //如果没有签名数据，建议商户app后台查询交易结果
                resultCode = @"-2";
                msg = @"unknown";
                
                return;
            }
            
            //数据从NSDictionary转换为NSString
            NSData *signData = [NSJSONSerialization dataWithJSONObject:data
                                                               options:0
                                                                 error:nil];
            NSString *sign = [[NSString alloc] initWithData:signData encoding:NSUTF8StringEncoding];
            
            
            
            //验签证书同后台验签证书
            //此处的verify，商户需送去商户后台做验签
            if (_verifyUrl && [_verifyUrl isEqualToString:@""]) {
                resultCode = @"0";
                msg = @"success";
            }
            else
            {
                if([self verify:sign]) {
                    //支付成功且验签成功，展示支付成功提示
                    resultCode = @"0";
                    msg = @"success";
                }
                else {
                    resultCode = @"1";
                    msg = @"fail";
                    //验签失败，交易结果数据被篡改，商户app后台查询交易结果
                }
            }
        }
        else if([code isEqualToString:@"fail"]) {
            //交易失败
            resultCode = @"1";
            msg = @"fail";
        }
        else if([code isEqualToString:@"cancel"]) {
            //交易取消
            resultCode = @"-1";
            msg = @"cancel";
        }
        NSMutableDictionary *node = [NSMutableDictionary dictionary];
        [node setObject:resultCode forKey:@"code"];
        [node setObject:msg forKey:@"msg"];
        doInvokeResult *invokeRes = [[doInvokeResult alloc]init:self.UniqueKey];
        [invokeRes SetResultNode:node];
        
        [_scritEngine Callback:_callbackName :invokeRes];
    }];
}


-(BOOL) verify:(NSString *) resultStr {
    
    //验签证书同后台验签证书
    //此处的verify，商户需送去商户后台做验签
    if (_verifyUrl && [_verifyUrl isEqualToString:@""]) {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:_verifyUrl]];
        request.HTTPMethod = @"POST";
        request.HTTPBody = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
        if (error) {
            NSLog(@"%@",error.description);
            return NO;
        }
        NSDictionary *resuDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            NSLog(@"%@",error.description);
            return NO;
        }
        NSString *resultCode = [resuDict objectForKey:@"code"];
        if ([resultCode isEqualToString:@"0"]) {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    return NO;
}

@end