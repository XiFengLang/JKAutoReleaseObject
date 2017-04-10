//
//  JKGCDTimerHolder.m
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 17/1/10.
//  Copyright © 2017年 溪枫狼. All rights reserved.
//

#import "JKGCDTimerHolder.h"
#import <objc/runtime.h>

@interface JKGCDTimerHolder ()

@property (nonatomic, strong) __block dispatch_source_t gcdTimer;
@property (nonatomic, assign) SEL callBackAction;
@property (nonatomic, weak)   id actionHandler;


/**
 callBackAction 方法中的参数个数（实际的自定义参数个数 = self.numberOfArguments - 2）
 */
@property (nonatomic, assign) unsigned int numberOfArguments;
@end


@implementation JKGCDTimerHolder
static const char * kJKGCDTimerQueueKey = "kJKGCDTimerHolderKey";

- (void)jk_startGCDTimerWithTimeInterval:(NSTimeInterval)seconds
                             repeatCount:(NSUInteger)repeatCount
                           actionHandler:(id _Nonnull)handler
                                  action:(SEL _Nonnull)action {
    
    [self jk_cancelGCDTimer];
    
    /// 先校验action
    Method callBackMethod = class_getInstanceMethod([handler class], action);
    if (callBackMethod == NULL) {
        NSLog(@"JKGCDTimerHolder Error:  %@ 未实现",NSStringFromSelector(action));
        return;
    } else if ([handler respondsToSelector:action] == NO) {
        NSLog(@"JKGCDTimerHolder Error:  [%@ 不能响应 %@]",[handler class],NSStringFromSelector(action));
        return;
    }
    /// 方法的参数个数（实际的自定义参数个数 = self.numberOfArguments - 2）
    self.numberOfArguments = method_getNumberOfArguments(callBackMethod);
    
    self.actionHandler = handler;
    self.callBackAction = action;
    
    __block NSUInteger currentRepeatCount = 0;
    
    
    /// GCD定时器代码
    dispatch_queue_t serialQueue = dispatch_queue_create(kJKGCDTimerQueueKey, DISPATCH_QUEUE_SERIAL);
    self.gcdTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, serialQueue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(seconds * NSEC_PER_SEC);
    dispatch_source_set_timer(self.gcdTimer, start, interval, 0);
    
    
    dispatch_source_set_event_handler(self.gcdTimer, ^{
        currentRepeatCount += 1;
        
        /// 实际最多只支持一个自定义参数（self.numberOfArguments - 2）
        if (self.numberOfArguments > 3) {
            NSLog(@"JKGCDTimerHolder Crash Error: 不支持多参数回调方法，最多支持一个自定义参数(NSTimer *类型), [%@ %@]",[self.actionHandler class],NSStringFromSelector(self.callBackAction));
        }
        
        /// 使用IMP调用方法
        if ([self.actionHandler respondsToSelector:self.callBackAction]) {
            typedef void (* MessageForwardFunc)(id, SEL, id);
            IMP impPointer = [self.actionHandler methodForSelector:self.callBackAction];
            MessageForwardFunc func = (MessageForwardFunc)impPointer;
            dispatch_async(dispatch_get_main_queue(), ^{
                func(self.actionHandler, self.callBackAction, self);
                
                /// PS:写重复代码是为了防止在子线程提前调用jk_cancelGCDTimer
                if (currentRepeatCount > repeatCount) {
                    [self jk_cancelGCDTimer];
                }
            });
        } else {
            /// 比如：外部响应者已释放
            [self jk_cancelGCDTimer];
            
            if (currentRepeatCount > repeatCount) {
                [self jk_cancelGCDTimer];
            }
        }
    });
    
    /// 开始
    dispatch_resume(self.gcdTimer);
}


- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)seconds
                               repeatCount:(NSUInteger)repeatCount
                             actionHandler:(id)handler
                                    handle:(JKGCDTimerHandle _Nonnull)handle {
    [self jk_cancelGCDTimer];
    
    
    self.actionHandler = handler;
    __block NSUInteger currentRepeatCount = 0;
    
    
    /// GCD定时器代码
    dispatch_queue_t serialQueue = dispatch_queue_create(kJKGCDTimerQueueKey, DISPATCH_QUEUE_SERIAL);
    self.gcdTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, serialQueue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1* NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(seconds * NSEC_PER_SEC);
    dispatch_source_set_timer(self.gcdTimer, start, interval, 0);
    
    
    dispatch_source_set_event_handler(self.gcdTimer, ^{
        currentRepeatCount += 1;
        
        /// Block回调
        if (nil != self.actionHandler) {
            if (handle) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handle(self,self.actionHandler,currentRepeatCount);
                    
                    /// 次数已够，结束定时器，【写重复代码是为了防止在子线程提前调用jk_cancelGCDTimer】
                    if (currentRepeatCount > repeatCount) {
                        [self jk_cancelGCDTimer];
                    }
                });
            }
        } else {
            /// 比如：外部响应者已释放
            [self jk_cancelGCDTimer];
            
            /// 次数已够，结束定时器
            if (currentRepeatCount > repeatCount) {
                [self jk_cancelGCDTimer];
            }
        }
    });
    
    /// 开始
    dispatch_resume(self.gcdTimer);
    
}



- (void)jk_cancelGCDTimer {
    if (self.gcdTimer) {
        dispatch_cancel(self.gcdTimer);
        _gcdTimer = nil;
        _callBackAction = NULL;
        _actionHandler = nil;
        _numberOfArguments = 0;
    }
}


- (void)dealloc {
    [self jk_cancelGCDTimer];
    
#ifdef DEBUG
    NSLog(@"%@ 已释放",self.class);
#endif
    
}


@end
