# 繼承 ros2-desktop-vnc:jazzy 建立工業機器人開發環境
ARG BASE_IMAGE=ros2-desktop-vnc:jazzy
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-c"]

# 切換回 root 安裝套件
USER root

# 安裝工業機器人開發套件 (支援 KUKA, ABB, FANUC, UR 等)
RUN apt-get update -q && \
    apt-get install -y \
    # ========== 核心控制 ==========
    ros-${ROS_DISTRO}-ros2-control \
    ros-${ROS_DISTRO}-ros2-controllers \
    ros-${ROS_DISTRO}-control-toolbox \
    ros-${ROS_DISTRO}-realtime-tools \
    ros-${ROS_DISTRO}-controller-manager \
    ros-${ROS_DISTRO}-joint-state-broadcaster \
    ros-${ROS_DISTRO}-joint-trajectory-controller \

    # ========== 運動規劃 ==========
    ros-${ROS_DISTRO}-moveit \
    ros-${ROS_DISTRO}-moveit-planners-ompl \
    ros-${ROS_DISTRO}-moveit-ros-visualization \
    ros-${ROS_DISTRO}-moveit-servo \
    ros-${ROS_DISTRO}-moveit-simple-controller-manager \

    # ========== 模擬環境 (jazzy 已含 ros-gz，僅保留 gz bridge) ==========
    ros-${ROS_DISTRO}-gz-ros2-control \

    # ========== 視覺化與除錯 ==========
    ros-${ROS_DISTRO}-rviz2 \
    ros-${ROS_DISTRO}-rqt \
    ros-${ROS_DISTRO}-rqt-common-plugins \
    ros-${ROS_DISTRO}-plotjuggler-ros \

    # ========== 運動學與機器人描述 ==========
    ros-${ROS_DISTRO}-xacro \
    ros-${ROS_DISTRO}-kdl-parser \
    ros-${ROS_DISTRO}-robot-state-publisher \
    ros-${ROS_DISTRO}-joint-state-publisher \
    ros-${ROS_DISTRO}-joint-state-publisher-gui \

    # ========== 開發工具 ==========
    python3-pytest \
    clang-format \
    clang-tidy \
    htop \
    net-tools \
    iputils-ping && \
    rm -rf /var/lib/apt/lists/*

# 安裝額外的 Python 工具 (透過 pip)
RUN pip3 install --no-cache-dir --break-system-packages \
    transforms3d \
    numpy \
    scipy \
    matplotlib \
    ikpy

# 建立完整的 ROS2 colcon workspace 結構
RUN mkdir -p /home/ubuntu/workspace/src && \
    mkdir -p /home/ubuntu/workspace/build && \
    mkdir -p /home/ubuntu/workspace/install && \
    mkdir -p /home/ubuntu/workspace/log && \
    # 建立 .gitignore
    echo "build/\ninstall/\nlog/\n__pycache__/\n*.pyc" > /home/ubuntu/workspace/.gitignore && \
    # 建立環境設置腳本
    echo '#!/bin/bash\nsource /opt/ros/$ROS_DISTRO/setup.bash\n[ -f install/setup.bash ] && source install/setup.bash' > /home/ubuntu/workspace/setup_ws.sh && \
    chmod +x /home/ubuntu/workspace/setup_ws.sh && \
    chown -R ubuntu:ubuntu /home/ubuntu/workspace

# 設定額外的 ROS 環境變數
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /home/ubuntu/.bashrc

# 切換回 ubuntu 使用者
USER ubuntu
WORKDIR /home/ubuntu/workspace
