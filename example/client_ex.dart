import 'package:pxdart/pxdart.dart';
import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  var c = PixivClient();
  await c.connect("******");
  // print(await c.getUserDetails(29431640));
  // print(await c.getUserIllusts(29431640));
  await c.searchIllust("lmao");
}
