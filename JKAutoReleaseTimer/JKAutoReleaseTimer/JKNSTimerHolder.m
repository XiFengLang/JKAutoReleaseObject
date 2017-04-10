//
//  JKNSTimerHolder.m
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 16/11/15.
//  Copyright © 2016年 溪枫狼. All rights reserved.
//

#import "JKNSTimerHolder.h"
#import <objc/runtime.h>

@interface JKNSTimerHolder ()

/**
 定时器对象
 */
@property (nonatomic, nonatomic, strong) NSTimer * timer;

/**
 重复次数，0即不重复
 */
@property (nonatomic, assign) NSUInteger repeatCount;


/**
 当前执行callBackAction的次数
 */
@property (nonatomic, assign) NSUInteger currentRepeatCount;



@property (nonatomic, assign) SEL action;
@property (nonatomic, weak)   id actionHandler;


/**
 callBackAction 方法中的参数（实际的自定义参数个数 = self.numberOfArguments - 2）
 */
@property (nonatomic, assign) unsigned int numberOfArguments;


@property (nonatomic, copy) JKNSTimerHandle handleBlock;

@end

@implementation JKNSTimerHolder
- (void)dealloc {
    [self jk_cancelNSTimer];
#ifdef DEBUG
    NSLog(@"%@ 已释放",self.class);
#endif
}


- (void)jk_cancelNSTimer {
    if (self.timer) {
        [_timer invalidate];
        _timer = nil;
        _currentRepeatCount = 0;
        _handleBlock = nil;
        _action = NULL;
        _repeatCount = 0;
    }
}


- (void)jk_startNSTimerWithTimeInterval:(NSTimeInterval)seconds
                            repeatCount:(NSUInteger)repeatCount
                          actionHandler:(id)handler
                                 action:(SEL _Nonnull)action {
    
    [self jk_cancelNSTimer];
    
    /// 先校验action
    Method callBackMethod = class_getInstanceMethod([handler class], action);
    if (callBackMethod == NULL) {
        NSLog(@"JKNSTimerHolder Error:  %@ 未实现",NSStringFromSelector(action));
        return;
    } else if ([handler respondsToSelector:action] == NO) {
        NSLog(@"JKNSTimerHolder Error:  [%@ 不能响应 %@]",[handler class],NSStringFromSelector(action));
        return;
    }
    
    /// 方法的参数个数（实际的自定义参数个数 = self.numberOfArguments - 2）
    self.numberOfArguments = method_getNumberOfArguments(callBackMethod);
    //    NSLog(@"%s",method_getTypeEncoding(callBackMethod));
    //    NSLog(@"%s",method_copyReturnType(callBackMethod));
    //    unsigned int count = method_getNumberOfArguments(callBackMethod);
    //    NSLog(@"%s",method_copyArgumentType(callBackMethod, count-1));
    
    
    _actionHandler = handler;
    _action = action;
    _repeatCount = repeatCount;
    _timer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                              target:self
                                            selector:@selector(handleTimerAction:)
                                            userInfo:nil
                                             repeats:repeatCount];
}


- (void)handleTimerAction:(NSTimer *)timer {
    if (self.currentRepeatCount > self.repeatCount) {
        [self jk_cancelNSTimer];
    }
    self.currentRepeatCount += 1;
    
    /// 实际最多只支持一个自定义参数（self.numberOfArguments - 2）
    if (self.numberOfArguments > 3) {
        NSLog(@"JKNSTimerHolder Crash Error: 不支持多参数回调方法，最多支持一个自定义参数(NSTimer *类型), [%@ %@]",[self.actionHandler class],NSStringFromSelector(self.action));
    }
    
    
    /// 使用IMP调用方法
    if ([self.actionHandler respondsToSelector:self.action]) {
        typedef void (* MessageForwardFunc)(id, SEL, id);
        IMP impPointer = [self.actionHandler methodForSelector:self.action];
        MessageForwardFunc func = (MessageForwardFunc)impPointer;
        func(self.actionHandler, self.action, timer);
    } else {
        /// 比如：外部响应者已释放
        [self jk_cancelNSTimer];
    }
}



- (void)setSuspended:(BOOL)suspended {
    _suspended = suspended;
    if (suspended) {
        [self.timer setFireDate:[NSDate distantFuture]];
    } else {
        [self.timer setFireDate:[NSDate date]];
    }
}






- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)seconds
                               repeatCount:(NSUInteger)repeatCount
                             actionHandler:(id)handler
                                    handle:(JKNSTimerHandle _Nonnull)handle {
    [self jk_cancelNSTimer];
    
    if (nil == handle || nil == handler) {
        return;
    }
    
    
    
    _handleBlock = handle;
    _actionHandler = handler;
    _repeatCount = repeatCount;
    _timer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                              target:self
                                            selector:@selector(handleBlockTimerAction:)
                                            userInfo:nil
                                             repeats:repeatCount];
}

- (void)handleBlockTimerAction:(NSTimer *)timer {
    if (self.currentRepeatCount > self.repeatCount) {
        [self jk_cancelNSTimer];
    }
    self.currentRepeatCount += 1;
    
    /// 校验外部响应者是否已释放
    if (nil != self.actionHandler) {
        if (nil != self.handleBlock) {
            self.handleBlock(self, self.actionHandler, self.currentRepeatCount);
        }
    } else {
        [self jk_cancelNSTimer];
    }
}



@end
