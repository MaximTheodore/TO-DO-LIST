import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationsEnabled') ?? false;
  }

  Future<void> initNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'task_channel',
            channelName: 'Уведомления о задачах',
            channelDescription: 'Напоминания о задачах',
            importance: NotificationImportance.High,
            playSound: true,
            enableVibration: true,
          ),
        ],
        debug: true,
      );

      await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
        if (!isAllowed) {
          AwesomeNotifications().requestPermissionToSendNotifications();
        }
      });

      await _firebaseMessaging.requestPermission();
      final token = await _firebaseMessaging.getToken();
      print("Токен Firebase: $token");

      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (e) {
      print("Ошибка инициализации уведомлений: $e");
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.notification != null) {
      await showNotification(
        title: message.notification!.title ?? "Новое уведомление",
        body: message.notification!.body ?? "Проверьте задачу",
      );
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!(await _areNotificationsEnabled())) {
      print("Уведомления отключены в настройках пользователя");
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'task_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
      ),
    ).then((_) => print("Уведомление успешно отображено"))
        .catchError((error) => print("Ошибка отображения уведомления: $error"));
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      if (!(await _areNotificationsEnabled())) {
        print("Запланированные уведомления отключены в настройках пользователя");
        return;
      }

      print("Планирование уведомления с ID: $id на $scheduledTime");
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (alarmStatus.isDenied) {
        print("Запрос разрешения SCHEDULE_EXACT_ALARM...");
        await Permission.scheduleExactAlarm.request();
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'task_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      print("Уведомление успешно запланировано");
    } catch (e) {
      print("Ошибка планирования уведомления: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id)
        .then((_) => print("Уведомление $id успешно отменено"))
        .catchError((error) => print("Ошибка отмены уведомления: $error"));
  }
}

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool('notificationsEnabled') ?? false)) {
    print("Фоновые уведомления отключены в настройках пользователя");
    return;
  }

  if (message.notification != null) {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'task_channel',
        title: message.notification!.title ?? "Новое уведомление",
        body: message.notification!.body ?? "Проверьте задачу",
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
      ),
    );
  }
}