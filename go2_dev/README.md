# Go2 Humble 開發環境

Ubuntu 22.04、ROS 2 Humble 與 Unitree `unitree_ros2` 開發環境。

## 1. 建立本機設定

第一次使用時建立不提交至 Git 的本機設定：

```bash
cp go2_dev/.env.example go2_dev/.env
```

依目前電腦與 Jetson 的網路環境調整 `go2_dev/.env`。`GO2_NETWORK_INTERFACE` 必須是 Humble container 內可見的網路介面；在 Ubuntu host network 環境中，應設定為連接 Jetson 網路的主機介面。

## 2. 網路路由

### macOS

檢查路由：

```bash
route -n get 192.168.123.18
```

`gateway` 應為 `192.168.10.180`。如果路由不正確，執行：

```bash
sudo route -n add -net 192.168.123.0/24 192.168.10.180
```

### Linux

設定路由：

```bash
sudo ip route replace 192.168.123.0/24 via 192.168.10.180
```

## 3. 第一次建立 Docker 環境

```bash
docker compose -f go2_dev/compose.yaml build go2_humble
docker compose -f go2_dev/compose.yaml up -d go2_humble
docker compose -f go2_dev/compose.yaml exec go2_humble bash
```

## 4. 第一次編譯 Unitree workspaces

只有第一次建立環境或相關原始碼更新後需要執行：

```bash
source /opt/ros/humble/setup.bash

cd cyclonedds_ws
colcon build
source /workspace/cyclonedds_ws/install/setup.bash

cd example
colcon build
source /workspace/example/install/setup.bash
```

## 5. 一般啟動與使用

```bash
docker compose -f go2_dev/compose.yaml up -d go2_humble
docker compose -f go2_dev/compose.yaml exec go2_humble bash
```

進入 container 後載入環境：

```bash
source /opt/ros/humble/setup.bash
source cyclonedds_ws/install/setup.bash
source example/install/setup.bash
```

## 6. 停止環境

```bash
docker compose -f go2_dev/compose.yaml down
```
