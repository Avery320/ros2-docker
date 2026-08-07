# Go2 開發環境規格與流程

本文件定義 Unitree Go2 在本 repository 中的開發架構、責任邊界與分階段驗收流程。實作時應先完成每一階段的驗收，再進入下一階段，避免同時除錯 Docker、實體網路、DDS、Zenoh 與視覺化。

## 1. 開發目標

本專案需要同時保留兩個 ROS 2 環境：

- 主機環境：macOS，使用 Docker 管理所有 containers。
- ROS 2 Humble：依照 Unitree 官方方法，使用 CycloneDDS 與 Go2 實體機器人直接通訊。
- ROS 2 Jazzy：沿用現有 `ros2-desktop-vnc:jazzy` image，提供 RViz2、VNC 桌面與後續 Jazzy 應用開發。
- Humble 與 Jazzy：使用 `zenoh-bridge-ros2dds` 連接兩側的 DDS 網路。
- Web 應用：視需求在 Jazzy desktop 內手動啟動 rosbridge 或 Foxglove Bridge。

目標資料流如下：

```text
Go2
  ↕ CycloneDDS（Unitree 官方方式）
go2_humble / unitree_ros2
  ↕ Humble 本地 DDS
zenoh_humble
  ↕ Zenoh TCP
zenoh_jazzy
  ↕ Jazzy 本地 DDS
jazzy_desktop
  ├── RViz2
  ├── rosbridge（選用、手動啟動）
  └── Foxglove Bridge（選用、手動啟動）
```

## 2. 核心設計規格

### 2.1 Unitree ROS 2 程式碼

Humble 環境以完整的 Unitree 官方 repository 為開發基礎：

- Repository：<https://github.com/unitreerobotics/unitree_ros2>
- 本地位置：`go2_dev/unitree_ros2/`
- 管理方式：Git submodule
- Dockerfile：直接使用官方 `.devcontainer/Dockerfile-humble`

本地 repository 可依專案需求調整版本與環境設定，目前統一使用 ROS 2 Humble。下列介面與通訊規格維持 Unitree 定義：

- `unitree_go` 訊息
- `unitree_api` 訊息
- Unitree 與 Go2 之間的 CycloneDDS 通訊方式

目前使用的 Unitree commit 為 `668d1ec5a05d1c38d3306bdca7d59f2ba3581a88`。上游版本只在需要時人工評估，不在 container 啟動或 build 時自動更新。

### 2.2 Source、build 與執行的關係

取得官方原始碼不等於 ROS 2 已經能執行套件：

```text
git clone / Git submodule
        ↓
取得官方原始碼
        ↓
colcon build
        ↓
產生 ROS 2 interfaces 與 executables
        ↓
source install/setup.bash
        ↓
ROS 2 可以尋找並使用建構結果
```

官方 repository 目前沒有 ROS 2 launch files。官方 README 主要直接執行 build 後的 executable，例如：

```bash
/workspace/example/install/unitree_ros2_example/bin/read_motion_state
```

因此，第一階段不把 `ros2 launch` 當作官方環境的驗收條件。如果未來需要統一的 launch 管理，應另外建立我們自己的 `go2_bringup` package，不修改 `unitree_ros2`。

### 2.3 Middleware 邊界

- Go2 與 Humble：`rmw_cyclonedds_cpp`
- Jazzy 本地 ROS graph：`rmw_cyclonedds_cpp`
- Humble 與 Jazzy：兩個 `zenoh-bridge-ros2dds` instance
- 不使用 `rmw_zenoh_cpp` 連接 Humble 與 Jazzy
- 不使用 `domain_bridge`
- Zenoh 不轉換或修改 Unitree 自訂訊息格式

`zenoh-bridge-ros2dds` 建議直接使用 Eclipse Zenoh 官方 image，並固定經過測試的版本或 image digest。Zenoh bridge 不安裝進 Unitree 官方 Dockerfile。

### 2.4 Jazzy desktop 與 Web bridge

現有 `jazzy/Dockerfile` 繼續作為 Jazzy desktop 的來源。預計包含：

- `ros-jazzy-desktop`
- `ros-jazzy-rmw-cyclonedds-cpp`
- `ros-jazzy-rosbridge-suite`
- `ros-jazzy-foxglove-bridge`

rosbridge 與 Foxglove Bridge 不需要隨 Compose 自動啟動。開發者可以透過 VNC 進入 Jazzy desktop，再從 terminal 手動選擇啟動：

```bash
ros2 launch rosbridge_server rosbridge_websocket_launch.xml
```

或：

```bash
ros2 launch foxglove_bridge foxglove_bridge_launch.xml
```

即使 node 是手動啟動，Jazzy service 仍需在 container 建立時預先發布所需 ports：

- `9090`：rosbridge WebSocket
- `8765`：Foxglove WebSocket

## 3. 預定目錄結構

```text
ros2-docker/
├── jazzy/
│   ├── Dockerfile
│   └── entrypoint.sh
│
└── go2_dev/
    ├── unitree_ros2/              # Unitree 官方 Git submodule
    │   ├── .devcontainer/
    │   │   └── Dockerfile-humble  # 直接使用官方 Dockerfile
    │   ├── cyclonedds_ws/
    │   └── example/
    ├── config/
    │   ├── cyclonedds/
    │   │   └── go2_humble.xml
    │   └── zenoh/
    │       ├── humble.json5
    │       └── jazzy.json5
    └── compose.yaml
```

本專案目前以 macOS 上的 Docker 環境進行開發。OrbStack 是目前使用的 Docker runtime，不是專案架構的一部分。

## 4. 分階段開發流程

### 階段一：建立官方 Humble Docker 環境

狀態：**已完成**

目的：只確認官方 Dockerfile、官方 source 與 ROS 2 build 能正常運作，不處理 Go2 實體網路。

工作項目：

- [x] 建立 `go2_dev/`。
- [x] 將官方 `unitree_ros2` 加入為 Git submodule。
- [x] 建立 `go2_dev/compose.yaml`。
- [x] Compose 使用 `unitree_ros2/.devcontainer/Dockerfile-humble`。
- [x] 將完整 `unitree_ros2` 掛載到 `/workspace`。
- [x] 建立並啟動 Humble container。

驗收條件：

- 官方 Humble image 可以成功 build。
- Humble container 可以正常啟動並進入 shell。
- `/workspace/cyclonedds_ws` 與 `/workspace/example` 都是完整官方程式碼。
- `rmw_cyclonedds_cpp` 與 `rosidl_generator_dds_idl` 已安裝。

本階段不要求看到 Go2 topics。

### 階段二：建構 Unitree ROS 2 workspaces

狀態：**已完成**

目的：依照官方 workspace 關係完成 interfaces 與 examples 的建構。

參考建構順序：

```bash
source /opt/ros/humble/setup.bash

cd /workspace/cyclonedds_ws
colcon build
source /workspace/cyclonedds_ws/install/setup.bash

cd /workspace/example
colcon build
source /workspace/example/install/setup.bash
```

根目錄 `setup.sh` 的 ROS 2 環境已由 Foxy 改為 Humble。Workspace 建構明確 source `/opt/ros/humble/setup.bash` 與上述 workspace setup files。

驗收條件：

```bash
ros2 interface show unitree_go/msg/SportModeState
ros2 interface show unitree_go/msg/LowState
```

兩個指令都能顯示官方訊息定義，且下列唯讀 example executable 存在：

```text
/workspace/example/install/unitree_ros2_example/bin/read_motion_state
```

目前保留人工執行 build 流程。第一次建立環境或相關原始碼更新後才需要重新執行 `colcon build`。

### 階段三：設定 macOS、Docker 與 Go2 網路

狀態：**進行中**

目的：完成 Go2 與 Humble 的官方 CycloneDDS 連線。

目前的網路設定：

```text
macOS en0：192.168.10.32
Go2 gateway：192.168.10.180
Go2 內部網路：192.168.123.0/24
```

Go2 gateway 負責轉送公司測試網段與 Unitree 原廠內部網路。macOS 使用下列路由存取 Go2 內部服務：

```text
192.168.123.0/24 via 192.168.10.180
```

目前已確認 `192.168.123.18` 的 gateway 為 `192.168.10.180`。

只有 `go2_humble` container 直接與 Go2 通訊；`jazzy_desktop` 不加入 Go2 的 DDS 網路。

`go2_humble` 使用 Unitree 官方 Compose 相同的容器網路設定：

```yaml
privileged: true
network_mode: host
```

CycloneDDS 使用 `go2_dev/.env` 指定的 container 網路介面，並設定：

```text
NetworkInterface：${GO2_NETWORK_INTERFACE}
ExternalNetworkAddress：${GO2_DDS_EXTERNAL_ADDRESS}
Discovery peer：${GO2_DDS_PEER_ADDRESS}
ROS domain：0
```

各電腦的實際值由不提交至 Git 的 `go2_dev/.env` 提供；repository 只保留 `go2_dev/.env.example` 作為設定範例。

Humble runtime 設定：

```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI=file:///config/cyclonedds/go2_humble.xml
```

`go2_dev/config/cyclonedds/go2_humble.xml` 管理網路介面、外部位址與 discovery peer，不修改 Unitree 的訊息或通訊協定。

已完成的驗證：

```bash
ros2 topic list -t
ros2 topic echo /livox/imu --once
```

目前 Humble 可發現：

```text
/livox/imu   [sensor_msgs/msg/Imu]
/livox/lidar [livox_ros_driver2/msg/CustomMsg]
```

階段三尚未完成的驗收項目：

- [ ] 發現 `/sportmodestate` 或 `/lf/sportmodestate`。
- [ ] 發現 `/lowstate` 或 `/lf/lowstate`。
- [ ] 官方 `read_motion_state` 可持續收到資料。

本階段不得執行 `low_level_ctrl`、`go2_sport_client`、`go2_stand_example` 等控制程式。

### 階段四：加入 Jazzy 與 Zenoh

狀態：**尚未開始**

前提：階段三已穩定看到 Go2 topics。

工作項目：

1. 啟動 Jazzy desktop，並確認 Jazzy 使用 CycloneDDS。
2. 啟動 Humble 端 `zenoh-bridge-ros2dds`。
3. 啟動 Jazzy 端 `zenoh-bridge-ros2dds`。
4. 隔離 Humble 與 Jazzy DDS，避免直接 DDS 與 Zenoh 產生重複路徑。
5. 第一個 allowlist 只加入 `/utlidar/cloud`。

驗收條件：

- Humble 仍能直接看到 Go2。
- Jazzy 不直接加入 Go2 DDS 網路。
- Jazzy 可以看到經 Zenoh 重建的 `/utlidar/cloud`。
- Jazzy RViz2 可以使用 `utlidar_lidar` 作為 Fixed Frame 顯示點雲。

完成點雲後，才逐步評估 `/tf`、`/tf_static`、`/sportmodestate` 與 `/lowstate`。

### 階段五：Web 應用連線

狀態：**尚未開始**

前提：Jazzy 已能穩定接收需要的 topics。

依 Web 應用協定選擇其中一個：

- rosbridge：適合使用 rosbridge protocol 或 `roslibjs` 的應用。
- Foxglove Bridge：適合使用 Foxglove WebSocket protocol 與較高頻二進位感測資料的應用。

兩者均在 Jazzy desktop terminal 中手動啟動，不參與 Humble 與 Jazzy 的跨 Docker 傳輸。

## 5. 安全與變更規則

- 初期 Zenoh allowlist 只能包含狀態與視覺化 topics。
- 不得橋接 `/lowcmd`、`/api/sport/request` 等控制 topics。
- 不得修改 `unitree_go/msg` 與 `unitree_api/msg`。
- 自訂功能應建立在我們自己的 ROS 2 packages 中。
- 若 Jazzy 需要直接訂閱 Unitree 自訂訊息，必須使用與 Humble 相同 commit 的 interface source 重新編譯。
- Unitree submodule、Zenoh image 與其他外部依賴都必須固定版本。
- 每一階段均保留獨立驗收結果，避免跨層同時除錯。

## 6. 尚未決定的項目

以下項目應在對應階段開始前才確認：

- Zenoh bridge 的固定版本或 image digest。
- Humble 與 Jazzy 的最終 ROS domain IDs。
- Zenoh allowlist 與 QoS 細節。
- 後續 `go2_bringup` package 的需求與範圍。

## 7. 當前實作範圍

目前已完成：

- [x] 建立 `go2_dev` 專案結構。
- [x] 納入完整 `unitree_ros2` repository。
- [x] 使用 `Dockerfile-humble` 建立並啟動 Humble container。
- [x] 建構 `unitree_go`、`unitree_api`、`unitree_hg` 與官方 examples。
- [x] 設定 `192.168.123.0/24` 經由 `192.168.10.180` 的路由。
- [x] Humble 發現 `/livox/imu` 與 `/livox/lidar`。
- [x] Humble 成功讀取 `/livox/imu` 資料。
- [ ] 完成 Go2 核心狀態 topics 與官方唯讀 example 驗證。

目前進行階段三。
