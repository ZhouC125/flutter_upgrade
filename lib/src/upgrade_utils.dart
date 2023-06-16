import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../flutter_upgrade.dart';
import 'simple_app_upgrade.dart';

/// @description : 用于升级的工具类
/// @class : upgrade_utils
/// @date :  2023/6/10 21:33
/// @name : achen
class UpgradeUtils  {
  //fir渠道升级的api_token
  static  String? _firApiToken;
  //app store的id
  static String? _appStoreId;
  //app信息
  static PackageInfo? _appInfo;

  static PackageInfo? get appInfo => _appInfo;

  static void init({String? firApiToken,String? appStoreId}) async{
    UpgradeUtils._firApiToken = firApiToken;
    UpgradeUtils._appStoreId = appStoreId;
  }

  ///用于fir渠道升级
  static void firUpdate(BuildContext context,{ValueChanged? onOk, ValueChanged? onError,Widget? topWidget}) async{
    _appInfo = await PackageInfo.fromPlatform();
    if(_firApiToken == null){
      throw Exception('请先调用init方法初始化');
    }
    var params = {
      'type': Platform.isAndroid ? 'android' : 'ios',
      'api_token': _firApiToken
    };
    var dio = Dio();
    dio.get('https://api.bq04.com/apps/latest/${_appInfo?.packageName}', queryParameters: params).then((value) {
      if(value.statusCode == 200){
        var data = value.data;
        if(data['build'] != null && int.parse(data['build']) > int.parse(appInfo!.buildNumber)){
          AppUpgrade.appUpgrade(
            context,
            (c){
              return SimpleAppUpgradeWidget(
                title:'发现新版本',
                contents: [
                  data['changelog'] ?? ''
                ],
                force: true,
                downloadUrl: data['direct_install_url'],
                onOk: (){
                  onOk?.call(data['update_url']);
                },
                onError:onError,
                iosAppId: _appStoreId,
                topWidget: topWidget,
              );
            },
          );
        }
      }
    }).catchError((e) async {
      print(e);
      onError?.call(e);
    });

  }


}