// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NERtcSDK/NERtcSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RTCManagerProtocol <NSObject>

- (void)onRTCManagerProtocolLocalAudioVolumeIndication:(int)volume;
- (void)onRTCEngineAudioFrameDidRecord:(NERtcAudioFrame *)frame;

@end
@interface RTCManager : NSObject <RTCManagerProtocol>

+ (instancetype)getInstance;
- (void)initRTC:(NSString *)appkey;
- (void)addRTCManagerObserve:(id<RTCManagerProtocol>)obj;
- (void)enterRTCRoomWithToken:(NSString *)token
                  channelName:(NSString *)channelName
                        myUid:(uint64_t)myUid
                        error:(void(^)(NSError * _Nullable))callback;

//使用mix播放 只能同时播放一个音频
- (void)playAudioWithPath:(NSString *)path;
//使用effect播放，同时播放多个
- (void)playAudioWithAccPath:(NSString *)accompanyPath originalPath:(NSString *)originalPath;
- (void)stopAudioMixing;
- (uint64_t)getAudioMixingCurrentPosition;
@end

NS_ASSUME_NONNULL_END
