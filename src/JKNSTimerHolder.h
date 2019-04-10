//
//  JKNSTimerHolder.h
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 16/11/15.
//  Copyright © 2016年 溪枫狼. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

#define JKNSDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)



/** 实现NSTimer和self的解耦，解决2者循环引用的问题，1.0.1已支持泛型
 */
@interface JKNSTimerHolder <__covariant ObjectType>: NSObject


/**
 回调Block，使用block里面的参数，能避免循环引用的问题
 
 @param jkTimer 定时器持有者JKNSTimerHolder
 @param timerHandler 外部的事件处理者，支持泛型
 @param currentCount 当前的次数
 */
typedef void(^JKNSTimerBlack)(JKNSTimerHolder * __nonnull jkTimer, ObjectType __nonnull timerHandler, UInt64 currentCount);



@property (nonatomic, strong, readonly) NSTimer * timer;



/** 外部定时任务处理者，弱引用
 */
@property (nonatomic, weak, readonly) ObjectType timerHandler;


/** 挂起，暂停定时器，此处不会释放定时器，再次回调会是定时周期timeInterval(秒)后
 */
@property (nonatomic, assign) BOOL suspended;



/** 用外部定时任务处理者初始化，一般是self
 */
- (instancetype)initWithTimerHandler:(ObjectType)timerHandler NS_DESIGNATED_INITIALIZER;



/**
 * 开始定时器，需传值回调方法【selector】，repeatCount = 0时不重复，repeatCount = 总数 -1，调用cancelNSTimer取消。
 * 注意第一次回调是在定时周期timeInterval(秒)后
 
 @param timeInterval 周期、间隔(秒)
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param selector 回调SEL
 */
- (void)jk_startWithTimeInterval:(NSTimeInterval)timeInterval
                     repeatCount:(UInt64)repeatCount
                        selector:(SEL __nonnull)selector;


/**
 * 开始定时器，采用【Block】回调,repeatCount = 0时不重复，repeatCount = 总数 -1，调用cancelNSTimer取消。
 * 注意第一次回调是在定时周期timeInterval(秒)后
 
 @param timeInterval 周期、间隔(秒)
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param block 回调Block
 */
- (void)jk_startWithTimeInterval:(NSTimeInterval)timeInterval
                     repeatCount:(UInt64)repeatCount
                           block:(JKNSTimerBlack __nonnull)block;


/**  关闭定时器，内部会释放定时器，JKNSTimerHolder不被NSTimer强引用
 */
- (void)jk_cancelNSTimer;






- (void)jk_startNSTimerWithTimeInterval:(NSTimeInterval)timeInterval
                            repeatCount:(UInt64)repeatCount
                          actionHandler:(ObjectType __nonnull)handler
                                 action:(SEL __nonnull)action JKNSDeprecated("use startWithTimeInterval:repeatCount:timerHandler:callback");

- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)timeInterval
                               repeatCount:(UInt64)repeatCount
                             actionHandler:(ObjectType __nonnull)handler
                                    handle:(JKNSTimerBlack __nonnull)handle JKNSDeprecated("use startWithTimeInterval:repeatCount:timerHandler:block:");

@end
NS_ASSUME_NONNULL_END
