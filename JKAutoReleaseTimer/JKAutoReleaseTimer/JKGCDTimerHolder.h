//
//  JKGCDTimerHolder.h
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 17/1/10.
//  Copyright © 2017年 溪枫狼. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma clang assume_nonnull begin

@class JKGCDTimerHolder;
typedef void(^JKGCDTimerHandle)(JKGCDTimerHolder * gcdTimer, id tempSelf, NSUInteger currentCount);

/**
 实现GCD Timer和self的解耦，内部自动管理内存的释放
 */
@interface JKGCDTimerHolder : NSObject



/**
 开始GCD定时器，定时事件在主线程回调。repeatCount = 0时不重复，调用cancelGCDTimer，即可取消定时。
 
 @param seconds 周期
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param handler 回调响应者
 @param action 回调SEL
 */
- (void)jk_startGCDTimerWithTimeInterval:(NSTimeInterval)seconds
                             repeatCount:(NSUInteger)repeatCount
                           actionHandler:(id __nonnull)handler
                                  action:(SEL __nonnull)action;


/**
 开始GCD定时器，定时事件在主线程通过Block回调。repeatCount = 0时不重复，调用cancelGCDTimer，即可取消定时。
 
 @param seconds 周期
 @param repeatCount 重复次数，repeatCount = 总数 -1
 @param handler 回调响应者
 @param handle 回调SEL
 */
- (void)jk_startBlockTimerWithTimeInterval:(NSTimeInterval)seconds
                               repeatCount:(NSUInteger)repeatCount
                             actionHandler:(id __nonnull)handler
                                    handle:(JKGCDTimerHandle __nonnull)handle;



/**
 取消GCD定时器任务
 */
- (void)jk_cancelGCDTimer;

@end
#pragma clang assume_nonnull end
