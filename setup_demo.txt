#!/bin/bash

# Скрипт первоначальной настройки сервера для деплоя Go приложения
# Запускать под root или с sudo

set -e

echo "🚀 Начинаем настройку сервера..."

# Обновляем систему
echo "📦 Обновляем систему..."
apt update && apt upgrade -y

# Устанавливаем необходимые пакеты
echo "🔧 Устанавливаем необходимые пакеты..."
apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    htop \
    nano \
    vim

# Устанавливаем Docker
echo "🐳 Устанавливаем Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Устанавливаем Docker Compose (standalone)
echo "🐙 Устанавливаем Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Создаем пользователя для деплоя (если не существует)
USERNAME="deployer"
if ! id "$USERNAME" &>/dev/null; then
    echo "👤 Создаем пользователя $USERNAME..."
    useradd -m -s /bin/bash $USERNAME
    usermod -aG docker $USERNAME
    usermod -aG sudo $USERNAME
    
    # Настраиваем SSH для пользователя
    mkdir -p /home/$USERNAME/.ssh
    chmod 700 /home/$USERNAME/.ssh
    touch /home/$USERNAME/.ssh/authorized_keys
    chmod 600 /home/$USERNAME/.ssh/authorized_keys
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
    
    echo "⚠️  Добавьте ваш публичный SSH ключ в /home/$USERNAME/.ssh/authorized_keys"
else
    echo "👤 Пользователь $USERNAME уже существует"
fi

# Настраиваем UFW (firewall)
echo "🔥 Настраиваем firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Настраиваем fail2ban
echo "🛡️  Настраиваем fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
mta = sendmail
protocol = tcp
chain = INPUT
port = 0:65535
fail2ban_agent = Fail2Ban/%(fail2ban_version)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 1h

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6
bantime = 1h

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 1h
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# Настраиваем автоматические обновления безопасности
echo "🔄 Настраиваем автоматические обновления безопасности..."
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Настраиваем SSH (более безопасно)
echo "🔐 Настраиваем SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
cat > /etc/ssh/sshd_config << 'EOF'
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin no
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication no
X11Forwarding no
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
MaxStartups 10:30:60
Banner /etc/issue.net
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes
AllowUsers deployer
EOF

# Создаем директорию для проекта
echo "📁 Создаем директорию для проекта..."
mkdir -p /home/$USERNAME/my-go-app
chown -R $USERNAME:$USERNAME /home/$USERNAME/my-go-app

# Создаем systemd сервис для автозапуска Docker Compose
echo "🔧 Создаем systemd сервис..."
cat > /etc/systemd/system/my-go-app.service << EOF
[Unit]
Description=My Go App
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$USERNAME
Group=$USERNAME
WorkingDirectory=/home/$USERNAME/my-go-app
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable my-go-app

# Устанавливаем Caddy для автоматического HTTPS (опционально)
echo "🌐 Устанавливаем Caddy для HTTPS..."
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install -y caddy

# Создаем базовый Caddyfile
cat > /etc/caddy/Caddyfile << 'EOF'
# Замените your-domain.com на ваш домен
:80 {
    reverse_proxy localhost:80
}

# Для домена с HTTPS:
# your-domain.com {
#     reverse_proxy localhost:80
# }
EOF

systemctl enable caddy
systemctl restart caddy

# Создаем скрипт для мониторинга
echo "📊 Создаем скрипт для мониторинга..."
cat > /home/$USERNAME/monitor.sh << 'EOF'
#!/bin/bash

echo "=== System Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo ""

echo "=== Docker Status ==="
docker-compose ps 2>/dev/null || echo "Docker Compose not running"
echo ""

echo "=== Disk Usage ==="
df -h
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Application Health ==="
curl -s http://localhost/api/v1/health | jq . 2>/dev/null || curl -s http://localhost/api/v1/health || echo "Health check failed"
echo ""

echo "=== Recent Logs ==="
docker-compose logs --tail=10 2>/dev/null || echo "No logs available"
EOF

chmod +x /home/$USERNAME/monitor.sh
chown $USERNAME:$USERNAME /home/$USERNAME/monitor.sh

echo "✅ Настройка сервера завершена!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Добавьте ваш публичный SSH ключ в /home/$USERNAME/.ssh/authorized_keys"
echo "2. Перезапустите SSH: systemctl restart ssh"
echo "3. Клонируйте ваш проект в /home/$USERNAME/my-go-app"
echo "4. Настройте GitHub Secrets:"
echo "   - HOST: IP адрес сервера"
echo "   - USERNAME: $USERNAME"
echo "   - SSH_PRIVATE_KEY: приватный SSH ключ"
echo "5. Если используете домен, обновите Caddyfile"
echo ""
echo "🔍 Для мониторинга используйте: /home/$USERNAME/monitor.sh"
echo "📊 Логи: docker-compose logs -f"
echo "🔄 Перезапуск: docker-compose restart"