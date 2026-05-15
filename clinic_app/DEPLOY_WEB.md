# Deploy Flutter Web (clinic_app) to Nginx server

This project is a Flutter web build served as static files behind Nginx.

## 0) Build the web bundle (local)

From `clinic_app/`:

```bash
flutter clean
flutter pub get
flutter build web --release
```

Output folder:

- `build/web/`

If you need to host under a subpath (e.g. `/clinic/`), rebuild with:

```bash
flutter build web --release --base-href /clinic/
```

## 1) One-time: set up SSH key auth (recommended)

A deploy key has been generated locally at:

- `~/.ssh/clinic_web_deploy_ed25519`
- `~/.ssh/clinic_web_deploy_ed25519.pub`

Add it to the server (you will be prompted for the root password):

```bash
ssh-copy-id -i ~/.ssh/clinic_web_deploy_ed25519.pub root@31.97.190.216
```

Verify key-based login works:

```bash
ssh -i ~/.ssh/clinic_web_deploy_ed25519 root@31.97.190.216 'echo ok'
```

## 2) Upload the build to the server

Choose a target directory on the server, for example:

- `/var/www/clinic_web`

Upload using `rsync` (fast incremental updates):

```bash
rsync -az --delete -e "ssh -i ~/.ssh/clinic_web_deploy_ed25519" \
  build/web/ root@31.97.190.216:/var/www/clinic_web/
```

## 3) Nginx config (Flutter SPA)

Create an Nginx site file such as:

- `/etc/nginx/sites-available/clinic_web`

Example server block (adjust `server_name` to your hostname):

```nginx
server {
  listen 80;
  server_name YOUR_HOSTNAME_HERE;

  root /var/www/clinic_web;
  index index.html;

  # Flutter web is an SPA; route unknown paths to index.html
  location / {
    try_files $uri $uri/ /index.html;
  }

  # Optional: cache static assets more aggressively
  location ~* \.(?:js|css|png|jpg|jpeg|gif|svg|ico|webp|woff2?)$ {
    expires 7d;
    add_header Cache-Control "public";
    try_files $uri =404;
  }
}
```

Enable and reload:

```bash
ln -sf /etc/nginx/sites-available/clinic_web /etc/nginx/sites-enabled/clinic_web
nginx -t
systemctl reload nginx
```

## 4) Quick check

```bash
curl -I http://YOUR_HOSTNAME_HERE/
```
