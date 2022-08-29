// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import <NECopyrightedMedia/NECopyrightedMediaPublic.h>
#import "RTCManager.h"
#import "NECopyrightedExampleMacro.h"
#import "GenerateTestUserToken.h"
#import "DynamicTokenHandleEngine.h"


static int NEPageSize = 20;
typedef void (^SongListBlock)(NSError *_Nullable error);

@interface ViewController () <NESongPreloadProtocol, NECopyrightedEventHandler, RTCManagerProtocol,DynamicTokenHandleProtocol>
/// roomId Label
@property(nonatomic, strong) UILabel *roomIdLabel;
/// roomId输入框
@property(nonatomic, strong) UITextField *roomIdTextField;
/// uid Label
@property(nonatomic, strong) UILabel *uidLabel;
/// uid 输入框
@property(nonatomic, strong) UITextField *uidTextField;
/// account Label
@property(nonatomic, strong) UILabel *accountLabel;
/// account输入框
@property(nonatomic, strong) UITextField *accountTextField;
/// enterRoomButton
@property(nonatomic, strong) UIButton *enterRoomButton;
/// enterRoom Label
@property(nonatomic, strong) UILabel *enterRoomLabel;
/// copyRightButton
@property(nonatomic, strong) UIButton *copyrightedInitButton;
/// copyrightedInitResultLabel
@property(nonatomic, strong) UILabel *copyrightedInitResultLabel;
///推荐页码
@property(nonatomic, assign) NSInteger pageNum;
///点歌列表数据
@property(nonatomic, strong) NSMutableArray *pickSongArray;
/// songId Label
@property(nonatomic, strong) UILabel *songIdLabel;
/// songId 输入框
@property(nonatomic, strong) UITextField *songIdTextField;
/// preloadButton
@property(nonatomic, strong) UIButton *preloadButton;
/// preloadResultLabel
@property(nonatomic, strong) UILabel *preloadResultLabel;
/// preloadResultTextView
@property(nonatomic, strong) UITextView *preloadResultTextView;
/// playButton
@property(nonatomic, strong) UIButton *playButton;
/// currentSongId
@property(nonatomic, strong) NSString *currentSongId;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  //初始化页面
  [self initView];
    [[DynamicTokenHandleEngine sharedInstance] addObserve:self];
  //初始化RTC
  [[RTCManager getInstance] initRTC:appKay];
    
}

- (void)initView {
  self.view.backgroundColor = [UIColor blackColor];
    self.copyrightedInitButton = [[UIButton alloc] init];
    [self.view addSubview:self.copyrightedInitButton];
    
     ///roomIdLabel
    self.roomIdLabel = [[UILabel alloc] init];
    self.roomIdLabel.text = @"roomId:";
    self.roomIdLabel.textColor = [UIColor whiteColor];
    self.songIdLabel.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.roomIdLabel];
    [self.roomIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.mas_equalTo(self.view).offset(20);
      make.top.mas_equalTo(self.view).offset(50);
      make.width.mas_equalTo(60);
    }];
    
    ///roomIdTextField
    self.roomIdTextField = [[UITextField alloc] init];
    NSAttributedString *roomIdAttrString =
        [[NSAttributedString alloc] initWithString:@"请输入房间id"
                                        attributes:@{
                                          NSForegroundColorAttributeName : [UIColor whiteColor],
                                          NSFontAttributeName : [UIFont systemFontOfSize:14]
                                        }];
    self.roomIdTextField.text = @"";
    self.roomIdTextField.attributedPlaceholder = roomIdAttrString;
    self.roomIdTextField.textColor = [UIColor whiteColor];
    self.roomIdTextField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.roomIdTextField];
    [self.roomIdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.mas_equalTo(self.roomIdLabel.mas_right).offset(20);
      make.right.mas_equalTo(self.view).offset(-20);
      make.centerY.mas_equalTo(self.roomIdLabel.mas_centerY);
      make.height.mas_equalTo(30);
    }];
    
    self.uidLabel = [[UILabel alloc] init];
    self.uidLabel.text = @"uid:";
    self.uidLabel.textColor = [UIColor whiteColor];
    self.uidLabel.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.uidLabel];
    [self.uidLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.mas_equalTo(self.view).offset(20);
      make.top.mas_equalTo(self.roomIdLabel.mas_bottom).offset(10);
      make.width.mas_equalTo(60);
    }];
    
    ///uidTextField
    self.uidTextField = [[UITextField alloc] init];
    NSAttributedString *uidAttrString =
        [[NSAttributedString alloc] initWithString:@"请输入uid(数字)"
                                        attributes:@{
                                          NSForegroundColorAttributeName : [UIColor whiteColor],
                                          NSFontAttributeName : [UIFont systemFontOfSize:14]
                                        }];
    self.uidTextField.attributedPlaceholder = uidAttrString;
    self.uidTextField.textColor = [UIColor whiteColor];
    self.uidTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.uidTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:self.uidTextField];
    [self.uidTextField mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.mas_equalTo(self.uidLabel.mas_right).offset(20);
      make.right.mas_equalTo(self.view).offset(-20);
      make.centerY.mas_equalTo(self.uidLabel.mas_centerY);
      make.height.mas_equalTo(30);
    }];
    
///    enterRoomButton
    self.enterRoomButton = [[UIButton alloc] init];
    [self.enterRoomButton setTitle:@"加入房间" forState:UIControlStateNormal];
    self.enterRoomButton.backgroundColor = [UIColor blueColor];
    [self.enterRoomButton addTarget:self
                           action:@selector(enterRoom)
                 forControlEvents:UIControlEventTouchUpInside];
    self.enterRoomButton.layer.borderWidth = 1.0f;
    self.enterRoomButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.view addSubview:self.enterRoomButton];
    [self.enterRoomButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.mas_equalTo(self.uidTextField.mas_bottom).offset(8);
      make.centerX.mas_equalTo(self.view);
      make.width.mas_equalTo(@100);
      make.height.mas_equalTo(@30);
    }];
    ///enterRoomLabel
    self.enterRoomLabel = [[UILabel alloc] init];
    self.enterRoomLabel.text = @"";
    self.enterRoomLabel.textColor = [UIColor blackColor];
    self.enterRoomLabel.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.enterRoomLabel];
    [self.enterRoomLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.mas_equalTo(self.enterRoomButton.mas_right).offset(20);
      make.top.mas_equalTo(self.uidTextField.mas_bottom).offset(10);
//      make.width.mas_equalTo(100);
      make.height.mas_equalTo(30);
    }];
    
    ///accountLabel
    self.accountLabel = [[UILabel alloc] init];
    self.accountLabel.text = @"account:";
    self.accountLabel.textColor = [UIColor whiteColor];
    self.accountLabel.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.accountLabel];
    [self.accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.mas_equalTo(self.view).offset(20);
      make.top.mas_equalTo(self.enterRoomButton.mas_bottom).offset(10);
      make.width.mas_equalTo(70);
    }];
    
    ///uidTextField
    self.accountTextField = [[UITextField alloc] init];
    NSAttributedString *accountAttrString =
        [[NSAttributedString alloc] initWithString:@"请输入account"
                                        attributes:@{
                                          NSForegroundColorAttributeName : [UIColor whiteColor],
                                          NSFontAttributeName : [UIFont systemFontOfSize:14]
                                        }];
    self.accountTextField.attributedPlaceholder = accountAttrString;
    self.accountTextField.textColor = [UIColor whiteColor];
    self.accountTextField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.accountTextField];
    [self.accountTextField mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.mas_equalTo(self.accountLabel.mas_right).offset(10);
      make.right.mas_equalTo(self.view).offset(-20);
      make.centerY.mas_equalTo(self.accountLabel.mas_centerY);
      make.height.mas_equalTo(30);
    }];
    
///    copyrightedInitButton
    
    self.copyrightedInitButton = [[UIButton alloc] init];
    [self.copyrightedInitButton setTitle:@"初始化版权SDK" forState:UIControlStateNormal];
    self.copyrightedInitButton.backgroundColor = [UIColor blueColor];
    [self.copyrightedInitButton addTarget:self
                           action:@selector(copyrightedInit)
                 forControlEvents:UIControlEventTouchUpInside];
    self.copyrightedInitButton.layer.borderWidth = 1.0f;
    self.copyrightedInitButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.view addSubview:self.copyrightedInitButton];
    [self.copyrightedInitButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.top.mas_equalTo(self.accountTextField.mas_bottom).offset(8);
      make.centerX.mas_equalTo(self.view);
      make.width.mas_equalTo(@150);
      make.height.mas_equalTo(@30);
    }];
    
    ///copyrightedInitResultLabel
    self.copyrightedInitResultLabel = [[UILabel alloc] init];
    self.copyrightedInitResultLabel.text = @"";
    self.copyrightedInitResultLabel.textColor = [UIColor blackColor];
    self.copyrightedInitResultLabel.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.copyrightedInitResultLabel];
    [self.copyrightedInitResultLabel mas_makeConstraints:^(MASConstraintMaker *make) {
      make.left.mas_equalTo(self.copyrightedInitButton.mas_right).offset(20);
      make.top.mas_equalTo(self.accountTextField.mas_bottom).offset(10);
//      make.width.mas_equalTo(100);
      make.height.mas_equalTo(30);
    }];
    
  // songIdLabel
  self.songIdLabel = [[UILabel alloc] init];
  self.songIdLabel.text = @"songId:";
  self.songIdLabel.textColor = [UIColor whiteColor];
  self.songIdLabel.backgroundColor = [UIColor blackColor];
  [self.view addSubview:self.songIdLabel];
  [self.songIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.mas_equalTo(self.view).offset(20);
    make.top.mas_equalTo(self.accountLabel.mas_bottom).offset(50);
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
- (void)copyrightedInit{
  ///初始化版权SDK
    self.copyrightedInitResultLabel.text = @"";
    if (self.accountTextField.text.length <= 0) {
        self.copyrightedInitResultLabel.text = @"请输入account";
        return;
    }
    [[NECopyrightedMedia getInstance] initialize:appKay
                                           token:[GenerateTestUserToken makeDynamicToken:self.accountTextField.text]
                                        userUuid:self.accountTextField.text
                                          extras:nil];
    self.copyrightedInitResultLabel.text = @"初始化成功";
    [[DynamicTokenHandleEngine sharedInstance] calculateExpiredTime:ttl];
    //清理缓存
    [[NECopyrightedMedia getInstance] clearSongCache];
    self.pageNum = 0;
    //设置版权代理
    [[NECopyrightedMedia getInstance] addPreloadProtocolObserve:self];
    //设置动态Token过期代理
    [[NECopyrightedMedia getInstance] setEventHandler:self];
    [self getKaraokeSongList];
}
- (void)enterRoom{
    //加入房间
    self.enterRoomLabel.text = @"";
    if (self.roomIdLabel.text.length <= 0) {
        self.enterRoomLabel.text = @"请输入roomid";
        return;
    }
    if (self.uidLabel.text.length <= 0) {
        self.enterRoomLabel.text = @"请输入uid";
        return;
    }
    [[RTCManager getInstance] enterRTCRoomWithToken:NULL channelName:self.roomIdLabel.text myUid:[self.uidLabel.text intValue] error:^(NSError * _Nullable error) {
        if (error) {
            /// 加入失败
            self.enterRoomLabel.text = @"加入失败";
        }else{
            /// 加入成功
            self.enterRoomLabel.text = @"加入成功";
            //设置RTC监听
            [[RTCManager getInstance] addRTCManagerObserve:self];
        }
    }];
    
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

- (void)onDynamicTokenWillExpired{
    //Token即将过期
    NSString *token = [GenerateTestUserToken makeDynamicToken:self.accountTextField.text];
    [[NECopyrightedMedia getInstance] renewToken:token];
    [[DynamicTokenHandleEngine sharedInstance] calculateExpiredTime:ttl];
}

@end
