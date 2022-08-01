import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:pxdart/src/pixivuser.dart';
import 'package:pxdart/src/pixivillust.dart';

class PixivClient {
  late String accessToken;
  late String userId;
  late String displayName;
  late String userName;
  late String emailAddress;
  late bool isPremium;
  late int restrictLevel;
  late bool isMailAuthorized;
  late http.Client httpClient;
  late PixivUser user;

  String hosts = "app-api.pixiv.net";
  String refreshToken = "";
  String language = "English";

  String clientID = "MOBrBDS8blbauoSck0ZfDbtuzpyT";
  String clientSecret = "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj";
  String clientHashSecret =
      "28c1fdd170a5204386cb1313c7077b34f83e4aaf4aa829ce78c231e05b0bae2c";

  PixivClient() {
    httpClient = http.Client();
  }

  void exit() {
    httpClient.close();
  }

  Map<String, String> getHeader() {
    Map<String, String> header = {
      "Accept-Language": language,
      "host": "app-api.pixiv.net",
      "app-os": "ios",
      "app-os-version": "14.6",
      "user-agent": "PixivIOSApp/7.13.3 (iOS 14.6; iPhone13,2)",
      "Authorization": "Bearer $accessToken",
    };
    return header;
  }

  Future<void> connect(String refreshToken) async {
    Map<String, String> payload = {
      "get_secure_url": "1",
      "client_id": clientID,
      "client_secret": clientSecret,
      "grant_type": "refresh_token",
      "refresh_token": refreshToken,
    };
    DateTime datetime = DateTime.now();
    String month = datetime.month.toString().padLeft(2, "0");
    String day = datetime.day.toString().padLeft(2, "0");
    String hour = datetime.hour.toString().padLeft(2, "0");
    String minute = datetime.minute.toString().padLeft(2, "0");
    String second = datetime.second.toString().padLeft(2, "0");
    String localtime =
        "${datetime.year}-$month-${day}T$hour:$minute:$second+00:00";
    Map<String, String> header = {
      "Accept-Language": language,
      "x-client-time": localtime,
      "x-client-hash":
          md5.convert(utf8.encode(localtime + clientHashSecret)).toString(),
      "app-os": "ios",
      "app-os-version": "14.6",
      "user-agent": "PixivIOSApp/7.13.3 (iOS 14.6; iPhone13,2)",
      "host": "oauth.secure.pixiv.net",
    };

    var response = await httpClient.post(
      Uri.https(hosts, "/auth/token"),
      body: payload,
      headers: header,
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    userId = decodedResponse["user"]["id"];
    displayName = decodedResponse["user"]["name"];
    userName = decodedResponse["user"]["account"];
    accessToken = decodedResponse["access_token"];
    emailAddress = decodedResponse["user"]["mail_address"];
    isPremium = decodedResponse["user"]["is_premium"];
    restrictLevel = decodedResponse["user"]["x_restrict"];
    isMailAuthorized = decodedResponse["user"]["is_mail_authorized"];
  }

  Future<PixivUser> getUserDetails(int userId) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {
      "user_id": userId.toString(),
      "filter": "for_ios",
    };

    Uri uri = Uri.https("app-api.pixiv.net", "/v1/user/detail", body);
    var response = await httpClient.get(uri, headers: header);
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    return PixivUser.fromJson(decodedResponse);
  }

  Future<List> getUserIllusts(int userId) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {
      "user_id": userId.toString(),
      "filter": "for_ios",
    };

    Uri uri = Uri.https("app-api.pixiv.net", "/v1/user/illusts", body);
    var response = await httpClient.get(uri, headers: header);
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    List parsedIllusts = [];
    List illusts = decodedResponse["illusts"];
    for (int i = 0; i < illusts.length; i++) {
      parsedIllusts.add(PixivIllust.fromJson(illusts[i]));
    }

    return parsedIllusts;
  }

  Future<void> getUserBookmarkedIllusts(int userId) async {
    throw UnimplementedError();
  }

  Future<void> getUserRelated(int userId) async {
    throw UnimplementedError();
  }

  Future<void> getIllustFollow() async {
    throw UnimplementedError();
  }

  Future<void> getIllustDetail() async {
    throw UnimplementedError();
  }

  Future<void> getIllustComments() async {
    throw UnimplementedError();
  }

  Future<void> getIllustRelated() async {
    throw UnimplementedError();
  }

  Future<void> getIllustRecommended() async {
    throw UnimplementedError();
  }

  Future<void> getIllustRanking() async {
    throw UnimplementedError();
  }

  Future<void> getTrendingIllustTags() async {
    throw UnimplementedError();
  }

  /*

  Valid `searchTarget`s:
   - partial_match_for_tags
   - exact_match_for_tags
   - title_and_caption

  Valid `sort`s:
   - date_desc
   - date_asc
   - popular_desc
  
  Valid `duration`s:
   - within_last_day
   - within_last_week
   - within_last_month
  
  Valid `start_date` and `end_date` examples:
   - `2020-07-01`

  */
  Future<List> searchIllust(
    String word, {
    String searchTarget = "partial_match_for_tags",
    String sort = "popular_desc",
    String duration = "",
    String startDate = "",
    String endDate = "",
    int offset = 0,
  }) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {
      "word": word,
      "search_target": searchTarget,
      "sort": sort,
      "filter": "for_ios",
      "offset": offset.toString()
    };

    if (duration.isNotEmpty) {
      body["duration"] = duration;
    }

    if (startDate.isNotEmpty) {
      body["start_date"] = startDate;
    }

    if (endDate.isNotEmpty) {
      body["end_date"] = endDate;
    }

    Uri uri = Uri.https("app-api.pixiv.net", "/v1/search/illust", body);
    var response = await httpClient.get(uri, headers: header);

    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    List parsedIllusts = [];
    List illusts = decodedResponse["illusts"];
    for (int i = 0; i < illusts.length; i++) {
      parsedIllusts.add(PixivIllust.fromJson(illusts[i]));
    }

    return parsedIllusts;
  }

  Future<void> searchUser() async {
    throw UnimplementedError();
  }

  Future<void> getIllustBookmarkDetail() async {
    throw UnimplementedError();
  }

  Future<void> addIllustBookmark() async {
    throw UnimplementedError();
  }

  Future<void> deleteIllustBookmark() async {
    throw UnimplementedError();
  }

  Future<void> followUser() async {
    throw UnimplementedError();
  }

  Future<void> unfollowUser() async {
    throw UnimplementedError();
  }

  Future<void> getUserIllustBookmarkTags() async {
    throw UnimplementedError();
  }

  Future<void> getUserFollowing() async {
    throw UnimplementedError();
  }

  Future<void> getUserFollowers() async {
    throw UnimplementedError();
  }

  Future<void> getUserMyPixiv() async {
    throw UnimplementedError();
  }

  Future<void> getUserList() async {
    throw UnimplementedError();
  }

  Future<void> getUserNovels() async {
    throw UnimplementedError();
  }

  Future<void> getNovelSeries() async {
    throw UnimplementedError();
  }

  Future<void> getNovelText() async {
    throw UnimplementedError();
  }

  Future<void> getShowcaseArticle() async {
    throw UnimplementedError();
  }
}
