import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../flutter_upgrade.dart';

///
/// des:app升级提示控件
///
class SimpleAppUpgradeWidget extends StatefulWidget {
  const SimpleAppUpgradeWidget(
  {@required this.title,
        this.titleStyle,
        @required this.contents,
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
        this.downloadStatusChange});

  ///
  /// 升级标题
  ///
  final String? title;

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

  final VoidCallback? onError;
  final VoidCallback? onOk;
  final DownloadProgressCallback? downloadProgress;
  final DownloadStatusChangeCallback? downloadStatusChange;

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
          Align(
            alignment: Alignment.center,
            child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                borderRadius: BorderRadius.circular((8)),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 0),
                    blurRadius: 4,
                    spreadRadius: 0,
                    color: Color(0xFF000000).withOpacity(0.02),
                  )
                ],
              ),
              margin: const EdgeInsets.only(top: 68),
              // color: Colors.blue,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //标题
                  _buildTitle(),
                  //更新信息
                  _buildAppInfo(),
                  Divider(
                    height: 1,
                    color: Colors.grey,
                  ),
                  _buildDownloadProgress,

                ],
              ),
            ),
          ),
          Positioned.fill(
            top: 0,
            child: Container(
              height: 145,
              child:  Image.asset('images/update_bg.png'),
            ),
          )
        ],
      ),
    );

  }

  ///
  /// 构建标题
  ///
  _buildTitle() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(widget.title ?? '',
            style: widget.titleStyle ?? TextStyle(fontSize: 22)));
  }

  ///
  /// 构建版本更新信息
  ///
  _buildAppInfo() {
    return Container(
        margin: EdgeInsets.only(left: 15, right: 15,bottom: 10),
        height: 200,
        child: CupertinoScrollbar(
          child: ListView(
            children: widget.contents!.map((f) {
              return Text(
                f,
                style: widget.contentStyle ?? TextStyle(),
              );
            }).toList(),
          ),
        ));
  }

  ///
  /// 取消按钮
  ///
  Widget get _buildCancelActionButton{
    return InkWell(
        child: Container(
          height: 45,
          alignment: Alignment.center,
          child: Text(widget.cancelText ?? '取消下载',
              style: widget.cancelTextStyle ?? TextStyle()),
        ),
        onTap: () {
          try {
            _updateDownloadStatus(DownloadStatus.cancel);
            cancelToken?.cancel();
          } catch (e) {

          }
        }
    );
  }

  ///
  /// 确定按钮
  ///
  Widget get _buildOkActionButton{
    return InkWell(
      child: Container(
        height: 50,
        alignment: Alignment.center,
        child: Text(widget.okText ?? '立即体验',
            style: widget.okTextStyle ?? TextStyle(color: Colors.white,fontSize: 30)),
      ),
      onTap: () {
        _clickOk();
      },
    );
  }

  ///
  /// 下载进度widget
  ///
  Widget get _buildDownloadProgress{
    return StreamBuilder<double>(
      stream:_streamController.stream,
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
        if(!snapshot.hasData || (snapshot.data != null && snapshot.data! <= 0)){
          return SizedBox(
            height: 50,
            child: _buildOkActionButton,
          );
        }
        return Container(
          // height: 50,
          padding: EdgeInsets.symmetric(horizontal: 20).copyWith(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: Container(
                      height: 5,
                      decoration: new BoxDecoration(
                        borderRadius: BorderRadius.circular((4)),
                      ),
                      child:ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        child: LinearProgressIndicator(
                          backgroundColor:Color(0xFF000000).withOpacity(0.04),
                          value: snapshot.data,
                          valueColor: new AlwaysStoppedAnimation<Color>(_downloadStatus == DownloadStatus.error? Color(0xFF000000).withOpacity(0.25) : Color(0xFF538DFF)),
                        ),
                      )
                  )),
                  SizedBox(width: 10),
                  Text('${(snapshot.data!*100).toStringAsFixed(1)} %')
                ],
              ),
              _buildCancelActionButton
            ],
          ),
        );
      },
    );
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
      cancelToken  = CancelToken();
      await dio.download(url, path, cancelToken: cancelToken, onReceiveProgress: (int count, int total) {
        if (total != -1 && (_downloadStatus == DownloadStatus.none || _downloadStatus == DownloadStatus.start )) {
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
        if(_downloadStatus == DownloadStatus.cancel){
          return;
        }
        /// 下载出错
        /// 任务状态-失败，取消状态造成的下载报错 不处理
        _updateDownloadStatus(DownloadStatus.error,error: e);
        widget.onError?.call();
      });
    } catch (e) {
      print('$e');
      _streamController.add(0);
      if(_downloadStatus == DownloadStatus.cancel){
        return;
      }
      _updateDownloadStatus(DownloadStatus.error,error: e);
    }
  }

  _updateDownloadStatus(DownloadStatus downloadStatus, {dynamic error}) {
    _downloadStatus = downloadStatus;
    widget.downloadStatusChange?.call(_downloadStatus, error: error);
  }
}
