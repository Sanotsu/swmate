// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get_storage/get_storage.dart';
import 'package:proste_logger/proste_logger.dart';

import 'views/home.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  AppCatchError().run();
}

final pl = ProsteLogger();

//全局异常的捕捉
class AppCatchError {
  run() {
    ///Flutter 框架异常
    FlutterError.onError = (FlutterErrorDetails details) async {
      ///线上环境 todo
      if (kReleaseMode) {
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      } else {
        //开发期间 print
        FlutterError.dumpErrorToConsole(details);
      }
    };

    runZonedGuarded(
      () {
        //受保护的代码块
        WidgetsFlutterBinding.ensureInitialized();
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
            .then((_) async {
          await GetStorage.init();
          runApp(const SWMateApp());
        });
      },
      (error, stack) => catchError(error, stack),
    );
  }

  ///对搜集的 异常进行处理  上报等等
  catchError(Object error, StackTrace stack) async {
    //是否是 Release版本
    debugPrint("AppCatchError>>>>>>>>>> [ kReleaseMode ] $kReleaseMode");
    debugPrint('AppCatchError>>>>>>>>>> [ Message ] $error');
    pl.d(error);
    debugPrint('AppCatchError>>>>>>>>>> [ Stack ] \n$stack');

    // 弹窗提醒用户
    EasyLoading.showToast(
      error.toString(),
      duration: const Duration(seconds: 5),
      toastPosition: EasyLoadingToastPosition.top,
    );

    // 判断返回数据中是否包含"token失效"的信息
    // 一些错误处理，比如token失效这里退出到登录页面之类的
    if (error.toString().contains("token无效") ||
        error.toString().contains("token已过期") ||
        error.toString().contains("登录出错") ||
        error.toString().toLowerCase().contains("invalid")) {
      print(error);
    }
  }
}

class SWMateApp extends StatelessWidget {
  const SWMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 640), // 1080p / 3 ,单位dp
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, widget) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'SWMate',
          debugShowCheckedModeBanner: false,
          // 应用导航的观察者，导航有变化的时候可以做一些事？
          // navigatorObservers: [routeObserver],
          /// 旧版本不用默认3
          // theme: ThemeData(
          //   primarySwatch: Colors.blue,
          //   useMaterial3: false,
          // ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // form builder表单验证的多国语言
            FormBuilderLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
            ...FormBuilderLocalizations.supportedLocales,
          ],
          // 初始化的locale
          locale: const Locale('zh', 'CN'),

          /// 默认的主题
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const HomePage(),
          builder: EasyLoading.init(),
        );
      },
    );
  }
}
