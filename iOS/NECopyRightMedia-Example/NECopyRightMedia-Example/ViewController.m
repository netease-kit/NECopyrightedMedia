// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import <NECopyrightedMedia/NECopyrightedMediaPublic.h>
#import "RTCManager.h"

static NSString *RTCAppKey = @"";
static NSString *RTCToken = @"";
static long *RTCUid = @"";
static NSString *copyrightedAppKey = @"";
static NSString *realTimeToken = @"";
static NSString *channelName = @"";
static NSString *account = @"";
static int NEPageSize = 20;

typedef void (^SongListBlock)(NSError *_Nullable error);

@interface ViewController () <NESongPreloadProtocol, NECopyrightedEventHandler, RTCManagerProtocol>
//推荐页码
@property(nonatomic, assign) NSInteger pageNum;
//点歌列表数据
@property(nonatomic, strong) NSMutableArray *pickSongArray;
// songId Label
@property(nonatomic, strong) UILabel *songIdLabel;
// songId 输入框
@property(nonatomic, strong) UITextField *songIdTextField;
// preloadButton
@property(nonatomic, strong) UIButton *preloadButton;
// preloadResultLabel
@property(nonatomic, strong) UILabel *preloadResultLabel;
// preloadResultTextView
@property(nonatomic, strong) UITextView *preloadResultTextView;
// playButton
@property(nonatomic, strong) UIButton *playButton;
// currentSongId
@property(nonatomic, strong) NSString *currentSongId;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  //初始化页面
  [self initView];
  //初始化RTC
  [[RTCManager getInstance] initRTC:RTCAppKey];
  //加入房间
  [[RTCManager getInstance]
      enterRTCRoomWithToken:RTCToken
                channelName:channelName
                      myUid:RTCUid];
  //设置RTC监听
  [[RTCManager getInstance] addRTCManagerObserve:self];

  //初始化版权SDK
  [[NECopyrightedMedia getInstance] initialize:copyrightedAppKey
                                         token:realTimeToken
                                      userUuid:account
                                        extras:nil];
  //清理缓存
  [[NECopyrightedMedia getInstance] clearSongCache];
  self.pageNum = 0;
  //设置版权代理
  [[NECopyrightedMedia getInstance] addPreloadProtocolObserve:self];
  //设置动态Token过期代理
  [[NECopyrightedMedia getInstance] setEventHandler:self];
  [self getKaraokeSongList];
}

- (void)initView {
  self.view.backgroundColor = [UIColor blackColor];
  // songIdLabel
  self.songIdLabel = [[UILabel alloc] init];
  self.songIdLabel.text = @"songId:";
  self.songIdLabel.textColor = [UIColor whiteColor];
  [self.view addSubview:self.songIdLabel];
  [self.songIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.mas_equalTo(self.view).offset(20);
    make.top.mas_equalTo(self.view).offset(50);
  }];
  // songIdTextFiled
  self.songIdTextField = [[UITextField alloc] init];
  NSAttributedString *attrString =
      [[NSAttributedString alloc] initWithString:@"请输入从后台获取的SongId"
                                      attributes:@{
                                        NSForegroundColorAttributeName : [UIColor whiteColor],
                                        NSFontAttributeName : [UIFont systemFontOfSize:14]
                                      }];
  self.songIdTextField.text = @"A92A7942EE8B59EC04DCE1516819CE74";
  self.songIdTextField.attributedPlaceholder = attrString;
  self.songIdTextField.textColor = [UIColor whiteColor];
  self.songIdTextField.borderStyle = UITextBorderStyleRoundedRect;
  [self.view addSubview:self.songIdTextField];
  [self.songIdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.mas_equalTo(self.view).offset(20);
    make.right.mas_equalTo(self.view).offset(-20);
    make.top.mas_equalTo(self.songIdLabel.mas_bottom).offset(8);
    make.height.mas_equalTo(30);
  }];

  self.preloadButton = [[UIButton alloc] init];
  [self.preloadButton setTitle:@"预加载" forState:UIControlStateNormal];
  self.preloadButton.backgroundColor = [UIColor blueColor];
  [self.preloadButton addTarget:self
                         action:@selector(preloadSong)
               forControlEvents:UIControlEventTouchUpInside];
  self.preloadButton.layer.borderWidth = 1.0f;
  self.preloadButton.layer.borderColor = [UIColor whiteColor].CGColor;
  [self.view addSubview:self.preloadButton];
  [self.preloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.mas_equalTo(self.songIdTextField.mas_bottom).offset(8);
    make.centerX.mas_equalTo(self.view);
    make.width.mas_equalTo(@100);
    make.height.mas_equalTo(@30);
  }];
  // preloadResultLabel
  self.preloadResultLabel = [[UILabel alloc] init];
  self.preloadResultLabel.text = @"preloadResult:";
  self.preloadResultLabel.textColor = [UIColor whiteColor];
  [self.view addSubview:self.preloadResultLabel];
  [self.preloadResultLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.view).offset(20);
    make.top.equalTo(self.preloadButton.mas_bottom).offset(8);
  }];

  //    preloadResultTextView
  self.preloadResultTextView = [[UITextView alloc] init];
  self.preloadResultTextView.layer.borderWidth = 1.0f;
  self.preloadResultTextView.layer.borderColor = [UIColor whiteColor].CGColor;
  self.preloadResultTextView.editable = NO;
  self.preloadResultTextView.scrollEnabled = YES;

  [self.view addSubview:self.preloadResultTextView];
  [self.preloadResultTextView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.mas_equalTo(self.view).offset(20);
    make.right.mas_equalTo(self.view).offset(-20);
    make.top.mas_equalTo(self.preloadResultLabel.mas_bottom).offset(8);
    make.height.mas_equalTo(100);
  }];
  //    playButton
  self.playButton = [[UIButton alloc] init];
  [self.playButton setTitle:@"播放" forState:UIControlStateNormal];
  self.playButton.backgroundColor = [UIColor blueColor];
  [self.playButton addTarget:self
                      action:@selector(playSong)
            forControlEvents:UIControlEventTouchUpInside];
  self.playButton.layer.borderWidth = 1.0f;
  self.playButton.layer.borderColor = [UIColor whiteColor].CGColor;
  [self.view addSubview:self.playButton];
  [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.mas_equalTo(self.preloadResultTextView.mas_bottom).offset(8);
    make.centerX.mas_equalTo(self.view);
    make.width.mas_equalTo(@100);
    make.height.mas_equalTo(@30);
  }];
}
//获取歌单数据
- (void)getKaraokeSongList {
  [[NECopyrightedMedia getInstance]
      getSongList:nil
          pageNum:@(self.pageNum)
         pageSize:@(NEPageSize)
         callback:^(NSArray<NECopyrightedSong *> *_Nonnull songList, NSError *_Nonnull error) {
           if (error) {
             NSLog(@"getKaraokeSongListError --- %@", error.description);
           } else {
             NSLog(@"getKaraokeSongListSuccess");
             //            self.pickSongArray = [songList mutableCopy];
           }
         }];
}
- (void)preloadSong {
  self.currentSongId = nil;
  self.preloadResultTextView.text = @"";
  if (self.songIdTextField.text.length > 0) {
    [[NECopyrightedMedia getInstance] preloadSong:self.songIdTextField.text observe:self];
  } else {
    self.preloadResultTextView.text = @"加载失败，请输入服务端获取的SongId";
  }
}

#pragma mark <NESongPreloadProtocol>

- (void)onPreloadStart:(nonnull NSString *)songId {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.preloadResultTextView.text =
        [self.preloadResultTextView.text stringByAppendingFormat:@"开始预加载 - songID:%@", songId];
  });
}
- (void)onPreloadProgress:(NSString *)songId progress:(float)progress {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.preloadResultTextView.text = [self.preloadResultTextView.text
        stringByAppendingFormat:@"预加载进度 - songID:%@,progress:%.2f", songId, progress];
  });
}

- (void)onPreloadComplete:(NSString *)songId error:(NSError *_Nullable)preloadError {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (preloadError) {
      self.preloadResultTextView.text = [self.preloadResultTextView.text
          stringByAppendingFormat:@"预加载失败 - songID:%@ - error:%@", songId,
                                  preloadError.description];
    } else {
      self.currentSongId = songId;
      self.preloadResultTextView.text = [self.preloadResultTextView.text
          stringByAppendingFormat:@"预加载完成 - songID:%@", songId];
    }
    [self.preloadResultTextView
        scrollRangeToVisible:NSMakeRange(self.preloadResultTextView.text.length, 1)];
  });
}

- (void)playSong {
  if (self.currentSongId) {
    NSString *originalPath = [[NECopyrightedMedia getInstance] getSongURI:self.currentSongId
                                                              songResType:TYPE_ORIGIN];
    NSString *accPath = [[NECopyrightedMedia getInstance] getSongURI:self.currentSongId
                                                         songResType:TYPE_ACCOMP];
    [[RTCManager getInstance] playAudioWithAccPath:accPath originalPath:originalPath];
  } else {
    NSLog(@"暂无播放数据");
  }
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
- (void)onTokenExpired {
  // Token过期
  //此处需要申请新的realTimeToken
}

@end
