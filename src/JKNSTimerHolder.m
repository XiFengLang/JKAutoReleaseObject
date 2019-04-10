//
//  JKNSTimerHolder.m
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 16/11/15.
//  Copyright © 2016年 溪枫狼. All rights reserved.
//

#import "JKNSTimerHolder.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface JKNSTimerHolder ()


/** 重复次数，0即不重复
 */
@property (nonatomic, assign) UInt64 repeatCount;


/** 定时器间隔
 */
@property (nonatomic, assign) NSTimeInterval timeInterval;

/** 当前执行callBackAction的次数
 */
@property (nonatomic, assign) UInt64 currentRepeatCount;


@property (nonatomic, assign) SEL callbackSelector;
@property (nonatomic, copy) JKNSTimerBlack callbackBlock;


/** 回调方法中的参数（实际的自定义参数个数 = self.numberOfArguments - 2）
 */
@property (nonatomic, assign) int numberOfArguments;




/** 监听进入前台、后台的通知
 */
@property (nonatomic, assign) BOOL observingAppNotification;


/** 标记进入后台的时间戳
 */
@property (nonatomic, assign) NSTimeInterval markTimeInterval;



@end

@implementation JKNSTimerHolder

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

- (void)jk_startNSTimerWithTimeInterval:(NSTimeInterval)seconds
                            repeatCount:(UInt64)repeatCount
                          actionHandler:(id _Nonnull)handler
                                 action:(SEL _Nonnull)action {
    _timerHandler = handler;
    [self jk_startWithTimeInterval:seconds repeatCount:repeatCount selector:action];
}


- (void)jk_startWithTimeInterval:(NSTimeInterval)seconds
                     repeatCount:(UInt64)repeatCount
                        selector:(SEL _Nonnull)selector {
    NSParameterAssert(self.timerHandler);
    NSParameterAssert(selector);
    
    [self jk_cancelNSTimer];
    
    /// 先校验selector
    Method callBackMethod = class_getInstanceMethod([self.timerHandler class], selector);
    if (callBackMethod == NULL) {
        NSLog(@"JKNSTimerHolder Error:  %@ 未实现",NSStringFromSelector(selector));
        return;
    } else if ([self.timerHandler respondsToSelector:selector] == false) {
        NSLog(@"JKNSTimerHolder Error:  [%@ 不能响应 %@]",[self.timerHandler class],NSStringFromSelector(selector));
        return;
    }
    
    [self observingAppNotification];
    
    /// 方法的参数个数（实际的自定义参数个数 = self.numberOfArguments - 2）
    self.numberOfArguments = method_getNumberOfArguments(callBackMethod);
    
    _callbackSelector = selector;
    _timeInterval = seconds;
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
        NSLog(@"JKNSTimerHolder Crash Error: 不支持多参数回调方法，最多支持一个自定义参数(JKNSTimerHolder *), [%@ %@]",[self.timerHandler class],NSStringFromSelector(self.callbackSelector));
    }
    
    
    /// 使用IMP调用方法
    if ([self.timerHandler respondsToSelector:self.callbackSelector]) {
        typedef void (* MessageSendFunc)(id, SEL, id);
        IMP imp = [self.timerHandler methodForSelector:self.callbackSelector];
        MessageSendFunc invoke = (MessageSendFunc)imp;
        invoke(self.timerHandler, self.callbackSelector, self);
    } else {
        /// 比如：外部响应者已释放
        [self jk_cancelNSTimer];
    }
}



#pragma mark - Block回调


- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)seconds
                               repeatCount:(UInt64)repeatCount
                             actionHandler:(id _Nonnull)handler
                                    handle:(JKNSTimerBlack _Nonnull)handle {
    _timerHandler = handler;
    [self jk_startWithTimeInterval:seconds repeatCount:repeatCount block:handle];
}

- (void)jk_startWithTimeInterval:(NSTimeInterval)seconds
                     repeatCount:(UInt64)repeatCount
                           block:(JKNSTimerBlack)block {
    NSParameterAssert(self.timerHandler);
    NSParameterAssert(block);
    
    [self jk_cancelNSTimer];
    
    if (nil == self.timerHandler || nil == block) {
        return;
    }
    
    [self observingAppNotification];
    
    _callbackBlock = block;
    _timeInterval = seconds;
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
    if (nil != self.timerHandler) {
        if (nil != self.callbackBlock) {
            self.callbackBlock(self, self.timerHandler, self.currentRepeatCount);
        }
    } else {
        [self jk_cancelNSTimer];
    }
}


#pragma mark - 取消/结束定时器
- (void)setSuspended:(BOOL)suspended {
    _suspended = suspended;
    
    if (!self.timer) return;
    if (suspended) {
        [self.timer setFireDate:[NSDate distantFuture]];
    } else {
        [self.timer setFireDate:[NSDate date]];
    }
}

- (void)jk_cancelNSTimer {
    if (self.timer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [_timer invalidate];
        _timer = nil;
        
        _currentRepeatCount = 0;
        _callbackBlock = nil;
        _callbackSelector = NULL;
        _repeatCount = 0;
    }
}

- (void)dealloc {
    [self jk_cancelNSTimer];
    
#ifdef DEBUG
    NSLog(@"%@ 已释放",self.class);
#endif
}


#pragma mark - 监听APP进入前后台的通知

- (BOOL)observingAppNotification {
    if (!_observingAppNotification) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
        _observingAppNotification = YES;
    }
    return _observingAppNotification;
}


- (void)handleNotification:(NSNotification *)notification {
    if (self.suspended == NO) {
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
}


@end
