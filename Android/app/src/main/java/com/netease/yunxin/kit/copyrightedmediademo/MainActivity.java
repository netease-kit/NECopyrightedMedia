// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.kit.copyrightedmediademo;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.RadioGroup;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import com.netease.lava.nertc.sdk.NERtc;
import com.netease.lava.nertc.sdk.NERtcCallback;
import com.netease.lava.nertc.sdk.NERtcConstants;
import com.netease.lava.nertc.sdk.NERtcEx;
import com.netease.lava.nertc.sdk.NERtcParameters;
import com.netease.lava.nertc.sdk.audio.NERtcAudioStreamType;
import com.netease.lava.nertc.sdk.audio.NERtcCreateAudioEffectOption;
import com.netease.yunxin.kit.copyrightedmedia.api.NECopyrightedMedia;
import com.netease.yunxin.kit.copyrightedmedia.api.NEErrorCode;
import com.netease.yunxin.kit.copyrightedmedia.api.NESongPreloadCallback;
import com.netease.yunxin.kit.copyrightedmedia.api.SongResType;
import com.netease.yunxin.kit.copyrightedmedia.api.model.NECopyrightedMediaChannel;
import com.netease.yunxin.kit.copyrightedmedia.api.model.NECopyrightedSong;
import com.netease.yunxin.kit.copyrightedmedia.impl.NECopyrightedEventHandler;
import com.netease.yunxin.kit.copyrightedmediademo.debug.GenerateTestUserToken;
import java.util.HashMap;
import java.util.List;
import java.util.Random;
import kotlin.Unit;

public class MainActivity extends AppCompatActivity
    implements NERtcCallback, NECopyrightedEventHandler {
  private static final String LOG_TAG = "SampleCode";

  private static final int REQUEST_CODE_PERMISSION = 10000;

  private Context context;

  private static final long AHEAD_TIME_REFRESH_TOKEN = 180L;

  private static final int REFRESH_TOKEN_TASK_ID = 430;

  private static final int TOKEN_WILL_EXPIRED_TASK_ID = 431;

  private Integer songChannel = null;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    context = this;
    setContentView(R.layout.activity_main);
    requestPermissionsIfNeeded();
    initViews();
    setupNERtc();
    NECopyrightedMedia.getInstance().setEventHandler(this);
    TimerTaskUtil.init();
  }

  private void requestPermissionsIfNeeded() {
    final List<String> missedPermissions = NERtc.checkPermission(this);
    if (missedPermissions.size() > 0) {
      ActivityCompat.requestPermissions(
          this, missedPermissions.toArray(new String[0]), REQUEST_CODE_PERMISSION);
    }
  }

  private void initViews() {
    final EditText editTextUserId = findViewById(R.id.et_user_id);
    editTextUserId.setText(generateRandomUserID());
    final EditText editTextRoomId = findViewById(R.id.et_room_id);
    findViewById(R.id.btn_join)
        .setOnClickListener(
            v -> {
              String userIdText =
                  editTextUserId.getText() != null ? editTextUserId.getText().toString() : "";
              if (TextUtils.isEmpty(userIdText)) {
                Toast.makeText(this, R.string.please_input_user_id, Toast.LENGTH_SHORT).show();
                return;
              }
              String roomId =
                  editTextRoomId.getText() != null ? editTextRoomId.getText().toString() : "";
              if (TextUtils.isEmpty(roomId)) {
                Toast.makeText(this, R.string.please_input_room_id, Toast.LENGTH_SHORT).show();
                return;
              }
              long userId;
              try {
                userId = Long.parseLong(userIdText);
              } catch (NumberFormatException e) {
                Toast.makeText(this, R.string.invalid_user_id, Toast.LENGTH_SHORT).show();
                return;
              }

              joinRtcChannel(roomId, userId);
              hideSoftKeyboard();
            });
    findViewById(R.id.btn_init_sdk)
        .setOnClickListener(
            v -> {
              initCopyrightedMediaSDK();
            });
    findViewById(R.id.btn_start_play)
        .setOnClickListener(
            v -> {
              String songId = ((EditText) findViewById(R.id.et_song_id)).getText().toString();
              downloadSong(songId, songChannel);
            });
    RadioGroup songChannelGroup = findViewById(R.id.rg_song_channel);
    songChannelGroup.setOnCheckedChangeListener(
        (group, checkedId) -> {
          if (checkedId == R.id.channel_cloud_music) {
            songChannel = NECopyrightedMediaChannel.CLOUD_MUSIC;
          } else if (checkedId == R.id.channel_migu) {
            songChannel = NECopyrightedMediaChannel.MI_GU;
          } else {
            songChannel = null;
          }
        });
  }

  // ???????????????SDK
  private void initCopyrightedMediaSDK() {
    String account = ((EditText) findViewById(R.id.et_music_user)).getText().toString();
    String token = getToken(account);
    HashMap<String, Object> extras = new HashMap<>();
    // ??????token
    getSongDynamicToken(
        new NECopyrightedMedia.Callback<NEKaraokeDynamicToken>() {
          @Override
          public void success(@Nullable NEKaraokeDynamicToken neKaraokeDynamicToken) {
            // ?????????sdk
            NECopyrightedMedia.getInstance()
                .initialize(
                    MainActivity.this,
                    AppConfig.getAppKey(),
                    token,
                    account,
                    extras,
                    new NECopyrightedMedia.Callback<Unit>() {
                      @Override
                      public void success(@Nullable Unit info) {
                        Toast.makeText(
                                MainActivity.this,
                                "init CopyrightedMedia success",
                                Toast.LENGTH_LONG)
                            .show();
                      }

                      @Override
                      public void error(int code, @Nullable String msg) {
                        Toast.makeText(
                                MainActivity.this, "init CopyrightedMedia fail", Toast.LENGTH_LONG)
                            .show();
                      }
                    });
          }

          @Override
          public void error(int i, @Nullable String s) {}
        });
  }

  public String getToken(String account) {
    return GenerateTestUserToken.genTestUserToken(account);
  }

  private void downloadSong(String songId, Integer channel) {
    NECopyrightedMedia copyrightedMedia = NECopyrightedMedia.getInstance();
    if (!TextUtils.isEmpty(songId)) {
      preloadSong(copyrightedMedia, songId, channel);
    } else {
      //  ????????????songId????????????????????????
      Toast.makeText(MainActivity.this, "get song list", Toast.LENGTH_LONG).show();
      copyrightedMedia.getSongList(
          null,
          channel,
          0,
          20,
          new NECopyrightedMedia.Callback<List<NECopyrightedSong>>() {
            @Override
            public void error(int code, @Nullable String msg) {
              Log.e(LOG_TAG, "getSongList fail:" + msg);
            }

            @Override
            public void success(@Nullable List<NECopyrightedSong> info) {
              Log.i(LOG_TAG, "getSongList success:" + info);
              if (info != null && info.size() > 0) {
                preloadSong(
                    copyrightedMedia,
                    info.get(0).getSongId(),
                    info.get(0).getChannel()); // play first songId
              }
            }
          });
    }
  }

  private void preloadSong(NECopyrightedMedia copyrightedMedia, String songId, Integer channel) {
    Toast.makeText(
            MainActivity.this,
            "start download song:" + songId + " channel:" + channel,
            Toast.LENGTH_LONG)
        .show();
    copyrightedMedia.preloadSong(
        songId,
        channel,
        new NESongPreloadCallback() {
          @Override
          public void onPreloadStart(String songId, int channel) {
            Toast.makeText(
                    context, context.getString(R.string.start_load, songId), Toast.LENGTH_SHORT)
                .show();
          }

          @Override
          public void onPreloadProgress(String songId, int channel, float progress) {}

          @Override
          public void onPreloadComplete(String songId, int channel, int errorCode, String msg) {
            if (errorCode == NEErrorCode.OK) {
              Toast.makeText(
                      context,
                      context.getString(R.string.song_load_success, songId),
                      Toast.LENGTH_SHORT)
                  .show();
              String originPath =
                  copyrightedMedia.getSongURI(songId, channel, SongResType.TYPE_ORIGIN);
              String accompanyPath =
                  copyrightedMedia.getSongURI(songId, channel, SongResType.TYPE_ACCOMP);
              useNERtc(originPath, accompanyPath, 0);
            } else {
              Toast.makeText(
                      context,
                      context.getString(R.string.song_load_failed, errorCode, msg),
                      Toast.LENGTH_SHORT)
                  .show();
            }
          }
        });
  }

  /** ?????????NERtc */
  private void setupNERtc() {
    NERtcParameters parameters = new NERtcParameters();
    NERtcEx.getInstance().setParameters(parameters);
    try {
      NERtcEx.getInstance().init(getApplicationContext(), AppConfig.getAppKey(), this, null);
      NERtcEx.getInstance().enableLocalAudio(true);
      NERtcEx.getInstance().setClientRole(NERtcConstants.UserRole.CLIENT_ROLE_BROADCASTER);
    } catch (Exception e) {
      Toast.makeText(this, "nertc init failed", Toast.LENGTH_LONG).show();
      finish();
    }
  }

  /** ?????? ??????NERtc ????????????????????? */
  private void useNERtc(String originPath, String accompanyPath, long startTimeStamp) {
    NERtcEx rtcController = NERtcEx.getInstance();
    long PROGRESS_INTERVAL = 100L; // ??????????????????
    int sendVolume = 50; // ???????????????????????????
    int playbackVolume = 50; // ?????????????????????????????????
    // ?????????????????? songId ????????????????????????????????????????????????????????????????????????????????????
    //      ????????? effectOriginId ??? effectAccompanyId ??? int ????????????????????????????????????
    //      ?????? nertc ??? BGM ?????????????????????????????????????????????????????????????????? id ????????????
    int effectOriginId = 1000; // ???????????? id
    int effectAccompanyId = 1001; // ???????????? id

    rtcController.setAudioProfile(
        NERtcConstants.AudioProfile.HIGH_QUALITY_STEREO, NERtcConstants.AudioScenario.MUSIC);

    //?????????????????????????????????????????????
    rtcController.setEffectPlaybackVolume(effectAccompanyId, 100);
    rtcController.setEffectSendVolume(effectAccompanyId, sendVolume);

    //?????????????????????????????????????????????

    rtcController.setEffectPlaybackVolume(effectOriginId, 0);
    rtcController.setEffectSendVolume(effectOriginId, 0);

    // ????????????
    NERtcCreateAudioEffectOption accompanyOption = new NERtcCreateAudioEffectOption();
    accompanyOption.path = accompanyPath;
    accompanyOption.loopCount = 1;
    accompanyOption.sendEnabled = true;
    accompanyOption.sendVolume = sendVolume;
    accompanyOption.playbackEnabled = true;
    accompanyOption.playbackVolume = playbackVolume;
    accompanyOption.startTimestamp = startTimeStamp;
    accompanyOption.progressInterval = PROGRESS_INTERVAL;
    accompanyOption.sendWithAudioType = NERtcAudioStreamType.kNERtcAudioStreamTypeMain;
    rtcController.playEffect(effectAccompanyId, accompanyOption);

    // ????????????
    NERtcCreateAudioEffectOption originOption = new NERtcCreateAudioEffectOption();
    originOption.path = originPath;
    originOption.loopCount = 1;
    originOption.sendEnabled = true;
    originOption.sendVolume = 0;
    originOption.playbackEnabled = true;
    originOption.playbackVolume = 0;
    originOption.startTimestamp = startTimeStamp;
    originOption.progressInterval = PROGRESS_INTERVAL;
    originOption.sendWithAudioType = NERtcAudioStreamType.kNERtcAudioStreamTypeMain;
    rtcController.playEffect(effectOriginId, originOption);
  }

  private void joinRtcChannel(String roomId, long userId) {
    NERtcEx.getInstance().joinChannel("", roomId, userId);
  }

  private void hideSoftKeyboard() {
    if (getCurrentFocus() == null) return;
    InputMethodManager imm = (InputMethodManager) getSystemService(Activity.INPUT_METHOD_SERVICE);
    if (imm == null) return;
    imm.hideSoftInputFromWindow(getCurrentFocus().getWindowToken(), 0);
  }

  private String generateRandomUserID() {
    return String.valueOf(new Random().nextInt(100000));
  }

  @SuppressLint("UsingALog")
  @Override
  public void onJoinChannel(int code, long chenelId, long elapsed, long uid) {
    Log.i(LOG_TAG, "onJoinChannel:" + code);
    Toast.makeText(this, "onJoinChannel:" + code + " " + uid, Toast.LENGTH_SHORT).show();
  }

  @Override
  public void onLeaveChannel(int i) {
    NERtc.getInstance().release();
  }

  @Override
  public void onUserJoined(long uid) {}

  @Override
  public void onUserLeave(long l, int i) {}

  @Override
  public void onUserAudioStart(long l) {}

  @Override
  public void onUserAudioStop(long l) {}

  @Override
  public void onUserVideoStart(long uid, int i) {}

  @Override
  public void onUserVideoStop(long l) {}

  @Override
  public void onDisconnect(int i) {}

  @Override
  public void onClientRoleChange(int i, int i1) {}

  @Override
  protected void onDestroy() {
    super.onDestroy();
    NERtcEx.getInstance().leaveChannel();
    NERtcEx.getInstance().release();
    TimerTaskUtil.uninit();
  }

  @Override
  public void onTokenExpired() {
    Log.d(LOG_TAG, "onTokenExpired");
    Toast.makeText(this, R.string.copyright_token_has_expired, Toast.LENGTH_SHORT).show();
    getSongDynamicToken(null);
  }

  private void onTokenWillExpired() {
    getSongDynamicToken(null);
  }

  /** ????????????token */
  private void getSongDynamicToken(NECopyrightedMedia.Callback<NEKaraokeDynamicToken> callback) {
    Log.d(LOG_TAG, "getSongDynamicToken");
    Runnable runnable =
        new Runnable() {
          @Override
          public void run() {
            // ??????????????????token
            String account = ((EditText) findViewById(R.id.et_music_user)).getText().toString();
            String token = getToken(account);
            NEKaraokeDynamicToken dynamicToken =
                new NEKaraokeDynamicToken(token, GenerateTestUserToken.EXPIRE_TIME);
            NECopyrightedMedia.getInstance().renewToken(dynamicToken.getAccessToken()); // ??????token
            // ????????????????????????token?????????180???(??????????????????????????????)??????token
            Runnable tokenWillExpiredTask =
                new Runnable() {
                  @Override
                  public void run() {
                    onTokenWillExpired();
                  }
                };
            long delaySeconds = (dynamicToken.getExpiresIn() - AHEAD_TIME_REFRESH_TOKEN) * 1000L;
            if (delaySeconds < 0) {
              delaySeconds = 0L;
            }
            TimerTaskUtil.addTask(TOKEN_WILL_EXPIRED_TASK_ID, tokenWillExpiredTask, delaySeconds);
            if (callback != null) {
              callback.success(dynamicToken);
            }
          }
        };
    TimerTaskUtil.addTask(REFRESH_TOKEN_TASK_ID, runnable, 0L);
  }
}
