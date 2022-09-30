// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.kit.copyrightedmediademo.debug;

import android.util.Base64;
import com.google.gson.Gson;
import com.netease.yunxin.kit.copyrightedmediademo.AppConfig;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Map;

/*
 * 类名:   GenerateTestUserToken
 *
 * 作用: 用于生成测试用的 User Token，当您使用正版曲库 SDK 时，需要传入 Token，才会返回正版曲库相关数据。
 *           生成的 Token 是动态且临时有效的，有效期由您自行设置，建议不要太长。
 *           其计算方法是对 App Key、App Secret和 user 进行加密，加密算法为 SHA-1。
 *
 * 注意: 请不要将如下代码发布到您的线上正式版本的 App 中，原因如下：
 *
 *            本文件中的代码虽然能够正确计算出 Token，但仅适合快速调通 SDK 的基本功能，不适合线上产品，
 *            这是因为客户端代码中的 App Secret 很容易被反编译逆向破解，尤其是 Web 端的代码被破解的难度几乎为零。
 *            一旦您的密钥泄露，攻击者就可以计算出正确的 Token 来盗用您的版权服务。
 *
 *            正确的做法是将 Token 的代码和 AppSecret 放在您的业务服务器上，然后由 App 按需向您的服务器获取实时算出的 Token。
 *            由于破解服务器的成本要高于破解客户端 App，所以服务器计算的方案能够更好地保护您的加密密钥。
 *
 * 参考：https://doc.yunxin.163.com/karaoke/docs/jk2NzM1NTc?platform=server
 */
public class GenerateTestUserToken {
  /**
   * token过期时间，建议不要设置的太长
   *
   * <p>时间单位：秒 过期时间：10 * 60 = 600 = 10 分钟
   */
  public static final Long EXPIRE_TIME = 600L;

  /**
   * 计算 Token 用的加密密钥AppSecret，获取步骤如下：
   *
   * <p>注意：该方案仅适用于调试Demo，正式上线前请将 Token 计算代码和 AppSecret 迁移到您的后台服务器上，以避免加密密钥泄露导致的流量盗用。
   * 文档：https://doc.yunxin.163.com/Tk5NzkwOTY/docs/TA1ODMzMDc?platform=console
   */
  private static final String APP_SECRET = "your app secret";

  /**
   * 应用 App Key：
   *
   * <p>文档：https://doc.yunxin.163.com/Tk5NzkwOTY/docs/TA1ODMzMDc?platform=console
   */
  //    private static final String APP_KEY = AppConfig.getAppKey();
  private static final String APP_KEY = AppConfig.getAppKey();

  /**
   * 获取用户token
   *
   * @param user user用来对账时标记一个客户
   * @return
   */
  public static String genTestUserToken(String user) {
    long curTime = System.currentTimeMillis();
    Map<String, Object> params = new HashMap<>();
    params.put(
        "signature",
        getSignature(
            APP_KEY, user, String.valueOf(curTime), String.valueOf(EXPIRE_TIME), APP_SECRET));
    params.put("identification", user);
    params.put("curTime", curTime);
    params.put("ttl", EXPIRE_TIME);
    String result = new Gson().toJson(params);
    return Base64.encodeToString(result.getBytes(), Base64.NO_WRAP);
  }

  private static final char[] HEX_DIGITS = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
  };

  /**
   * 生成signature，将App Key、App Secret、user、curTime、ttl五个字段拼成一个字符串，进行sha1编码
   *
   * @param appKey 应用 App Key
   * @param user 用户id
   * @param curTime 当前时间
   * @param ttl 有效期，单位是秒
   * @param appSecret 应用 AppSecret
   * @return
   */
  public static String getSignature(
      String appKey, String user, String curTime, String ttl, String appSecret) {
    return encode("sha1", appKey + user + curTime + ttl + appSecret);
  }

  private static String encode(String algorithm, String value) {
    if (value == null) {
      return null;
    }
    try {
      MessageDigest messageDigest = MessageDigest.getInstance(algorithm);
      messageDigest.update(value.getBytes("UTF-8"));
      return getFormattedText(messageDigest.digest());
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

  private static String getFormattedText(byte[] bytes) {
    int len = bytes.length;
    StringBuilder buf = new StringBuilder(len * 2);
    for (int j = 0; j < len; j++) {
      buf.append(HEX_DIGITS[(bytes[j] >> 4) & 0x0f]);
      buf.append(HEX_DIGITS[bytes[j] & 0x0f]);
    }
    return buf.toString();
  }
}
