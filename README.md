# ROS2 Docker

這是一個基於 ROS2 Jazzy 的 Docker 開發環境，採用分層架構設計，支援 VNC 遠端桌面和 SSH 連線。

## 專案架構

本專案採用兩層 Image 架構，將基礎環境與應用環境分離：

### ROS2 Base Image (jazzy/)

基礎桌面環境，包含 ROS2 Jazzy 與遠端開發工具：

- 作業系統: Ubuntu 24.04 (Noble)
- ROS2: Jazzy Desktop + Gazebo
- ROS Bridge: rosbridge_suite
- 桌面環境: MATE Desktop
- 遠端存取: VNC Server (TigerVNC) + noVNC Web 介面 + SSH Server
- 開發工具: Firefox、VSCodium、Terminator

Image 名稱: `ros2-desktop-vnc:jazzy`

---

### Industrial Robot Image (industrial_robot/)

工業機器人開發環境，以 ros2-desktop-vnc:jazzy 為基礎，加入機器人控制相關套件（支援 KUKA、ABB、FANUC、UR 等）：

核心套件:
- 控制框架: ros2-control, ros2-controllers
- 運動規劃: MoveIt2, OMPL
- 模擬整合: Gazebo (ros-gz), gz-ros2-control
- 視覺化: RViz2, RQt, PlotJuggler
- 運動學: KDL, urdf-parser, xacro
- Python 工具: transforms3d, ikpy, numpy, scipy, matplotlib

預建 Workspace: 容器內已建立標準 colcon workspace 結構 (`src/`, `build/`, `install/`, `log/`)

Image 名稱: `ros2-industrial-robot:jazzy`

---

## 快速開始

### docker build

```bash
cd jazzy && docker build -t ros2-desktop-vnc:jazzy .
```

```bash
cd industrial_robot && docker build -t ros2-industrial-robot:jazzy .
```

### docker-compose up

```bash
cd rccn_kuka_dev && docker-compose up -d
```

### 建立個別專案

```bash
# 複製範本
cp -r rccn_kuka_dev my_project_name

# 編輯 docker-compose.yml，修改以下項目：
# - container_name
# - ports (VNC & SSH)
# - volume name
```


### 容器相關指令
```bash
docker-compose up -d # 啟動容器
docker-compose ps # 查看容器狀態
docker logs <container_name> # 查看日誌
docker-compose down # 停止容器
docker exec -it <container_name> bash # 進入容器
```

### Volume 管理
```bash
docker volume ls # 列出所有 Volumes
docker volume inspect <volume_name> # 檢視 Volume 內容
docker volume rm <volume_name> # 刪除 Volume（資料會永久消失）
```

---

## 許可證

見 [LICENSE](LICENSE)
