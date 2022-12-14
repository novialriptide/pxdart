import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

  Future<Map> connect(String refreshToken) async {
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
    var decodedResponse = readResponse(response.bodyBytes);
    accessToken = decodedResponse["access_token"];

    return decodedResponse;
  }

  Map readResponse(Uint8List bytes) {
    var decoded = jsonDecode(utf8.decode(bytes)) as Map;

    if (decoded.keys.contains("error")) {
      throw Exception(decoded.toString());
    } else {
      return decoded;
    }
  }

  Future<Map> httpGet(
      String path, Map<String, String> body, Map<String, String> header) async {
    Uri uri = Uri.https("app-api.pixiv.net", path, body);
    var response = await httpClient.get(uri, headers: header);
    Map decodedResponse = readResponse(response.bodyBytes);
    return decodedResponse;
  }

  Future<Map> getUserDetails(int userId) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {
      "user_id": userId.toString(),
      "filter": "for_ios",
    };
    return await httpGet("/v1/user/detail", body, header);
  }

  Future<Map> getUserIllusts(int userId, {int offset = 0}) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {
      "user_id": userId.toString(),
      "offset": offset.toString(),
      "filter": "for_ios",
    };
    return await httpGet("/v1/user/illusts", body, header);
  }

  Future<Map> getUserBookmarkedIllusts(int userId) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {
      'user_id': userId.toString(),
      'restrict': 'public'
    };
    return await httpGet("/v1/user/bookmarks/illust", body, header);
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

  Future<Map> getIllustRelated(int illustId) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {
      "illust_id": illustId.toString(),
    };
    return await httpGet("/v2/illust/related", body, header);
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

  Future<Map> getSearchAutoComplete(String word) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {'word': word};
    word = Uri.encodeComponent(word);
    return await httpGet("/v1/search/autocomplete", body, header);
  }

  Future<Map> getSearchAutoCompleteV2(String word) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {'word': word};
    word = Uri.encodeComponent(word);
    return await httpGet("/v2/search/autocomplete", body, header);
  }

  Future<Map> searchIllust(
    String word, {
    String searchTarget = "partial_match_for_tags",
    String sort = "popular_desc",
    String duration = "",
    String startDate = "",
    String endDate = "",
    int offset = 0,
  }) async {
    // Valid `searchTarget`s:
    //  - partial_match_for_tags
    //  - exact_match_for_tags
    //  - title_and_caption
    //
    // Valid `sort`s:
    //  - date_desc
    //  - date_asc
    //  - popular_desc
    //
    // Valid `duration`s:
    //  - within_last_day
    //  - within_last_week
    //  - within_last_month
    //
    // Valid `start_date` and `end_date` examples:
    //  - `2020-07-01`

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

    return await httpGet("/v1/search/illust", body, header);
  }

  Future<Uint8List> getIllustImageBytes(String url) async {
    Map<String, String> header = getHeader();
    header["Referer"] = "https://app-api.pixiv.net/";
    String unencodedPath = url.replaceAll("https://i.pximg.net", "");
    try {
      var response = await httpClient
          .get(Uri.https("i.pximg.net", unencodedPath), headers: header);
      return response.bodyBytes;
    } catch (e) {
      return Uint8List.fromList([]);
    }
  }

  Future<Map> getPopularPreviewIllusts(String word) async {
    Map<String, String> header = getHeader();
    Map<String, String> body = {
      "word": word,
      "search_target": "partial_match_for_tags",
    };
    return await httpGet("/v1/search/popular-preview/illust", body, header);
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
