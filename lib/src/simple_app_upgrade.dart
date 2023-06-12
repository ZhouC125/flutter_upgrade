import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../flutter_upgrade.dart';
import 'gradient_linear_progress_bar.dart';

///
/// des:app升级提示控件
///
class SimpleAppUpgradeWidget extends StatefulWidget {
  const SimpleAppUpgradeWidget(
      {required this.title,
      this.titleStyle,
      this.contents,
      this.contentStyle,
      this.cancelText,
      this.cancelTextStyle,
      this.okText,
      this.okTextStyle,
      this.okBackgroundColors,
      this.progressBar,
      this.progressBarColor,
      this.borderRadius = 10,
      this.downloadUrl,
      this.force = false,
      this.iosAppId,
      this.appMarketInfo,
      this.onError,
      this.onOk,
      this.downloadProgress,
      this.topWidget,
      this.downloadStatusChange});

  ///
  /// 升级标题
  ///
  final String title;

  ///
  /// 标题样式
  ///
  final TextStyle? titleStyle;

  ///
  /// 升级提示内容
  ///
  final List<String>? contents;

  ///
  /// 提示内容样式
  ///
  final TextStyle? contentStyle;

  ///
  /// 下载进度条
  ///
  final Widget? progressBar;

  ///
  /// 进度条颜色
  ///
  final Color? progressBarColor;

  ///
  /// 确认控件
  ///
  final String? okText;

  ///
  /// 确认控件样式
  ///
  final TextStyle? okTextStyle;

  ///
  /// 确认控件背景颜色,2种颜色左到右线性渐变
  ///
  final List<Color>? okBackgroundColors;

  ///
  /// 取消控件
  ///
  final String? cancelText;

  ///
  /// 取消控件样式
  ///
  final TextStyle? cancelTextStyle;

  ///
  /// app安装包下载url,没有下载跳转到应用宝等渠道更新
  ///
  final String? downloadUrl;

  ///
  /// 圆角半径
  ///
  final double borderRadius;

  ///
  /// 是否强制升级,设置true没有取消按钮
  ///
  final bool force;

  ///
  /// ios app id,用于跳转app store
  ///
  final String? iosAppId;

  ///
  /// 指定跳转的应用市场，
  /// 如果不指定将会弹出提示框，让用户选择哪一个应用市场。
  ///
  final AppMarketInfo? appMarketInfo;

  final ValueChanged? onError;
  final VoidCallback? onOk;
  final DownloadProgressCallback? downloadProgress;
  final DownloadStatusChangeCallback? downloadStatusChange;

  final Widget? topWidget;

  @override
  State<StatefulWidget> createState() => _SimpleAppUpgradeWidget();
}

class _SimpleAppUpgradeWidget extends State<SimpleAppUpgradeWidget> {
  static final String _downloadApkName = 'temp.apk';

  DownloadStatus _downloadStatus = DownloadStatus.none;

  StreamController<double> _streamController = StreamController();

  /// 取消下载的token
  CancelToken? cancelToken;
  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        children: [
          Positioned(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  const Radius.circular(8),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      offset: Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 0,
                      color: Color(0xFF000000).withOpacity(0.05))
                ],
              ),
              margin: EdgeInsets.only(top: 68),
              padding: EdgeInsets.only(top: 77),
              child: _buildDownloadProgress,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: widget.topWidget ??
                Container(
                  height: 145,
                  width: 288,
                ),
          )
        ],
      ),
    );
  }

  ///
  /// 下载进度widget
  ///
  Widget get _buildDownloadProgress {
    return StreamBuilder<double>(
      stream: _streamController.stream,
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if (!snapshot.hasData ||
            (snapshot.data != null && snapshot.data! <= 0)) {
          return _updateContents;
        }
        return _updateProgress(snapshot.data!);
      },
    );
  }

  ///
  /// 发现新版本界面
  ///
  Widget get _updateContents => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //标题
          _buildTitle(widget.title),
          //更新信息
          _buildAppInfo(),
          GestureDetector(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: 24,
              ).copyWith(bottom: 24),
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(21)),
                color: Color(0xFF0086FB),
              ),
              alignment: Alignment.center,
              child: Text(
                '立即更新',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: _clickOk,
          )
        ],
      );

  ///
  /// 更新版本界面
  ///
  Widget _updateProgress(double _s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //标题
        _buildTitle('正在更新中'),
        Container(
            margin: EdgeInsets.only(top: 39, bottom: 6, left: 24, right: 40),
            height: 20,
            child: Stack(
              children: [
                GradientLinearProgressBar(
                  strokeCapRound: true,
                  strokeWidth: 20,
                  colors: [Color(0xFF00BBFD), Color(0xFF0086FB)],
                  backgroundColor: Color(0xFFF0F0F0),
                  value: _s,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(_s * 100).toStringAsFixed(1)} %',
                    style: TextStyle(color: Color(0xFF59595B), fontSize: 14),
                  ),
                )
              ],
            )),
        Text(
          _downloadStatus == DownloadStatus.error ? '下载异常' : '新版本正在更新中，请等候…',
          style: TextStyle(
              color: Color(0xFF000000).withOpacity(0.35), fontSize: 12),
        ),
        GestureDetector(
          child: Container(
            margin: EdgeInsets.only(top: 58, bottom: 32),
            color: Colors.white,
            alignment: Alignment.center,
            child: Text(
              '取消更新',
              style: TextStyle(
                color: Color(0xFF000000).withOpacity(0.45),
                fontSize: 16,
              ),
            ),
          ),
          onTap: () {
            try {
              _updateDownloadStatus(DownloadStatus.cancel);
              cancelToken?.cancel();
            } catch (e) {}
          },
        )
      ],
    );
  }

  ///
  /// 构建标题
  ///
  _buildTitle(String title) {
    return Container(
      alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0086FB).withOpacity(0.85))));
  }

  ///
  /// 构建版本更新信息
  ///
  _buildAppInfo() {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        constraints: BoxConstraints(
          maxHeight: 160,
          minHeight: 110,
        ),
        child: CupertinoScrollbar(
          child: SingleChildScrollView(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children:widget.contents!.map((f) {
               return Text(
                 f,
                 style: widget.contentStyle ??
                     TextStyle(color: Color(0xFF59595B), fontSize: 16),
               );
             }).toList(),
           ),
          ),
        ));
  }

  ///
  /// 点击确定按钮
  ///
  _clickOk() async {
    if (Platform.isIOS) {
      widget.onOk?.call();
      return;
    }

    ///没有下载地址直接走fir
    if (widget.downloadUrl == null || widget.downloadUrl!.isEmpty) {
      widget.onOk?.call();
      ////没有下载地址，跳转到第三方渠道更新，原生实现
      //// FlutterUpgrade.toMarket(appMarketInfo: widget.appMarketInfo!);
      return;
    }
    String path = await FlutterUpgrade.apkDownloadPath;
    _downloadApk(widget.downloadUrl!, '$path/$_downloadApkName');
  }

  ///
  /// 下载apk包
  ///
  _downloadApk(String url, String path) async {
    if (_downloadStatus == DownloadStatus.start ||
        _downloadStatus == DownloadStatus.downloading ||
        _downloadStatus == DownloadStatus.done) {
      print('当前下载状态：$_downloadStatus,不能重复下载。');
      return;
    }

    _updateDownloadStatus(DownloadStatus.start);
    try {
      var dio = Dio();
      cancelToken = CancelToken();
      await dio.download(url, path, cancelToken: cancelToken,
          onReceiveProgress: (int count, int total) {
        if (total != -1 &&
            (_downloadStatus == DownloadStatus.none ||
                _downloadStatus == DownloadStatus.start)) {
          widget.downloadProgress?.call(count, total);
          _streamController.add(count / total.toDouble());
        }
      }).then((value) {
        //下载完成，跳转到程序安装界面
        FlutterUpgrade.installAppForAndroid(path);
        _streamController.add(0);
        _updateDownloadStatus(DownloadStatus.none);
      }).catchError((e) {
        _streamController.add(0);
        if (_downloadStatus == DownloadStatus.cancel) {
          return;
        }

        /// 下载出错
        /// 任务状态-失败，取消状态造成的下载报错 不处理
        _updateDownloadStatus(DownloadStatus.error, error: e);
        widget.onError?.call(e);
      });
    } catch (e) {
      print('$e');
      _streamController.add(0);
      if (_downloadStatus == DownloadStatus.cancel) {
        return;
      }
      _updateDownloadStatus(DownloadStatus.error, error: e);
    }
  }

  _updateDownloadStatus(DownloadStatus downloadStatus, {dynamic error}) {
    _downloadStatus = downloadStatus;
    widget.downloadStatusChange?.call(_downloadStatus, error: error);
  }
}
