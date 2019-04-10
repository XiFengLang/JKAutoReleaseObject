//
//  JKViewController.m
//  JKAutoReleaseTimer
//
//  Created by 蒋鹏 on 17/1/10.
//  Copyright © 2017年 溪枫狼. All rights reserved.
//

#import "GCDTimerTestVC.h"
#import "JKGCDTimerHolder.h"

@interface GCDTimerTestVC ()
@property (weak, nonatomic) IBOutlet UILabel *msgLabel;

@property (nonatomic, weak) JKGCDTimerHolder <GCDTimerTestVC *>* gcdTimerHolder;

@property (nonatomic, assign) NSUInteger repeatCount;

@end

@implementation GCDTimerTestVC



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.repeatCount = 20;
}


- (IBAction)startTimerJK:(id)sender {
    [self.gcdTimerHolder jk_cancelGCDTimer];
    
    JKGCDTimerHolder <GCDTimerTestVC *>* gcdTimerHolder = [[JKGCDTimerHolder alloc] initWithTimerHandler:self];
    
    /// 强/弱引用都有可以
    self.gcdTimerHolder = gcdTimerHolder;
    
    /// 1. selector
    //    [self.gcdTimerHolder jk_startWithTimeInterval:0.5
    //                                      repeatCount:self.repeatCount
    //                                         selector:@selector(gcdTimer:)];
    
    /// 废弃
    //    [self.gcdTimerHolder jk_startGCDTimerWithTimeInterval:0.5
    //                                              repeatCount:self.repeatCount
    //                                            actionHandler:self
    //                                                   action:@selector(gcdTimer:)];
    
    /// 2. block
    [gcdTimerHolder jk_startWithTimeInterval:1.5 repeatCount:self.repeatCount block:^(JKGCDTimerHolder * _Nonnull jkTimer, GCDTimerTestVC * _Nonnull timerHandler, UInt64 currentCount) {
        
        //  使用timerHandler不会发生循环引用（Block只会在执行过程强引用参数对象，执行完就会解除强引用）
        [timerHandler gcdTimerAction:currentCount];
    }];
    
    
    /// 废弃
    //    [self.gcdTimerHolder jk_startBlockTimerWithTimeInterval:1.5
    //                                                repeatCount:self.repeatCount
    //                                              actionHandler:self
    //                                                     handle:^(JKGCDTimerHolder * _Nonnull gcdTimer, id  _Nonnull tempSelf, NSUInteger currentCount) {
    //
    //        ///  tempSelf == 传入的actionHandler,使用tempSelf不会发生循环引用（Block只会在执行过程强引用参数对象，执行完就会解除强引用）
    //        [(GCDTimerTestVC *)tempSelf gcdTimerAction:currentCount];
    //    }];
}

- (void)gcdTimer:(JKGCDTimerHolder *)timer { }

- (void)gcdTimerAction:(NSInteger)index {
    self.msgLabel.text = [NSString stringWithFormat:@"执行%zd次,将在第%zd次后取消",index, self.repeatCount + 1];
    
    if (index == self.repeatCount + 1) {
        [self.gcdTimerHolder jk_cancelGCDTimer];
        self.msgLabel.text = [NSString stringWithFormat:@"执行%zd次,已停止定时器",index];
    }
}
- (IBAction)suspenTimer:(id)sender {
    self.gcdTimerHolder.suspended = !self.gcdTimerHolder.suspended;
}


- (IBAction)cancelTimerJK:(id)sender {
    [self.gcdTimerHolder jk_cancelGCDTimer];
}



- (void)dealloc {
    NSLog(@"%@ 已释放",self.class);
}

@end
