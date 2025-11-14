# Proxy Cloud


<p align="center">
  <img src="assets/images/logo.png" alt="代理云标志" width="150"/>
</p>

<p align="center">
  <img src="screenshots/base.jpg" alt="代理云截图"/>
</p>

<div align="center">
  <img src="https://img.shields.io/github/downloads/code3-dev/ProxyCloud/total?label=Downloads&style=for-the-badge" alt="Downloads Badge">
</div>

<p align="center">
  <b>一个现代、功能丰富的VPN客户端，快速、无限制、安全且完全免费。</b>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="FA.md">فارسی</a> | <a href="RU.md">Русский</a>
</p>

## 🚀 概述

代理云是一款功能强大的Flutter应用程序，旨在通过V2Ray VPN技术和Telegram MTProto代理提供安全、私密的互联网访问。凭借直观的深色主题界面和全面的功能，代理云让您能够控制您的在线隐私，无需任何订阅费用或隐藏成本。

## ✨ 主要特点

### 🔒 V2Ray VPN
- **一键连接**：只需轻点一下即可立即连接到V2Ray服务器
- **订阅管理**：通过订阅URL导入、组织和更新配置
- **实时监控**：跟踪连接状态和性能指标
- **服务器选择**：浏览并从多个服务器位置中选择
- **自定义VPN设置**：为高级用户配置绕过子网和DNS选项

### 💬 Telegram代理
- **广泛的代理集合**：浏览并连接到来自世界各地的MTProto代理
- **详细信息**：查看每个代理的国家、提供商、ping和正常运行时间统计信息
- **无缝集成**：通过选定的代理一键连接到Telegram
- **轻松共享**：将代理详细信息复制到剪贴板以与他人共享

### 🛠️ 高级工具
- **IP信息**：查看有关您当前IP地址和位置的详细信息
- **主机检查器**：测试任何网络主机的状态、响应时间和详细信息
- **速度测试**：测量您的互联网连接下载和上传速度
- **订阅商店**：从精选集合中发现并添加新的V2Ray配置
- **订阅管理器**：在一个地方添加、编辑、删除和更新您的V2Ray订阅

### 🎨 现代UI/UX
- **时尚的深色主题**：优雅的深色界面，带有绿色点缀，便于查看
- **直观导航**：底部导航栏，轻松访问所有功能
- **流畅动画**：整个应用程序中的精致过渡和视觉效果
- **实时指示器**：连接状态的视觉反馈（已连接、正在连接、已断开连接）
- **响应式设计**：针对各种屏幕尺寸和方向进行了优化

## 📱 安装

### 下载

| Architecture | Download Link |
|-------------|---------------|
| Universal   | <a href="https://github.com/code3-dev/ProxyCloud/releases/latest/download/proxycloud-universal.apk"><img src="https://img.shields.io/badge/Android-Universal-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android Universal"></a> |
| armeabi-v7a | <a href="https://github.com/code3-dev/ProxyCloud/releases/latest/download/proxycloud-armeabi-v7a.apk"><img src="https://img.shields.io/badge/Android-armeabi--v7a-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android armeabi-v7a"></a> |
| arm64-v8a   | <a href="https://github.com/code3-dev/ProxyCloud/releases/latest/download/proxycloud-arm64-v8a.apk"><img src="https://img.shields.io/badge/Android-arm64--v8a-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android arm64-v8a"></a> |
| x86_64      | <a href="https://github.com/code3-dev/ProxyCloud/releases/latest/download/proxycloud-x86_64.apk"><img src="https://img.shields.io/badge/Android-x86_64-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android x86_64"></a> |

#### Windows
- [📦 Windows Installer (.exe)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)
- [💼 Windows Portable (.exe)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)

#### macOS
- [🍎 macOS Intel (x64) (.dmg)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)
- [🍎 macOS Apple Silicon (arm64) (.dmg)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)
- [📦 macOS Intel (x64) (.zip)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)
- [📦 macOS Apple Silicon (arm64) (.zip)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)

#### Linux
- [🐧 Linux (.deb)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)
- [🐧 Linux (.rpm)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)
- [🐧 Linux (.AppImage)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)
- [🐧 Linux (.tar.gz)](https://github.com/code3-dev/ProxyCloud-GUI/releases/latest)

#### Arch Linux

ProxyCloud is now on the [AUR](https://aur.archlinux.org/packages/proxycloud-gui-bin), therefore you can install it using your prefered AUR helper.

```bash
paru -S proxycloud-gui-bin

# or if you are using yay

yay -S proxycloud-gui-bin
```

### 开发者指南

#### 前提条件
- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Android设备或模拟器

### 构建步骤

1. 克隆仓库：
   ```bash
   git clone https://github.com/code3-dev/ProxyCloud.git
   cd ProxyCloud
   ```

2. 安装依赖：
   ```bash
   flutter pub get
   ```

3. 在调试模式下运行应用：
   ```bash
   flutter run
   ```

4. 构建发布版APK：
   ```bash
   flutter build apk
   ```

## 📖 使用指南

### 设置V2Ray
1. 导航到VPN选项卡（主屏幕）
2. 点击"添加订阅"输入您的订阅URL和名称
3. 等待服务器从您的订阅加载
4. 从列表中选择一个服务器
5. 点击大的连接按钮建立VPN连接

### 管理订阅
1. 转到工具选项卡
2. 选择"订阅管理器"
3. 在这里您可以添加新订阅、编辑现有订阅或删除不需要的订阅
4. 使用刷新按钮一次性更新所有订阅

### 使用Telegram代理
1. 导航到代理选项卡
2. 浏览可用的MTProto代理列表
3. 点击代理上的"连接"，使用选定的代理配置打开Telegram
4. 或者，点击复制图标复制代理详细信息，以便在Telegram中手动配置

### 探索商店
1. 转到商店选项卡
2. 浏览精选的V2Ray订阅提供商列表
3. 点击任何项目查看详细信息
4. 使用"添加"按钮快速将订阅添加到您的收藏中

### 使用工具
1. 导航到工具选项卡
2. 从各种实用工具中选择：
   - IP信息：检查您当前的IP地址和位置详细信息
   - 主机检查器：测试与任何网站或服务器的连接
   - 速度测试：测量您的连接速度
   - VPN设置：配置VPN连接的高级选项

## 🤝 贡献

我们欢迎贡献，使代理云变得更好！以下是您可以提供帮助的方式：

1. Fork仓库
2. 创建您的功能分支：`git checkout -b feature/amazing-feature`
3. 提交您的更改：`git commit -m 'Add some amazing feature'`
4. 推送到分支：`git push origin feature/amazing-feature`
5. 打开Pull Request

请阅读[CONTRIBUTING.md](CONTRIBUTING.md)了解我们的行为准则和提交拉取请求的流程详情。

## 📄 许可证

本项目采用MIT许可证 - 详情请参阅[LICENSE](LICENSE)文件。

## 📞 支持

如果您遇到任何问题或有疑问，请在我们的GitHub仓库上开一个issue。

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 用于构建原生编译应用程序的UI工具包
- [Xray Core](https://github.com/XTLS/Xray-core) - 一个用于构建绕过网络限制的代理的平台
- [AndroidLibV2rayLite](https://github.com/2dust/AndroidLibV2rayLite) - Xray核心的Android库
- [Provider](https://pub.dev/packages/provider) - 状态管理解决方案
- 所有帮助塑造这个项目的贡献者

---

<p align="center">
  <b>由Hossein Pira开发</b><br>
  <i>快速、无限制、安全且免费</i>
</p>
