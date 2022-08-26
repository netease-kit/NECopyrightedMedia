//
//  DynamicTokenHandleEngine.h
//  NECopyRightMedia-Example
//
//  Created by 马雅杰 on 2022/8/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DynamicTokenHandleProtocol <NSObject>

// Token过期
- (void)onDynamicTokenWillExpired;

@end
@interface DynamicTokenHandleEngine : NSObject

/// 初始化
+ (instancetype)sharedInstance;
/// 添加监听对象
/// @param observe 监听对象
- (void)addObserve:(id<DynamicTokenHandleProtocol>)observe;

- (void)calculateExpiredTime:(long)timeExpired;
@end

NS_ASSUME_NONNULL_END
