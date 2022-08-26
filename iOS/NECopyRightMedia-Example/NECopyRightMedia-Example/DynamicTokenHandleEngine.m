//
//  DynamicTokenHandleEngine.m
//  NECopyRightMedia-Example
//
//  Created by 马雅杰 on 2022/8/26.
//

#import "DynamicTokenHandleEngine.h"
@interface DynamicTokenHandleEngine()
@property(nonatomic, strong) NSPointerArray *observeArray;
//过期定时器
@property(nonatomic, strong) NSTimer *expiredTimer;
//过期时间
@property(nonatomic, assign) uint64_t expiredSeconds;
@end

@implementation DynamicTokenHandleEngine


+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  static DynamicTokenHandleEngine *dynamicTokenHandleEngine = nil;
  dispatch_once(&onceToken, ^{
      dynamicTokenHandleEngine = [[DynamicTokenHandleEngine alloc] init];
      dynamicTokenHandleEngine.observeArray = [NSPointerArray weakObjectsPointerArray];
      dynamicTokenHandleEngine.expiredSeconds = 180;
  });
  return dynamicTokenHandleEngine;
}

- (void)addObserve:(id<DynamicTokenHandleProtocol>)observe {
  bool hasAdded = NO;
  for (id<DynamicTokenHandleProtocol> item in self.observeArray) {
    if (item == observe) {
      hasAdded = YES;
      break;
    }
  }
  if (!hasAdded) {
    [self.observeArray addPointer:(__bridge void *)(observe)];
  }
}

//定时器相关处理

//计算过期时间
- (void)calculateExpiredTime:(long)timeExpired {
  //单位是秒
  //直接释放定时器
  [self releaseExpiredTimer];
  if (timeExpired > 0) {
    if (timeExpired > self.expiredSeconds) {
      //大于用户设定过期提醒时间
      self.expiredTimer = [NSTimer scheduledTimerWithTimeInterval:timeExpired - self.expiredSeconds
                                                           target:self
                                                         selector:@selector(timeEvent)
                                                         userInfo:nil
                                                          repeats:NO];
      [[NSRunLoop currentRunLoop] addTimer:self.expiredTimer forMode:NSRunLoopCommonModes];
      [[NSRunLoop currentRunLoop] run];
    } else {
      //直接提示
      //设置属性即将过期
      [self timeEvent];
    }
  } else {
    //未设定过期时间，直接释放
    [self timeEvent];
  }
}
- (void)releaseExpiredTimer {
  if (self.expiredTimer) {
    [self.expiredTimer invalidate];
    self.expiredTimer = nil;
  }
}
- (void)timeEvent {
    for (id<DynamicTokenHandleProtocol> obj in self.observeArray) {
      if (obj && [obj conformsToProtocol:@protocol(DynamicTokenHandleProtocol)] &&
          [obj respondsToSelector:@selector(onDynamicTokenWillExpired)]) {
          [obj onDynamicTokenWillExpired];
      }
    }
}
@end
