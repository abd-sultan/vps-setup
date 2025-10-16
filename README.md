# 🚀 Ubuntu Full Performance Server Setup

## 🧩 Contenu installé
- NGINX (optimisé + Certbot HTTPS)
- Docker + Docker Compose
- Node.js 20 + PM2 + pnpm + yarn
- Java 17 + Maven
- Python 3 + pip + venv
- PostgreSQL (port 55432)
- MySQL (port 3307)
- MongoDB (port 27018)
- pgAdmin4 Web + HTTPS
- Netdata + Glances
- GitHub CLI + GitLab Runner
- Zsh + Oh My Zsh (autosuggestions, syntax highlighting, Powerlevel10k)

---

## 🔐 Connexion SSH
1. Crée ta clé SSH locale :
   ```bash
   ssh-keygen -t ed25519 -C "ton@email.com"

2. Copie la clé publique dans ton VPS :

   ```bash
   ssh-copy-id -p 2222 admin@<IP_SERVEUR>
   ```
3. Connecte-toi :

   ```bash
   ssh -p 2222 admin@<IP_SERVEUR>
   ```

---

## 🌐 Accès pgAdmin4

* URL : `https://pgadmin.mondomaine.com`
* SSL activé via Let's Encrypt
* Mot de passe configuré à la première installation

---

## 🍃 Connexion MongoDB Compass

Dans MongoDB Compass :

```
mongodb://<ip_serveur>:27018
```

⚠️ Vérifie que le port 27018 est ouvert dans le pare-feu :

```bash
sudo ufw allow 27018/tcp
```

---

## 📊 Monitoring

* **Netdata (Web)** : http://<ip_serveur>:19999
* **Glances (CLI)** : `glances`

---

## 🧠 Utilisation Docker

```bash
sudo systemctl start docker
docker ps
docker compose up -d
```

---

## 💀 Personnalisation Zsh

Zsh est déjà installé avec :

* Thème : Powerlevel10k
* Plugins : git, docker, node, z, autosuggestions, syntax-highlighting

Pour activer la configuration :

```bash
exec zsh
```

---

## ⚙️ Déploiement

Tu peux déployer via :

* GitHub Actions
* GitLab Runner
* PM2 (`pm2 deploy`)
* ou Rsync (`rsync -avz --progress ./dist admin@ip:/var/www/app`)

---

## 🕒 Fuseau horaire

Défini sur `Africa/Dakar`

---

## 🧾 Licences

Script libre sous licence MIT.
