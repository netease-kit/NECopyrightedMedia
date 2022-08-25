// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "RTCManager.h"
#import <NERtcSDK/NERtcEngineBase.h>
#import <NERtcSDK/NERtcSDK.h>

@interface RTCManager () <NERtcEngineDelegateEx, NERtcEngineAudioFrameObserver>
@property(nonatomic, strong) NSMutableArray *observeArray;
@end

@implementation RTCManager

+ (instancetype)getInstance {
  static RTCManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
    instance.observeArray = [NSMutableArray array];
  });
  return instance;
}
- (void)initRTC:(NSString *)appkey {
  NERtcEngine *coreEngine = [NERtcEngine sharedEngine];
  NERtcEngineContext *context = [[NERtcEngineContext alloc] init];
  // 设置通话相关信息的回调
  context.engineDelegate = self;
  [coreEngine setAudioFrameObserver:self];
  //  [coreEngine enableAudioVolumeIndication:YES interval:200 vad:YES];
  // 设置当前应用的appKey
  context.appKey = appkey;
  NERtcLogSetting *logSetting = [[NERtcLogSetting alloc] init];
  logSetting.logLevel = kNERtcLogLevelWarning;
  context.logSetting = logSetting;

  [coreEngine setupEngineWithContext:context];
  [coreEngine enableLocalAudio:YES];
  [coreEngine setAudioProfile:kNERtcAudioProfileHighQualityStereo
                     scenario:kNERtcAudioScenarioMusic];

  NERtcAudioFrameRequestFormat *format = [NERtcAudioFrameRequestFormat new];
  format.channels = 1;
  format.sampleRate = 44100;
  format.mode = kNERtcAudioFrameOpModeReadWrite;
  [coreEngine setPlaybackAudioFrameParameters:format];
  [coreEngine setRecordingAudioFrameParameters:format];
}

- (void)addRTCManagerObserve:(id<RTCManagerProtocol>)obj {
  [self.observeArray addObject:obj];
}
- (void)enterRTCRoomWithToken:(NSString *)token
                  channelName:(NSString *)channelName
                        myUid:(uint64_t)myUid {
  [NERtcEngine.sharedEngine
      joinChannelWithToken:NULL
               channelName:channelName
                     //                                             myUid:random() % 100000
                     myUid:myUid
                completion:^(NSError *_Nullable error, uint64_t channelId, uint64_t elapesd,
                             uint64_t uid) {
                  if (error) {
                    //加入失败

                  } else {
                    //加入成功
                    NSLog(@"uid --- %llu, cid --- %llu", uid, channelId);
                    [[NERtcEngine sharedEngine] setParameters:@{kNERtcKeyAutoSubscribeAudio : @1}];
                  }
                }];
}

- (void)leaveRoom {
  [NERtcEngine.sharedEngine leaveChannel];
}

- (void)onNERtcEngineUserDidJoinWithUserID:(uint64_t)userID userName:(NSString *)userName {
  NSLog(@"user ID --- %llu , userName --- %@", userID, userName);
}

- (void)playAudioWithAccPath:(NSString *)accompanyPath originalPath:(NSString *)originalPath {
  // 调用以下代码会播放并上行伴奏
  NERtcCreateAudioEffectOption *aOption = [[NERtcCreateAudioEffectOption alloc] init];
  aOption.path = accompanyPath;
  aOption.playbackVolume = 50;  //如果当前放纯伴奏音乐，将带原唱的播放音量设成0
  aOption.sendVolume = 50;  //如果当前放纯伴奏音乐，将带原唱的伴奏发送音量设成0
  aOption.sendEnabled = true;
  aOption.loopCount = 1;
  aOption.sendWithAudioType = kNERtcAudioStreamTypeMain;
  int aCode = [[NERtcEngine sharedEngine] playEffectWitdId:0 effectOption:aOption];
  // 调用以下代码会播放并上行原唱
  NERtcCreateAudioEffectOption *oOption = [[NERtcCreateAudioEffectOption alloc] init];
  oOption.path = originalPath;
  oOption.playbackVolume =
      aCode == 0
          ? 0
          : 50;  // 如果伴奏播放失败则播放原唱 ；//如果当前播放纯伴奏音乐，将带原唱的播放音量设置成0
  oOption.sendVolume = aCode == 0 ? 0 : 50;  //如果当前播放纯伴奏，将带原唱的伴奏发送音量设置成0
  oOption.sendEnabled = true;
  aOption.loopCount = 1;
  oOption.sendWithAudioType = kNERtcAudioStreamTypeMain;
  [[NERtcEngine sharedEngine]
      playEffectWitdId:1
          effectOption:aOption];  // optOriginalEffectId 自己定义的原唱effect id
}
- (void)playAudioWithPath:(NSString *)path {
  NERtcCreateAudioMixingOption *audioMixingOption = [[NERtcCreateAudioMixingOption alloc] init];
  audioMixingOption.path = path;
  [[NERtcEngine sharedEngine] startAudioMixingWithOption:audioMixingOption];
}

- (void)stopAudioMixing {
  [[NERtcEngine sharedEngine] stopAudioMixing];
}

- (uint64_t)getAudioMixingCurrentPosition {
  uint64_t currentTime;
  int value = [[NERtcEngine sharedEngine] getAudioMixingCurrentPosition:&currentTime];
  if (value == 0) {
    return currentTime;
  }
  return -1;
}

- (void)onLocalAudioVolumeIndication:(int)volume {
  for (id<RTCManagerProtocol> obj in self.observeArray) {
    if ([obj conformsToProtocol:@protocol(RTCManagerProtocol)] &&
        [obj respondsToSelector:@selector(onRTCManagerProtocolLocalAudioVolumeIndication:)]) {
      [obj onRTCManagerProtocolLocalAudioVolumeIndication:volume];
    }
  }
}

- (void)onAudioMixingTimestampUpdate:(uint64_t)timeStampMS {
  //    NSLog(@"当前播放时间 --- %llu",timeStampMS);
}
- (void)onNERtcEngineAudioFrameDidRecord:(NERtcAudioFrame *)frame {
  //音频裸数据..如果需要传递，需要音频编码

  for (id<RTCManagerProtocol> obj in self.observeArray) {
    if ([obj conformsToProtocol:@protocol(RTCManagerProtocol)] &&
        [obj respondsToSelector:@selector(onRTCEngineAudioFrameDidRecord:)]) {
      [obj onRTCEngineAudioFrameDidRecord:frame];
    }
  }
}

@end
