# 添加依赖
此包是在flutter_app_upgrade的版本上做的升级重构，以适配flutter3.10.0版本
1、在`pubspec.yaml`中加入：

```
dependencies:
  flutter_upgrade: # 版本升级
    git:
      url: https://github.com/ZhouC125/flutter_upgrade.git
      tag: v3.0.3
```

2、执行flutter命令获取包：
```
flutter pub get`
```

3、引入

```
import 'package:flutter_upgrade/flutter_upgrade.dart';

```

4、如果你需要支持Android平台，在`./android/app/src/main/AndroidManifest.xml`文件中配置`provider`，代码如下：

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.flutter.laomeng.flutter_upgrade_example">
    <application
        android:name="io.flutter.app.FlutterApplication"
        android:icon="@mipmap/ic_launcher"
        android:label="flutter_upgrade_example">
				...
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="com.flutter.laomeng.flutter_upgrade_example.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                tools:replace="android:resource"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
</manifest>
```

>  注意：provider中authorities的值为当前App的包名，和顶部的package值保持一致。


## Flutter App 升级功能流程

应用程序升级功能是App的基础功能之一，如果没有此功能会造成用户无法升级，应用程序的bug或者新功能老用户无法触达，甚至损失这部分用户。


对于应用程序升级功能的重要性就无需赘言了，下面介绍下应用程序升级功能的几种方式，从平台方面来说：

- IOS平台，应用程序升级功能只能通过跳转到app store进行升级。
- Android平台，既可以通过跳转到应用市场进行升级，也可以下载apk包升级。

从强制性来说可以分别强制升级和非强制升级：

- 强制升级：就是用户必须升级才能继续使用App，如果不是非常必要不建议使用如此强硬的方式，会造成用户的反感。
- 非强制升级就是允许用户点击“取消”，继续使用App。



下面分别介绍IOS和Android升级流程。

## IOS升级流程

IOS升级流程如下：

![](https://github.com/781238222/imgs/raw/master/flutter_upgrade/app_upgrade_1.png)

流程说明：

1. 通常我们会访问后台接口获取是否有新的版本，如果有新的版本则弹出提示框，判断当前版本是否为“强制升级”，如果是则只提供用户一个“升级”的按钮，否则提供用户“升级”和“取消”按钮。
2. 弹出提示框后用户选择是否升级，如果选择“取消”，提示框消失，如果选择“升级”，跳转到app store进行升级。



## Android 升级流程

相比ios的升级过程，Android就稍显复杂了，流程图如下：

![](https://github.com/781238222/imgs/raw/master/flutter_upgrade/app_upgrade_2.png)

流程说明：

1. 访问后台接口获取是否有新的版本，这里和IOS是一样的，有则弹出升级提示框，判断当前版本是否为“强制升级”，如果是则只提供用户一个“升级”的按钮，否则提供用户“升级”和“取消”按钮。
2. 弹出提示框后有用户选择是否升级，如果选择“取消”，提示框消失，如果选择“升级”，判断是跳转到应用市场进行升级还是通过下载apk升级。
3. 如果下载apk升级，则开始下载apk，下载完成后跳转到apk安装引导界面。
4. 如果跳转到应用市场升级，判断是否指定了应用市场，比如只在华为应用市场上架了，那么此时需要指定跳转到华为应用市场，即使你在很多应用市场都上架了，也应该根据用户手机安装的应用市场指定一个应用市场，让用户选择应用市场不是一个好的体验，而且用户也不知道应该去哪个市场更新，如果用户选择了一个你没有上架的应用市场，那就更尴尬了。
5. 指定应用市场后直接跳转到指定的应用市场的更新界面。

