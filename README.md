# JKAutoReleaseTimer 自释放定时器（NSTimer + GCD 定时器） #

 * JKNSTimerHolder 基于NSTimer封装的自释放定时器
 * JKGCDTimerHolder 基于dispatch_queue_t封装的自释放定时器


### 先思考一个问题：在一个由导航控制器NaviVC管理的控制器VC中运行一个定时器NSTimer，target为VC(self)，假设重复20次，在第10次的时候退出VC（出栈），怎么在最短的时间内停止定时器并释放VC？ ###


常规的NSTimer用法中, self会被强引用，必须先释放_timer才能释放self，如果_timer没能及时释放，就会出现内存泄露，这个情况在《Effective Objective-C 2.0 编写高质量iOS与OS X代码的52个有效方法》的第52条被提到。而基于GCD的dispatch_source_set_event_handler有类似的缺点,容易强引用外部变量，引起循环引用或者内存泄露。

```Object-C
    _timer = [NSTimer scheduledTimerWithTimeInterval:second
                                              target:self
                                            selector:@selector(handleTimerAction:)
                                            userInfo:nil
                                             repeats:yesOrNo];
                                             
```
![self与timer](https://github.com/XiFengLang/JKAutoReleaseTimer/blob/master/QQ20170408.png)


## JKNSTimerHolder ##

而JKNSTimerHolder则在self和timer之间增加的"桥梁对象"类，将self和timer解耦。timerHolder管理timer，timer强引用timerHolder，两者之间存在引用环。但是timerHolder弱引用self，一旦self被释放就会主动废除定时器已实现自释放。而外部的self同样可以主动控制timerHolder，暂停或者废除定时器，达到释放效果。对于前面提出的问题，在这就能迎刃而解,一旦控制器VC出栈，VC没有被额外的强引用就会释放，timerHolder也会自动废除定时器实现自释放。

![d](https://github.com/XiFengLang/JKAutoReleaseTimer/blob/master/QQ20170407.png)

```Object-C

    JKNSTimerHolder * timerHolder = [[JKNSTimerHolder alloc] init];
    
    /// 强/弱引用都有可以
    self.timerHolder = timerHolder;

	[timerHolder jk_startNSTimerWithTimeInterval:0.5
                                     repeatCount:self.repeatCount
                                   actionHandler:self
                                          action:@selector(jk_sel:)];
	
	/// 暂停
	/// self.timerHolder.suspended = YES;


	/// 废除定时器
	/// [self.timerHolder jk_cancelNSTimer];

```

JKNSTimerHolder同时还支持Block块，写法如下：

```Object-C

 @param seconds 时间间隔
 @param repeatCount 重复次数，repeatCount == 运行总数 -1，达到重复次数后会自动停止定时器
 @param handler 回调响应者 == handle中的tempSelf
 @param handle 回调Block


    [timerHolder jk_startBlockTimerWithTimeInterval:0.5
                                        repeatCount:self.repeatCount
                                      actionHandler:self
                                             handle:^(JKNSTimerHolder * _Nonnull jkTimer, id  _Nonnull tempSelf, NSUInteger currentCount) {
        
        ///  tempSelf == 传入的actionHandler,使用tempSelf不会发生循环引用
        [(NSTimerTestVC *)tempSelf jk_sel:jkTimer];
    }];

```

在这呢需要理解一个知识点，即Block对参数对象的引用，非Block对外部对象的引用。经测试，Block会在执行过程强引用参数对象，执行完就会解除强引用。这个测试过程在文章[Block与Copy](http://www.jianshu.com/p/b554e813fce1)中提到，虽然文章中提到的结论有错误，一位大兄弟在评论中指出了错误所在，但是文章中的测试代码还是很有参考价值的。上面代码中Block有个tempSelf参数，这个参数就是传入的actionHandler：self，在handleBlock中使用tempSelf不会出现循环引用，但如果仍使用self，那就可能出现循环引用，需要对self进行weak strong转换才行。


## JKGCDTimerHolder ##

JKGCDTimerHolder基于GCD的dispatch_source_set_event_handler实现，但是原理、用法都和JKNSTimerHolder一样。

```Object-C

    JKGCDTimerHolder * gcdTimerHolder = [[JKGCDTimerHolder alloc] init];
    
    /// 强/弱引用都有可以
    self.gcdTimerHolder = gcdTimerHolder;
    
    [self.gcdTimerHolder jk_startGCDTimerWithTimeInterval:0.5
                                              repeatCount:self.repeatCount
                                            actionHandler:self
                                                   action:@selector(gcdTimerAction)];



	/// 废除定时器
	/// [self.gcdTimerHolder jk_cancelGCDTimer];
```

**Block写法**

```Object-C
    [timerHolder jk_startBlockTimerWithTimeInterval:0.5
                                        repeatCount:self.repeatCount
                                      actionHandler:self
                                             handle:^(JKNSTimerHolder * _Nonnull jkTimer, id  _Nonnull tempSelf, NSUInteger currentCount) {
        
        ///  tempSelf == 传入的actionHandler,使用tempSelf不会发生循环引用
        [(NSTimerTestVC *)tempSelf jk_sel:jkTimer];
    }];
```



