#!/bin/bash

# Helper function to create desktop entries
create_desktop_entry() {
    local filename="$1"
    local content="$2"
    cat << EOF > "$HOME/Desktop/$filename"
$content
EOF
}

# Create User
USER=${USER:-root}
HOME=/root
if [ "$USER" != "root" ]; then
    echo "* enable custom user: $USER"
    useradd --create-home --shell /bin/bash --user-group --groups adm,sudo "$USER"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    PASSWORD=${PASSWORD:-ubuntu}
    [ -z "$PASSWORD" ] && echo "  set default password to \"ubuntu\""
    HOME="/home/$USER"
    echo "$USER:$PASSWORD" | /usr/sbin/chpasswd 2>/dev/null || true
    cp -r /root/{.config,.gtkrc-2.0,.asoundrc} "$HOME" 2>/dev/null
    [ -d "/dev/snd" ] && chgrp -R adm /dev/snd
fi

# VNC password
VNC_PASSWORD=${PASSWORD:-ubuntu}
mkdir -p "$HOME/.vnc"
echo "$VNC_PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
sed -i "s/password = WebUtil.getConfigVar('password');/password = '$VNC_PASSWORD'/" /usr/lib/novnc/app/ui.js

# xstartup
cat << 'EOF' > "$HOME/.vnc/xstartup"
#!/bin/sh
unset DBUS_SESSION_BUS_ADDRESS
mate-session
EOF
chmod 755 "$HOME/.vnc/xstartup"

# vncserver launch
cat << 'EOF' > "$HOME/.vnc/vnc_run.sh"
#!/bin/sh
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null
if [ $(uname -m) = "aarch64" ]; then
    LD_PRELOAD=/lib/aarch64-linux-gnu/libgcc_s.so.1 vncserver :1 -fg -geometry 1920x1080 -depth 24
else
    vncserver :1 -fg -geometry 1920x1080 -depth 24
fi
EOF

# Supervisor
cat << EOF > /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root
[program:vnc]
command=gosu '$USER' bash '$HOME/.vnc/vnc_run.sh'
[program:novnc]
command=gosu '$USER' bash -c "websockify --web=/usr/lib/novnc 80 localhost:5901"
[program:ssh]
command=/usr/sbin/sshd -D
EOF

# ROS environment setup
cat << EOF >> "$HOME/.bashrc"
source /opt/ros/$ROS_DISTRO/setup.bash
# export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
EOF

# Fix rosdep permission
mkdir -p "$HOME/.ros"
cp -r /root/.ros/rosdep "$HOME/.ros/" 2>/dev/null || true

# Desktop shortcuts
mkdir -p "$HOME/Desktop"

create_desktop_entry "terminator.desktop" "[Desktop Entry]
Name=Terminator
Comment=Multiple terminals in one window
Exec=terminator
Icon=terminator
Type=Application
Categories=GNOME;GTK;Utility;TerminalEmulator;System;
Keywords=terminal;shell;prompt;command;commandline;"

create_desktop_entry "firefox.desktop" "[Desktop Entry]
Version=1.0
Name=Firefox Web Browser
Comment=Browse the World Wide Web
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer
Exec=firefox %u
Terminal=false
Type=Application
Icon=firefox
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=Open a New Window
Exec=firefox -new-window

[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=firefox -private-window"

create_desktop_entry "codium.desktop" "[Desktop Entry]
Name=VSCodium
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/usr/share/codium/codium --unity-launch %F
Icon=vscodium
Type=Application
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-codium-workspace;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=/usr/share/codium/codium --new-window %F"

# Set ownership for all user files
chown -R "$USER:$USER" "$HOME"

echo "============================================================================================"
echo "Launched docker container."
echo -e 'Open \e]8;;http://127.0.0.1:6080\e\\http://127.0.0.1:6080\e]8;;\e\\ via web browser.'
echo ""
echo "NOTE 1: Default user is \"$USER\", password is \"$PASSWORD\"."
echo "NOTE 2: --security-opt seccomp=unconfined flag is required to launch Ubuntu Jammy/Noble based image."
echo "============================================================================================"

# Cleanup sensitive data
PASSWORD=
VNC_PASSWORD=

exec /bin/tini -- supervisord -n -c /etc/supervisor/supervisord.conf
