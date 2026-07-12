# main-nginx

Репозиторій із конфігурацією Nginx, SSL-сертифікатами та GitHub Actions Runner для VPS.

## Розташування проєкту

Проєкт на VPS розташований за шляхом:

```text
/home/petya/actions-runner/_work/main-nginx/main-nginx
```

Перейти до каталогу проєкту:

```bash
cd /home/petya/actions-runner/_work/main-nginx/main-nginx
```

---

## SSL-сертифікати Let's Encrypt

### Встановлення Certbot

```bash
sudo apt update
sudo apt install certbot
```

Перевірити встановлену версію:

```bash
certbot --version
```

Сертифікати зберігаються в каталозі:

```text
/etc/letsencrypt/live/
```

Сертифікат для `quizpet.mooo.com`:

```text
/etc/letsencrypt/live/quizpet.mooo.com/fullchain.pem
/etc/letsencrypt/live/quizpet.mooo.com/privkey.pem
```

Не потрібно вручну редагувати, замінювати або копіювати файли з `/etc/letsencrypt/live`.

### Для чого потрібна `.well-known/acme-challenge`

Шлях на VPS:

```text
/home/petya/actions-runner/_work/main-nginx/main-nginx/sites/quizpet/.well-known/acme-challenge
```

Цей каталог використовується для підтвердження володіння доменом під час випуску або оновлення SSL-сертифіката через Certbot у режимі `--webroot`.

Під час запуску Certbot:

```bash
sudo certbot certonly \
  --webroot \
  -w /home/petya/actions-runner/_work/main-nginx/main-nginx/sites/quizpet \
  -d quizpet.mooo.com \
  -d www.quizpet.mooo.com
```

Certbot тимчасово створює перевірочний файл усередині каталогу:

```text
sites/quizpet/.well-known/acme-challenge/<token>
```

Після цього Let's Encrypt намагається отримати цей файл через HTTP:

```text
http://quizpet.mooo.com/.well-known/acme-challenge/<token>
```

Якщо файл доступний, Let's Encrypt підтверджує, що сервер керує доменом, і дозволяє випуск або оновлення сертифіката.

У параметрі `-w` потрібно вказувати кореневий каталог webroot:

```text
/home/petya/actions-runner/_work/main-nginx/main-nginx/sites/quizpet
```

Повний шлях до `.well-known/acme-challenge` вказувати не потрібно — Certbot додає його автоматично.

Certbot запускається на VPS, тому під час отримання сертифіката використовується саме серверний шлях.

Локальний каталог потрібен тому, що він зберігається в Git-репозиторії та потрапляє на сервер під час деплою через GitHub Actions.

Каталог `.well-known/acme-challenge` можна залишати порожнім. Під час оновлення сертифіката Certbot самостійно створює в ньому тимчасові challenge-файли.

### Первинне отримання сертифіката

```bash
cd /home/petya/actions-runner/_work/main-nginx/main-nginx

sudo certbot certonly \
  --webroot \
  -w /home/petya/actions-runner/_work/main-nginx/main-nginx/sites/quizpet \
  -d quizpet.mooo.com \
  -d www.quizpet.mooo.com
```

Краще використовувати абсолютний шлях у параметрі `-w`, щоб команда не залежала від поточного каталогу.

Перед запуском потрібно переконатися, що обидва домени доступні через HTTP на порту `80`:

```text
http://quizpet.mooo.com
http://www.quizpet.mooo.com
```

### Перевірка сертифікатів

```bash
sudo certbot certificates
```

Команда показує:

* назву сертифіката;
* перелік доменів;
* строк дії;
* шлях до сертифіката;
* шлях до приватного ключа.

### Тестове оновлення

```bash
sudo certbot renew \
  --cert-name quizpet.mooo.com \
  --dry-run
```

Успішний результат:

```text
Congratulations, all simulated renewals succeeded
```

Параметр `--dry-run` не замінює поточний сертифікат, а лише перевіряє, чи зможе Certbot автоматично його оновити.

### Реальне оновлення

```bash
sudo certbot renew --cert-name quizpet.mooo.com
```

Certbot оновить сертифікат лише тоді, коли наблизиться дата завершення строку його дії.

Якщо сертифікат ще не потрібно оновлювати, буде показано повідомлення:

```text
Certificate not yet due for renewal
```

Це нормальна поведінка.

Примусове оновлення:

```bash
sudo certbot renew \
  --cert-name quizpet.mooo.com \
  --force-renewal
```

Параметр `--force-renewal` слід використовувати лише за необхідності.

### Перевірка автоматичного оновлення

Перевірити наявність системного таймера Certbot:

```bash
systemctl list-timers --all | grep certbot
```

Перевірити стан таймера:

```bash
systemctl status certbot.timer
```

Перевірити, чи ввімкнений таймер:

```bash
systemctl is-enabled certbot.timer
```

### Видалення невикористовуваного сертифіката

Наприклад, якщо сайт `yt-music.mooo.com` більше не працює:

```bash
sudo certbot delete --cert-name yt-music.mooo.com
```

Після видалення повторно перевірити оновлення:

```bash
sudo certbot renew --dry-run
```

Не рекомендується видаляти сертифікати вручну з каталогу `/etc/letsencrypt/live`.

---

## Перезапуск Nginx

### Nginx у Docker

Переглянути запущені контейнери:

```bash
docker ps
```

Переглянути також зупинені контейнери:

```bash
docker ps -a
```

Перезапустити контейнер за ID:

```bash
docker restart <container_id>
```

Приклад:

```bash
docker restart a1b2c3d4e5f6
```

Можна використовувати скорочений ID, якщо він унікальний:

```bash
docker restart a1b2c3
```

Перезапустити контейнер із тайм-аутом 10 секунд:

```bash
docker restart -t 10 <container_id>
```

Перезапустити Nginx через Docker Compose:

```bash
cd /home/petya/actions-runner/_work/main-nginx/main-nginx
docker compose restart nginx
```

Перечитати конфігурацію Nginx без повного перезапуску контейнера:

```bash
docker compose exec nginx nginx -s reload
```

Перевірити конфігурацію всередині контейнера:

```bash
docker compose exec nginx nginx -t
```

Рекомендована послідовність:

```bash
docker compose exec nginx nginx -t &&
docker compose exec nginx nginx -s reload
```

Якщо команда виконується в CI або без інтерактивного термінала:

```bash
docker compose exec -T nginx nginx -t &&
docker compose exec -T nginx nginx -s reload
```

Переглянути логи контейнера:

```bash
docker compose logs nginx
```

Стежити за логами в реальному часі:

```bash
docker compose logs -f nginx
```

### Nginx як системний сервіс

Якщо Nginx встановлений безпосередньо на VPS:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Перевірити стан:

```bash
sudo systemctl status nginx
```

Переглянути логи:

```bash
sudo journalctl -u nginx -n 100 --no-pager
```

---

## GitHub Actions Runner

Файл systemd-сервісу:

```text
/etc/systemd/system/github-runner.service
```

Відкрити файл:

```bash
sudo nano /etc/systemd/system/github-runner.service
```

Конфігурація:

```ini
[Unit]
Description=GitHub Actions Runner
After=network.target

[Service]
Type=simple
User=petya
WorkingDirectory=/home/petya/actions-runner
ExecStart=/home/petya/actions-runner/run.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Сервіс:

* запускає GitHub Actions Runner;
* працює від користувача `petya`;
* використовує каталог `/home/petya/actions-runner`;
* запускається через `run.sh`;
* автоматично перезапускається після збою;
* очікує 10 секунд перед повторним запуском;
* може автоматично запускатися разом із системою.

Сам сервіс не є cron-задачею. Він постійно працює та очікує завдання від GitHub Actions.

### Застосування змін

Після редагування файлу:

```bash
sudo systemctl daemon-reload
sudo systemctl restart github-runner.service
```

### Перевірка стану

```bash
sudo systemctl status github-runner.service
```

### Перегляд логів

```bash
sudo journalctl \
  -u github-runner.service \
  -n 100 \
  --no-pager
```

Стежити за логами в реальному часі:

```bash
sudo journalctl -u github-runner.service -f
```

### Автозапуск

Увімкнути автозапуск:

```bash
sudo systemctl enable github-runner.service
```

Перевірити автозапуск:

```bash
sudo systemctl is-enabled github-runner.service
```

Вимкнути автозапуск:

```bash
sudo systemctl disable github-runner.service
```

---

## HTTP/3

Матеріали:

* Cloudflare:
  https://blog.cloudflare.com/experiment-with-http-3-using-nginx-and-quiche/

* quiche:
  https://github.com/cloudflare/quiche

Перевірка підтримки HTTP/3:

```text
https://http3check.net/
```

Перевірити через `curl`:

```bash
curl -I --http3 https://quizpet.mooo.com
```

Для виконання цієї команди встановлена версія `curl` повинна підтримувати HTTP/3.

Перевірити версію та доступні можливості:

```bash
curl --version
```

---

## Швидка перевірка після змін

Перейти до каталогу проєкту:

```bash
cd /home/petya/actions-runner/_work/main-nginx/main-nginx
```

Перевірити сертифікати:

```bash
sudo certbot certificates
```

Перевірити можливість автоматичного оновлення:

```bash
sudo certbot renew \
  --cert-name quizpet.mooo.com \
  --dry-run
```

Перевірити конфігурацію Nginx:

```bash
docker compose exec nginx nginx -t
```

Перечитати конфігурацію:

```bash
docker compose exec nginx nginx -s reload
```

Або повністю перезапустити контейнер:

```bash
docker compose restart nginx
```

Перевірити контейнери:

```bash
docker ps
```

Перевірити HTTPS:

```bash
curl -I https://quizpet.mooo.com
```

Перевірити HTTP:

```bash
curl -I http://quizpet.mooo.com
```

Перевірити HTTP/3:

```bash
curl -I --http3 https://quizpet.mooo.com
```
