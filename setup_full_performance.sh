#!/bin/bash

set -e

# ==============================================
# 🚀 FULL PERFORMANCE VPS SETUP - Ubuntu 22/24 LTS
# Auteur : Alioune
# ==============================================

NEW_USER="admin"
SSH_PORT="2222"
TIMEZONE="Africa/Dakar"
DOMAIN_PGADMIN="pgadmin.mondomaine.com"   # à remplacer
EMAIL_SSL="admin@mondomaine.com"          # à remplacer

# ==============================================
# 🔧 MISE À JOUR DU SYSTÈME
# ==============================================
echo "🔄 Mise à jour du système..."
apt update && apt upgrade -y
apt install -y curl wget git unzip vim htop net-tools software-properties-common ca-certificates gnupg lsb-release ufw build-essential apt-transport-https

# ==============================================
# 👤 UTILISATEUR + ACCÈS SSH
# ==============================================
echo "👤 Création de l’utilisateur $NEW_USER..."
adduser --disabled-password --gecos "" $NEW_USER
usermod -aG sudo $NEW_USER

mkdir -p /home/$NEW_USER/.ssh
cp ~/.ssh/authorized_keys /home/$NEW_USER/.ssh/authorized_keys
chmod 700 /home/$NEW_USER/.ssh
chmod 600 /home/$NEW_USER/.ssh/authorized_keys
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh

sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
systemctl restart ssh

# ==============================================
# 🔥 FIREWALL
# ==============================================
ufw default deny incoming
ufw default allow outgoing
ufw allow $SSH_PORT/tcp
ufw allow 80,443/tcp
ufw --force enable

# ==============================================
# 🌐 NGINX + CERTBOT
# ==============================================
apt install -y nginx certbot python3-certbot-nginx
systemctl enable nginx && systemctl start nginx

cat <<EOF >/etc/nginx/conf.d/optimizations.conf
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
client_max_body_size 100M;
EOF
nginx -t && systemctl reload nginx

# ==============================================
# 🐳 DOCKER + COMPOSE
# ==============================================
apt remove docker docker-engine docker.io containerd runc -y || true
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker $NEW_USER
systemctl enable docker && systemctl start docker

# ==============================================
# 💻 LANGAGES
# ==============================================
apt install -y openjdk-17-jdk maven python3 python3-pip python3-venv
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install -g pm2 pnpm yarn

# ==============================================
# 💀 ZSH + OH-MY-ZSH
# ==============================================
apt install -y zsh fonts-powerline
chsh -s $(which zsh) $NEW_USER

su - $NEW_USER -c "
  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" --unattended
  git clone https://github.com/zsh-users/zsh-autosuggestions \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
  sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc
  sed -i 's/plugins=(git)/plugins=(git docker node z zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
"

# ==============================================
# 🗄️ BASES DE DONNÉES
# ==============================================
# PostgreSQL
apt install -y postgresql postgresql-contrib
sed -i "s/#port = 5432/port = 55432/" /etc/postgresql/*/main/postgresql.conf
systemctl enable postgresql && systemctl restart postgresql

# MySQL
apt install -y mysql-server
sed -i "s/3306/3307/" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl enable mysql && systemctl restart mysql

# MongoDB
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org.list
apt update && apt install -y mongodb-org
sed -i "s/port: 27017/port: 27018/" /etc/mongod.conf
sed -i "s/bindIp: 127.0.0.1/bindIp: 0.0.0.0/" /etc/mongod.conf  # autoriser MongoDB Compass
systemctl enable mongod && systemctl restart mongod

# ==============================================
# 🧭 PGADMIN4 HTTPS
# ==============================================
apt install -y pgadmin4-web
/usr/pgadmin4/bin/setup-web.sh --yes

# Nginx reverse proxy + HTTPS pour pgAdmin
cat <<EOF >/etc/nginx/sites-available/pgadmin.conf
server {
    listen 80;
    server_name $DOMAIN_PGADMIN;
    location / {
        proxy_pass http://127.0.0.1:5050/;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s /etc/nginx/sites-available/pgadmin.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Certificat SSL
certbot --nginx -d $DOMAIN_PGADMIN --non-interactive --agree-tos -m $EMAIL_SSL

# ==============================================
# 📊 MONITORING
# ==============================================
apt install -y glances
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --non-interactive

# ==============================================
# 🕒 CONFIGURATION FINALE
# ==============================================
timedatectl set-timezone $TIMEZONE
echo "✅ Installation complète terminée !"
