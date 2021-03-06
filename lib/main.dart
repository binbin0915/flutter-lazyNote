import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './views/login/Login.dart';
import './views/mine/Mine.dart';
import './views/objective/AddObjective.dart';
import './views/objective/ObjectiveList.dart';
import './views/register/Register.dart';
import 'models/index.dart';
import 'provider/index.dart';
import 'utils/FadeRoute.dart';
import 'utils/HttpUtil.dart';
import 'utils/PromptUtil.dart';

void main() async {
  final userInfo = UserProviderModel();
  final globalInfo = GlobalProviderModel();
  final objectiveListInfo = ObjectiveProviderModel();
  WidgetsFlutterBinding.ensureInitialized();
  // 强制竖屏
  // If you're running an application and need to access the binary messenger before `runApp()` has been called (for example, during plugin initialization), then you need to explicitly call the `WidgetsFlutterBinding.ensureInitialized()` first.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]).then((_) {
    runApp(MultiProvider(providers: [
      ChangeNotifierProvider<UserProviderModel>.value(value: userInfo),
      ChangeNotifierProvider<GlobalProviderModel>.value(value: globalInfo),
      ChangeNotifierProvider<ObjectiveProviderModel>.value(
          value: objectiveListInfo)
    ], child: MyApp()));
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        // 沉浸式透明
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        // 该属性仅用于 iOS 设备顶部状态栏亮度
        statusBarBrightness: Brightness.light,
        // 底部导航的设置
        systemNavigationBarColor: Colors.white,
        systemNavigationBarDividerColor: Colors.grey,
        systemNavigationBarIconBrightness: Brightness.dark));
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: MaterialApp(
        title: '懒得记',
        locale: Locale('zh'),
        theme: ThemeData(
          primarySwatch: Colors.blue,
//        platform: TargetPlatform.iOS
        ),
        home: MyHomePage(title: '懒得记'),
        routes: {
          '/login': (context) => LoginWidget(),
          '/register': (context) => RegisterWidget()
        },
        // route change animation
        onGenerateRoute: (setting) {
          switch (setting.name) {
            case '/addObjective':
              return FadeRoute(AddObjective());
            default:
              return null;
          }
        },
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        supportedLocales: [const Locale('en', 'US'), const Locale('zh', 'CH')],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _navSelectedIndex = 0;
  final _contentItems = [ObjectiveListWidget(), MineWidget()];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 注册监听器
    fetchUserDetail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除监听器
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print(AppLifecycleState.resumed);
        break;
      case AppLifecycleState.inactive:
        print(AppLifecycleState.inactive);
        break;
      case AppLifecycleState.paused:
        print(AppLifecycleState.paused);
        break;
      default:
        break;
    }
  }

  // 请求用户详情数据
  fetchUserDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.get('token');
    if (token != null && prefs.get('userInfo') != null) {
      final userInfo = json.decode(prefs.get('userInfo'));
      UserInfoModel prefsUserInfo = UserInfoModel.fromJson(userInfo);
      var userId = prefsUserInfo.userId;
      Map<String, dynamic> params = {'userId': userId};
      try {
        var res =
            await Http.getInstance().get('/user/queryDetail', data: params);
        var result = UserInfoModel.fromJson(res);
        Provider.of<GlobalProviderModel>(context, listen: false)
            .changeLoginStatus(true);
        Provider.of<UserProviderModel>(context, listen: false).setUserData(
            userName: result.userName,
            userId: result.userId,
            phone: result.phone,
            email: result.email);
      } on Exception catch (_) {
        print('fetchUserDetail request error');
      }
    }
  }

  // 新增小目标
  void addObjective() {
    if (!Provider.of<GlobalProviderModel>(context, listen: false).isLogin) {
      PromptUtil.openToast('您还未登录...',
          bgColor: Colors.white, textColor: Colors.black, fadeTime: 1);
      return;
    }
    Navigator.pushNamed(context, '/addObjective');
  }

  // 导航点击切换index
  void onNavClick(int index) {
    setState(() {
      _navSelectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
//          brightness: Brightness.dark,
          // Adaptive: android title is left
          centerTitle: true),
      body: Center(child: _contentItems[_navSelectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.collections_bookmark), title: Text('目标')),
            BottomNavigationBarItem(
                icon: Icon(Icons.people), title: Text('我的')),
          ],
          currentIndex: _navSelectedIndex,
          fixedColor: Colors.blue,
          type: BottomNavigationBarType.fixed,
          onTap: onNavClick),
      floatingActionButton: FloatingActionButton(
        onPressed: addObjective,
        tooltip: '新增目标',
        child: Icon(Icons.add),
      ),
    );
  }
}
