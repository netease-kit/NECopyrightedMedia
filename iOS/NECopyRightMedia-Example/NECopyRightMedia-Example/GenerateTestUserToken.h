//
//  GenerateTestUserToken.h
//  NECopyRightMedia-Example
//
//  Created by 马雅杰 on 2022/8/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GenerateTestUserToken : NSObject
+ (NSString *)makeDynamicToken:(NSString *)account;

@end

NS_ASSUME_NONNULL_END
