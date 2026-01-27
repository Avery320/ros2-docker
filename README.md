# ROS2 Docker

這是一個基於 ROS2 Jazzy 的 Docker 開發環境，採用分層架構設計，支援 VNC 遠端桌面和 SSH 連線。

## 專案架構

本專案採用兩層 Image 架構，將基礎環境與應用環境分離：

### ROS2 Base Image (jazzy/)

基礎桌面環境，包含 ROS2 Jazzy 與遠端開發工具，內容：
- Ubuntu 24.04 (Noble)
- ROS2 Jazzy Desktop
- MATE 桌面環境
- VNC Server (TigerVNC)
- noVNC Web 介面
- SSH Server
- 開發工具：Firefox、VSCodium、Terminator
- Gazebo 模擬器

### ROS2 Industrial Robot Image (industrial_robot/)

工業機器人開發環境，繼承 Base Image 並加入機器人控制相關套件。

內容：
- ros2-control 與 ros2-controllers
- MoveIt2 運動規劃框架
- Gazebo 機器人模擬整合
- RViz2、RQt 視覺化工具
- 運動學與機器人描述工具
- Python 工具：transforms3d、ikpy、numpy、scipy
- 工作空間初始化腳本


## 使用方式

### 建置 Image

依序建置兩層 Image：

```bash
# ros2-desktop-vnc: jazzy
cd jazzy && docker build -t ros2-desktop-vnc:jazzy .
```

```bash
# ros2-industrial-robot: industrial_robot
cd ../industrial_robot && docker build -t ros2-industrial-robot:jazzy .
```

### 啟動容器


預設帳號密碼：
- 使用者名稱：ubuntu
- 密碼：ubuntu

### 初始化工作空間

進入容器後，執行初始化腳本建立 ROS2 workspace：

```bash
cd ~/workspace
bash /home/ubuntu/workspace/../init_workspace.sh
```

## 許可證

見 [LICENSE](LICENSE)
