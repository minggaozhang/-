import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '防风控守护增强版',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String appPkg = "com.gof.china";
  int intervalTime = 12;
  String logText = "日志输出区域\n";

  // 执行ROOT命令
  Future<String> runRoot(String cmd) async {
    try {
      final res = await Process.run("su", ["-c", cmd]);
      return res.stdout.trim() + res.stderr.trim();
    } catch (e) {
      return "错误：$e";
    }
  }

  // 追加日志
  void addLog(String msg) {
    setState(() {
      logText += "${DateTime.now().toString().substring(11,19)} | $msg\n";
    });
  }

  // 启动增强守护
  Future<void> startGuard() async {
    addLog("开始启动守护...");
    final String shell = '''
APP="$appPkg"
INTERVAL=$intervalTime
su -c "
am force-stop \$APP 2>/dev/null
killall -9 \$APP etd etd_svr security rmserver 2>/dev/null
pkill -9 etd security 2>/dev/null
rm -rf /data/data/\$APP/cache/* /data/data/\$APP/shared_prefs/*
rm -rf /sdcard/Android/data/\$APP/cache/* /sdcard/Android/data/\$APP/files/log/*
rm -rf /sdcard/Android/data/\$APP/files/.etd* /data/local/tmp/etd* /cache/*.log
rm -rf /data/local/tmp/*.log /data/data/\$APP/lib/libNetHTProtect.so.tmp
rm -rf /sdcard/Android/data/\$APP/files/.so_load* 2>/dev/null
mkdir -p /sdcard/Android/data/\$APP/files 2>/dev/null
echo '' > /sdcard/Android/data/\$APP/files/.motion
echo '' > /sdcard/Android/data/\$APP/files/.safe
chmod 444 /sdcard/Android/data/\$APP/files/.motion 2>/dev/null
chmod 444 /sdcard/Android/data/\$APP/files/.safe 2>/dev/null
(while true;
do
  killall -9 etd etd_svr security rmserver 2>/dev/null
  pkill -9 etd 2>/dev/null
  rm -rf /sdcard/Android/data/\$APP/files/log/* /sdcard/Android/data/\$APP/files/.etd*
  rm -rf /data/local/tmp/etd* /cache/*.log /data/local/tmp/*.log 2>/dev/null
  echo '' > /sdcard/Android/data/\$APP/files/.motion
  echo '' > /sdcard/Android/data/\$APP/files/.safe
  chmod 444 /sdcard/Android/data/\$APP/files/.motion 2>/dev/null
  chmod 444 /sdcard/Android/data/\$APP/files/.safe 2>/dev/null
  sleep \$INTERVAL
done &)
" >/dev/null 2>&1
''';
    await runRoot(shell);
    addLog("✅ 守护启动成功，间隔：${intervalTime}s");
  }

  // 检测状态
  Future<void> checkStatus() async {
    final res = await runRoot("pgrep -f 'while true'");
    if(res.isNotEmpty){
      addLog("✅ 守护正在运行中");
    }else{
      addLog("❌ 守护未运行");
    }
  }

  // 停止守护
  Future<void> stopGuard() async {
    await runRoot("pkill -f 'while true' 2>/dev/null;pkill -9 etd etd_svr security 2>/dev/null");
    addLog("✅ 守护已完全停止");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GofChina 防风控·增强版")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 间隔调节
            Row(
              children: [
                const Text("循环间隔："),
                Expanded(
                  child: Slider(
                    min: 5,max: 30,
                    value: intervalTime.toDouble(),
                    onChanged: (v)=>setState(()=>intervalTime = v.toInt()),
                  ),
                ),
                Text("${intervalTime}s"),
              ],
            ),
            const SizedBox(height: 10),
            // 功能按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(onPressed: startGuard,child: const Text("启动守护")),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(onPressed: checkStatus,child: const Text("检测状态")),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(onPressed: stopGuard,style: ElevatedButton.styleFrom(backgroundColor: Colors.red),child: const Text("停止守护")),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // 日志面板
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey),borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(child: Text(logText,style: const TextStyle(fontSize: 12))),
              ),
            )
          ],
        ),
      ),
    );
  }
}
