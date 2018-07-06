//
//  JKNSTimerHolder.h
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 16/11/15.
//  Copyright © 2016年 溪枫狼. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang assume_nonnull begin

@class JKNSTimerHolder;
typedef void(^JKNSTimerHandle)(JKNSTimerHolder * jkTimer, id tempSelf, NSUInteger currentCount);



/**
 实现NSTimer和self的解耦，内部自动管理内存的释放
 */
@interface JKNSTimerHolder : NSObject



/**
 挂起，暂停定时器，此处不会释放定时器，JKNSTimerHolder仍被NSTimer强引用
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
                          actionHandler:(id __nonnull)handler
                                 action:(SEL __nonnull)action;



/**
 开始定时器，采用Block回调,repeatCount = 0时不重复，repeatCount = 总数 -1，调用cancelNSTimer取消
 
 @param seconds 间隔
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param handler 回调响应者
 @param handle 回调Block
 */
- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)seconds
                               repeatCount:(NSUInteger)repeatCount
                             actionHandler:(id __nonnull)handler
                                    handle:(JKNSTimerHandle __nonnull)handle;


/**
 关闭定时器，内部会释放定时器，JKNSTimerHolder不被NSTimer强引用
 */
- (void)jk_cancelNSTimer;

@end
#pragma clang assume_nonnull end
