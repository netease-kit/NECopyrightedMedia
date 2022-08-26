//
//  GenerateTestUserToken.m
//  NECopyRightMedia-Example
//
//  Created by 马雅杰 on 2022/8/26.
//

#import "GenerateTestUserToken.h"
#import "NECopyrightedExampleMacro.h"
#import<CommonCrypto/CommonDigest.h>

@implementation GenerateTestUserToken

+ (NSString *)makeDynamicToken:(NSString *)account{
    ///获取当前时间戳，单位毫秒
    long curTime = 1661509154011;
//    [self getNowTimeTimestamp];
    ///设置过期时间，单位秒，如600
/// #生成signature，将appkey、identification、curTime、ttl、appsecret五个字段拼成一个字符串
    NSLog(@"%@",[NSString stringWithFormat:@"%@_%@_%@_%@_%@",appKay,account,[NSString stringWithFormat:@"%ld",curTime],[NSString stringWithFormat:@"%d",ttl],appSecret]);
    NSString *signature = [NSString stringWithFormat:@"%@%@%@%@%@",appKay,account,[NSString stringWithFormat:@"%ld",curTime],[NSString stringWithFormat:@"%d",ttl],appSecret];
    ///进行sha1加密
    NSString *signatureSha1 = [GenerateTestUserToken sha1:signature];
    NSDictionary *jsonDic = @{@"signature":signatureSha1, @"curTime":@(curTime),@"ttl": @(ttl)};
    NSString *jsonString = [GenerateTestUserToken convertToJsonData:jsonDic];
    ///base64编码
    NSString *base64String = [GenerateTestUserToken base64Encod:jsonString];
    return [base64String stringByReplacingOccurrencesOfString:@"=" withString:@""];
}
+ (long)getNowTimeTimestamp{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss SSS"]; // 设置想要的格式，hh与HH的区别:分别表示12小时制,24小时制
    //设置时区,这一点对时间的处理有时很重要
    NSTimeZone*timeZone=[NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    NSDate *datenow = [NSDate date];
    return [datenow timeIntervalSince1970]*1000;
}


/**
 * sha1加密方式
 */
+ (NSString *)sha1:(NSString *)input
{
    //const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    //NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
     NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i=0; i<CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

/**
 * 转换为Base64编码
 */

+ (NSString *)base64Encod:(NSString *)string;
{
NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
return [data base64EncodedStringWithOptions:0];
}

/**
 * 字典转json
 */
+ (NSString *)convertToJsonData:(NSDictionary *)dict{
    NSError*error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString*jsonString;
    if(!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
//    NSRange range = {0,jsonString.length};
    //去掉字符串中的空格
//    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;

}
@end
