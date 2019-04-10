//
//  JKGCDTimerHolder.m
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 17/1/10.
//  Copyright © 2017年 溪枫狼. All rights reserved.
//

#import "JKGCDTimerHolder.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface JKGCDTimerHolder ()

@property (nonatomic, strong) __block dispatch_source_t gcdTimer;
@property (nonatomic, assign) SEL callbackSelector;


/** 重复次数，0即不重复
 */
@property (nonatomic, assign) UInt64 repeatCount;

/** 当前执行callBackAction的次数
 */
@property (nonatomic, assign) __block UInt64 currentRepeatCount;

/** 周期
 */
@property (nonatomic, assign) NSTimeInterval timeInterval;

/** callBackAction 方法中的参数个数（实际的自定义参数个数 = self.numberOfArguments - 2）
 */
@property (nonatomic, assign) unsigned int numberOfArguments;

/** 监听进入前台、后台的通知
 */
@property (nonatomic, assign) BOOL observingAppNotification;

/** 标记进入后台的时间戳
 */
@property (nonatomic, assign) NSTimeInterval markTimeInterval;


@end


@implementation JKGCDTimerHolder
static const char * kJKGCDTimerQueueKey = "JKGCDTimer.serial.queue";

- (instancetype)init {
    id tmp = nil;
    return [self initWithTimerHandler:tmp];
}

- (instancetype)initWithTimerHandler:(id)timerHandler {
    if (self = [super init]) {
        _timerHandler = timerHandler;
    }return self;
}

#pragma mark - selector回调

- (void)jk_startGCDTimerWithTimeInterval:(NSTimeInterval)timeInterval
                             repeatCount:(UInt64)repeatCount
                           actionHandler:(id _Nonnull)handler
                                  action:(SEL _Nonnull)action {
    _timerHandler = handler;
    [self jk_startWithTimeInterval:timeInterval repeatCount:repeatCount selector:action];
}

- (void)jk_startWithTimeInterval:(NSTimeInterval)timeInterval
                     repeatCount:(UInt64)repeatCount
                        selector:(SEL __nonnull)selector {
    NSParameterAssert(self.timerHandler);
    NSParameterAssert(selector);
    
    [self jk_cancelGCDTimer];
    
    /// 先校验action
    Method callBackMethod = class_getInstanceMethod([self.timerHandler class], selector);
    if (callBackMethod == NULL) {
        NSLog(@"JKGCDTimerHolder Error:  %@ 未实现",NSStringFromSelector(selector));
        return;
    } else if ([self.timerHandler respondsToSelector:selector] == NO) {
        NSLog(@"JKGCDTimerHolder Error:  [%@ 不能响应 %@]",[self.timerHandler class],NSStringFromSelector(selector));
        return;
    }
    /// 方法的参数个数（实际的自定义参数个数 = self.numberOfArguments - 2）
    self.numberOfArguments = method_getNumberOfArguments(callBackMethod);
    
    
    _callbackSelector = selector;
    _timeInterval = timeInterval;
    _repeatCount = repeatCount;
    
    
    [self startWithTimeInterval:timeInterval block:^{
        if (self.suspended == false) {
            self.currentRepeatCount += 1;
            
            /// 实际最多只支持一个自定义参数（self.numberOfArguments - 2）
            if (self.numberOfArguments > 3) {
                NSLog(@"JKGCDTimerHolder Crash Error: 不支持多参数回调方法，最多支持一个自定义参数(JKGCDTimerHolder *), [%@ %@]",[self.timerHandler class],NSStringFromSelector(self.callbackSelector));
            }
            
            /// 使用IMP调用方法
            if ([self.timerHandler respondsToSelector:self.callbackSelector]) {
                __weak typeof(self.timerHandler) weakTimerHandler = self.timerHandler;
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakTimerHandler) timerHandler = weakTimerHandler;
                    typedef void (* MessageSendFunc)(id, SEL, id);
                    IMP imp = [timerHandler methodForSelector:self.callbackSelector];
                    MessageSendFunc invoke = (MessageSendFunc)imp;
                    timerHandler && imp ? invoke(timerHandler, self.callbackSelector, self) : NULL;
                    
                    /// PS:写重复代码是为了防止在子线程提前调用jk_cancelGCDTimer
                    if (self.currentRepeatCount > repeatCount) {
                        [self jk_cancelGCDTimer];
                    }
                });
            } else {
                /// 比如：外部响应者已释放
                [self jk_cancelGCDTimer];
                
                if (self.currentRepeatCount > repeatCount) {
                    [self jk_cancelGCDTimer];
                }
            }
        }
    }];
    
    
    [self observingAppNotification];
    
    /// 开始
    dispatch_resume(self.gcdTimer);
}


#pragma mark - block回调

- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)timeInterval
                               repeatCount:(UInt64)repeatCount
                             actionHandler:(id)handler
                                    handle:(JKGCDTimerBlock _Nonnull)handle {
    _timerHandler = handler;
    [self jk_startWithTimeInterval:timeInterval repeatCount:repeatCount block:handle];
}

- (void)jk_startWithTimeInterval:(NSTimeInterval)timeInterval
                     repeatCount:(UInt64)repeatCount
                           block:(JKGCDTimerBlock __nonnull)block {
    NSParameterAssert(self.timerHandler);
    NSParameterAssert(block);
    
    [self jk_cancelGCDTimer];
    
    if (nil == self.timerHandler || nil == block) {
        return;
    }
    
    _timeInterval = timeInterval;
    _repeatCount = repeatCount;
    
    [self startWithTimeInterval:timeInterval block:^{
        if (self.suspended == false) {
            self.currentRepeatCount += 1;
            
            /// Block回调
            if (nil != self.timerHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(self,self.timerHandler,self.currentRepeatCount);
                    
                    /// 次数已够，结束定时器，【写重复代码是为了防止在子线程提前调用jk_cancelGCDTimer】
                    if (self.currentRepeatCount > repeatCount) {
                        [self jk_cancelGCDTimer];
                    }
                });
            } else {
                /// 比如：外部响应者已释放
                [self jk_cancelGCDTimer];
                
                /// 次数已够，结束定时器
                if (self.currentRepeatCount > repeatCount) {
                    [self jk_cancelGCDTimer];
                }
            }
        }
    }];
    
    [self observingAppNotification];
    /// 开始
    dispatch_resume(self.gcdTimer);
}


- (void)startWithTimeInterval:(NSTimeInterval)timeInterval
                        block:(dispatch_block_t _Nullable)block {
    /// GCD定时器
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
    dispatch_queue_t serialQueue = dispatch_queue_create(kJKGCDTimerQueueKey, attr);
    _gcdTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, serialQueue);
    uint64_t interval = (uint64_t)(timeInterval * NSEC_PER_SEC);
    
    dispatch_source_set_timer(self.gcdTimer,  dispatch_walltime(NULL, 0), interval, 0);
    dispatch_source_set_event_handler(self.gcdTimer, block);
}


#pragma mark - 监听APP进入前后台

- (BOOL)observingAppNotification {
    if (!_observingAppNotification) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
        _observingAppNotification = YES;
    }
    return _observingAppNotification;
}


- (void)handleNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:UIApplicationWillResignActiveNotification]) {
        self.markTimeInterval = [NSDate date].timeIntervalSince1970;
    } else {
        NSTimeInterval timeNow = [NSDate date].timeIntervalSince1970;
        NSInteger interval = timeNow - self.markTimeInterval;
        NSInteger number = (NSInteger)llround(self.currentRepeatCount + interval / self.timeInterval);
        
        self.currentRepeatCount = number < self.repeatCount ? number : self.repeatCount;
        self.markTimeInterval = 0;
    }
}


#pragma mark - 废除/结束定时器
- (void)setSuspended:(BOOL)suspended {
    if (!self.gcdTimer) return;
    if (suspended) {
        _suspended = suspended;
        dispatch_suspend(self.gcdTimer);
    } else {
        _suspended = suspended;
        dispatch_resume(self.gcdTimer);
    }
}


- (void)jk_cancelGCDTimer {
    if (self.gcdTimer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        if (self.suspended) {
            /// 不能再暂停的timer 赋值 nil，所以要恢复
            dispatch_source_set_timer(self.gcdTimer,  dispatch_walltime(NULL, 0), 100, 0);
            dispatch_resume(self.gcdTimer);
        }
        dispatch_cancel(self.gcdTimer);
        _gcdTimer = nil;
        
        _suspended = false;
        _callbackSelector = NULL;
        _timerHandler = nil;
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
