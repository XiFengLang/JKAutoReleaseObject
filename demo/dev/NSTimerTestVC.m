//
//  NSTimerTestVC.m
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 17/1/10.
//  Copyright © 2017年 溪枫狼. All rights reserved.
//

#import "NSTimerTestVC.h"
#import "JKNSTimerHolder.h"

@interface NSTimerTestVC ()

@property (nonatomic, strong) JKNSTimerHolder <NSTimerTestVC *>* timerHolder;

@property (nonatomic, assign) NSUInteger repeatCount;

@property (weak, nonatomic) IBOutlet UILabel *msgLabel;

@end

@implementation NSTimerTestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.repeatCount = 19;
    
    
    /// 初始化定时器，支持泛型
    JKNSTimerHolder <NSTimerTestVC *>* timerHolder = [[JKNSTimerHolder alloc] initWithTimerHandler:self];
    
    
    /// 强/弱引用都有可以
    self.timerHolder = timerHolder;
    
    /// 1.selector
//    [self.timerHolder jk_startWithTimeInterval:0.5
//                                   repeatCount:self.repeatCount
//                                      selector:@selector(jk_sel:)];
    
    /// 废弃
    //    [timerHolder jk_startNSTimerWithTimeInterval:0.5
    //                                     repeatCount:self.repeatCount
    //                                   actionHandler:self
    //                                          action:@selector(jk_sel:)];
    
    
    /// 2.block
    [timerHolder jk_startWithTimeInterval:5 repeatCount:self.repeatCount block:^(JKNSTimerHolder * _Nonnull jkTimer, NSTimerTestVC * _Nonnull timerHandler, UInt64 currentCount) {
        //  使用timerHandler不会发生循环引用（Block只会在执行过程强引用参数对象，执行完就会解除强引用）
        [timerHandler jk_sel:jkTimer index:currentCount];
    }];
    
    
    /// 废弃
    //    [timerHolder jk_startBlockTimerWithTimeInterval:1 repeatCount:self.repeatCount actionHandler:self handle:^(JKNSTimerHolder * _Nonnull jkTimer, NSTimerTestVC * _Nonnull tempSelf, NSUInteger currentCount) {
    //
    //        ///  tempSelf == 传入的actionHandler,使用tempSelf不会发生循环引用（Block只会在执行过程强引用参数对象，执行完就会解除强引用）
    //        [self jk_sel:jkTimer index:currentCount];
    //
    //    }];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"暂停/开始" style:(UIBarButtonItemStylePlain) target:self action:@selector(suspend)];
}

- (void)suspend {
    self.timerHolder.suspended = !self.timerHolder.suspended;
}

- (void)jk_sel:(JKNSTimerHolder *)timer {}

- (void)jk_sel:(JKNSTimerHolder *)timer index:(NSInteger)index {
    self.msgLabel.text = [NSString stringWithFormat:@"执行%zd次,将在第%zd次后取消",index, self.repeatCount + 1];
    
    if (index == self.repeatCount + 1) {
        [self.timerHolder jk_cancelNSTimer];
        self.msgLabel.text = [NSString stringWithFormat:@"执行%zd次,已停止定时器",index];
    }
}


- (void)dealloc {
    NSLog(@"%@ 已释放",self.class);
}

@end
