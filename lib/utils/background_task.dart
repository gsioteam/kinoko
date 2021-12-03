
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter_git/flutter_git.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:glib/glib.dart';
import 'package:kinoko/utils/favorites_manager.dart';
import 'package:path_provider/path_provider.dart' as platform;

import 'plugin/plugin.dart';
import 'plugins_manager.dart';

class BackgroundTask {
  static const int _id = 0x3990;

  static _onSelectNotification(String? payload) {
    print("Payload $payload");
  }

  static Future<FlutterLocalNotificationsPlugin> _initNotification() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('noti_icon');
    final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings();
    final MacOSInitializationSettings initializationSettingsMacOS =
    MacOSInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsMacOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);

    return flutterLocalNotificationsPlugin;
  }

  static Future<void> _checkFavorites(
      FlutterLocalNotificationsPlugin notification,
      NotificationDetails platformChannelSpecifics) async {
    List<FavCheckItem> list = [];
    var items = FavoritesManager().items.data;
    for (var item in items) {
      if (!item.value) {
        await item.checkNew(false);
        if (item.value) {
          list.add(item);
        }
      }
    }
    if (list.isNotEmpty) {
      List<String> strs = [];
      for (int i = 0, t = math.min(3, list.length); i < t; ++i) {
        strs.add(list[i].info.title);
      }
      await notification.show(
          0, 'New chapter', '${strs.join(',')}${list.length > 3 ? "..." : ''}', platformChannelSpecifics);
    }
  }

  static Future<void> _fetchPlugins(FlutterLocalNotificationsPlugin notification,
      NotificationDetails platformChannelSpecifics) async {
    await GitRepository.initialize();
    await PluginsManager.instance.ready;

    List<String> updates = [];

    var list = PluginsManager.instance.plugins.data;
    for (var info in list) {
      String id = PluginsManager.instance.calculatePluginID(info.src);
      Plugin? plugin  = PluginsManager.instance.findPlugin(id);
      if (plugin != null) {
        String path = "${PluginsManager.instance.root.path}/$id";
        GitRepository repo = GitRepository(path);

        if (repo.open()) {
          String branch = info.branch ?? "master";

          if (repo.getSHA1("refs/heads/$branch") == repo.getSHA1("refs/remotes/origin/$branch")) {
            GitController controller = GitController(repo);
            await repo.fetch(controller);

            if (repo.getSHA1("refs/heads/$branch") != repo.getSHA1("refs/remotes/origin/$branch")) {
              updates.add(info.title);
            }
            controller.dispose();
          }
        }

        repo.dispose();
      }
    }

    if (updates.isNotEmpty) {
      await notification.show(
          0, 'New version', '${updates.length} plugins can be updated', platformChannelSpecifics);
    }
  }

  static _callback() async {
    Directory dir = await platform.getApplicationSupportDirectory();

    await Glib.setup(dir.path);

    FlutterLocalNotificationsPlugin notification = await _initNotification();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails('kinoko_bg_checking', 'kinoko',
        channelDescription: 'Background checking',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _checkFavorites(notification, platformChannelSpecifics);
    await _fetchPlugins(notification, platformChannelSpecifics);

    Glib.destroy();
  }

  static Future<void> setup() async {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
      await AndroidAlarmManager.periodic(const Duration(seconds: 10), _id, _callback);
    }
  }
}