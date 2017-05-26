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
//@property (nonatomic, strong)JKNSTimerHolder * timerHolder;
@property (nonatomic, weak)JKNSTimerHolder * timerHolder;


@property (nonatomic, assign) NSUInteger repeatCount;

@property (weak, nonatomic) IBOutlet UILabel *msgLabel;

@end

@implementation NSTimerTestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.repeatCount = 19;
    
    /// 初始化定时器
    JKNSTimerHolder * timerHolder = [[JKNSTimerHolder alloc] init];
    
    /// 强/弱引用都有可以
    self.timerHolder = timerHolder;
    
    
    
    /// 1.selector
//    [timerHolder jk_startNSTimerWithTimeInterval:0.5
//                                     repeatCount:self.repeatCount
//                                   actionHandler:self
//                                          action:@selector(jk_sel:)];
    
    /// 2.block
    [timerHolder jk_startBlockTimerWithTimeInterval:1
                                        repeatCount:self.repeatCount
                                      actionHandler:self
                                             handle:^(JKNSTimerHolder * _Nonnull jkTimer, id  _Nonnull tempSelf, NSUInteger currentCount) {
        
        ///  tempSelf == 传入的actionHandler,使用tempSelf不会发生循环引用（Block只会在执行过程强引用参数对象，执行完就会解除强引用）
        [(NSTimerTestVC *)tempSelf jk_sel:jkTimer index:currentCount];
    }];
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
