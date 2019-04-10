//
//  JKGCDTimerHolder.h
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 17/1/10.
//  Copyright © 2017年 溪枫狼. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
#define JKGCDDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)


/** 实现dispatch_source_set_event_handler和self的解耦，避免循环引用，1.0.1已支持泛型
 */
@interface JKGCDTimerHolder <__covariant ObjectType>: NSObject


/**
 回调Block，使用block里面的参数，能避免循环引用的问题
 
 @param jkTimer 定时器持有者JKNSTimerHolder
 @param timerHandler 外部的事件处理者，支持泛型
 @param currentCount 当前的次数
 */
typedef void(^JKGCDTimerBlock)(JKGCDTimerHolder * jkTimer, ObjectType timerHandler, UInt64 currentCount);



/** 外部定时任务处理者，弱引用
 */
@property (nonatomic, weak, readonly) ObjectType timerHandler;


/** 挂起/暂停定时器，此处不会释放定时器，JKGCDTimerHolder仍被dispatch_source_set_event_handler强引用。
 * 目前暂停dispatch_source_t有一个问题，因为会dispatch_source_t积累暂停期间的block，恢复定时器后的前2次回调时间精度不太准
 */
@property (nonatomic, assign) BOOL suspended;



/** 用外部定时任务处理者初始化，一般是self
 */
- (instancetype)initWithTimerHandler:(ObjectType)timerHandler NS_DESIGNATED_INITIALIZER;



/**
 * 立刻开始GCD定时器，在‘主线程’回调【selector】。repeatCount = 0时不重复，调用cancelGCDTimer，即可取消定时。
 
 @param timeInterval 周期
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param selector 回调SEL
 */
- (void)jk_startWithTimeInterval:(NSTimeInterval)timeInterval
                     repeatCount:(UInt64)repeatCount
                        selector:(SEL __nonnull)selector;




/**
 立刻开始GCD定时器，在‘主线程’回调【Block】。repeatCount = 0时不重复，调用cancelGCDTimer，即可取消定时。
 
 @param timeInterval 周期
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param block 回调Block
 */
- (void)jk_startWithTimeInterval:(NSTimeInterval)timeInterval
                     repeatCount:(UInt64)repeatCount
                           block:(JKGCDTimerBlock __nonnull)block;


/** 取消GCD定时器任务，内部会释放dispatch_source_t
 */
- (void)jk_cancelGCDTimer;






- (void)jk_startGCDTimerWithTimeInterval:(NSTimeInterval)timeInterval
                             repeatCount:(UInt64)repeatCount
                           actionHandler:(id __nonnull)handler
                                  action:(SEL __nonnull)action JKGCDDeprecated("use startWithTimeInterval:repeatCount:timerHandler:callback");

- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)timeInterval
                               repeatCount:(UInt64)repeatCount
                             actionHandler:(id __nonnull)handler
                                    handle:(JKGCDTimerBlock __nonnull)handle JKGCDDeprecated("use startWithTimeInterval:repeatCount:timerHandler:block:");
@end
NS_ASSUME_NONNULL_END
