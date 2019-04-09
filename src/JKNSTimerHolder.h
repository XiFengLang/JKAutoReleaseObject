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


/**
 实现NSTimer和self的解耦，内部自动管理对象的释放，并已支持泛型
 */
@interface JKNSTimerHolder <__covariant ObjectType>: NSObject


/**
 回调Block，使用block里面的参数，能避免循环引用的问题

 @param jkTimer 定时器持有者JKNSTimerHolder
 @param timerHandler 外部的事件处理者，支持泛型
 @param currentCount 当前的次数
 */
typedef void(^JKNSTimerBlack)(JKNSTimerHolder * __nonnull jkTimer, ObjectType __nonnull timerHandler, NSUInteger currentCount);


    

@property (nonatomic, strong, readonly) NSTimer * __nonnull timer;
    

/** 挂起，暂停定时器，此处不会释放定时器，JKNSTimerHolder仍被NSTimer强引用
*/
@property (nonatomic, assign) BOOL suspended;




/**
 开始定时器，repeatCount = 0时不重复，repeatCount = 总数 -1，调用cancelNSTimer取消
 
 @param seconds 间隔
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param handler 回调响应者
 @param action 回调SEL
 */
- (void)jk_startNSTimerWithTimeInterval:(NSTimeInterval)seconds
                            repeatCount:(NSUInteger)repeatCount
                          actionHandler:(ObjectType __nonnull)handler
                                 action:(SEL __nonnull)action JKNSDeprecated("jk_startWithTimeInterval:repeatCount:timerHandler:callback");

/**
 开始定时器，需传值回调方法selector，repeatCount = 0时不重复，repeatCount = 总数 -1，调用cancelNSTimer取消
 
 @param seconds 间隔
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param timerHandler 回调响应者
 @param selector 回调SEL
 */
- (void)jk_startWithTimeInterval:(NSTimeInterval)seconds
                     repeatCount:(NSUInteger)repeatCount
                    timerHandler:(ObjectType __nonnull)timerHandler
                        selector:(SEL __nonnull)selector;
    
    

/**
 开始定时器，采用Block回调,repeatCount = 0时不重复，repeatCount = 总数 -1，调用cancelNSTimer取消
 
 @param seconds 间隔
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param handler 回调响应者
 @param handle 回调Block
 */
- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)seconds
                               repeatCount:(NSUInteger)repeatCount
                             actionHandler:(ObjectType __nonnull)handler
                                    handle:(JKNSTimerBlack __nonnull)handle JKNSDeprecated("jk_startWithTimeInterval:repeatCount:timerHandler:block:");

/**
 开始定时器，采用【Block】回调,repeatCount = 0时不重复，repeatCount = 总数 -1，调用cancelNSTimer取消
 
 @param seconds 间隔
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param timerHandler 回调响应者
 @param block 回调Block
 */
- (void)jk_startWithTimeInterval:(NSTimeInterval)seconds
                     repeatCount:(NSUInteger)repeatCount
                    timerHandler:(ObjectType __nonnull)timerHandler
                           block:(JKNSTimerBlack __nonnull)block;
    

/**
 关闭定时器，内部会释放定时器，JKNSTimerHolder不被NSTimer强引用
 */
- (void)jk_cancelNSTimer;

@end
NS_ASSUME_NONNULL_END
