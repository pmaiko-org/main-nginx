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

## Моніторинг: Netdata та Portainer

Обидва сервіси описані в `docker-compose.yaml`, працюють у мережі `shared_network` і **не публікують жодного порту назовні**. Єдиний шлях до них — через Nginx:

```text
https://quizpet.mooo.com/netdata/     — дашборд Netdata (під basic-auth)
https://quizpet.mooo.com/portainer/   — Portainer (власна авторизація)
```

Location-блоки лежать у `snippets/monitoring.conf` і підключаються одним рядком усередині HTTPS-сервера в `sites-enabled/quizpet.conf`:

```nginx
include /etc/nginx/snippets/monitoring.conf;
```

Щоб перенести моніторинг на інший домен, достатньо перенести цей `include` до іншого файлу в `sites-enabled/`.

### Basic-auth для Netdata

У Netdata немає власної авторизації, тому шлях `/netdata/` закритий basic-auth у Nginx. Файл із паролями:

```text
secrets/.htpasswd
```

Каталог `secrets/` у `.gitignore` — файл ніколи не потрапляє до репозиторію.

Створити користувача (команда працює і локально, і на VPS, `apache2-utils` не потрібен):

```bash
make htpasswd HTPASSWD_USER=petya
```

Команда дописує рядок у `secrets/.htpasswd`. Щоб замінити всіх користувачів, спочатку видаліть файл.

Постійна копія на VPS лежить поза робочим каталогом runner'а, поруч із `.env`:

```text
/home/petya/projects/main-nginx/.htpasswd
```

GitHub Actions копіює її в `secrets/.htpasswd` під час кожного деплою — так само, як `.env`. Створити її один раз на сервері:

```bash
cd /home/petya/projects/main-nginx
read -rsp 'Password: ' password && echo
printf '%s' "$password" | docker run --rm -i httpd:2.4-alpine htpasswd -niB petya | sed '/^$/d' >> .htpasswd
unset password
```

`make build` падає з явною помилкою, якщо файл відсутній або порожній, — Nginx не стартує з незахищеним дашбордом.

### Дані, що переживають деплой

`make down` виконується з прапорцем `--volumes`, тому дані Portainer (адмін-акаунт, налаштування) і бази Netdata зберігаються в **зовнішніх** томах — Docker Compose їх не видаляє:

```text
main-nginx-portainer-data
main-nginx-netdata-config
main-nginx-netdata-lib
main-nginx-netdata-cache
```

Томи створює `make create-volumes` — він викликається автоматично з `make build`, так само як `create-network`.

Переглянути томи:

```bash
make list-volumes
```

Видалити дані Portainer можна лише вручну:

```bash
docker volume rm main-nginx-portainer-data
```

### Перший вхід у Portainer

Під час першого запуску Portainer друкує в лог **setup token** — без нього екран створення адміністратора не відкриється:

```bash
docker compose logs portainer | grep setup_token
```

Відкрити `https://quizpet.mooo.com/portainer/`, вставити токен і створити адміністратора.

Токен діє, доки адміністратора не створено. Якщо лог уже перекрутився, перезапустити контейнер — Portainer згенерує новий:

```bash
docker compose restart portainer
```

Portainer запускається з прапорцем `--base-url /portainer`, а Nginx зрізає цей префікс перед проксуванням — цього вимагає офіційна документація Portainer. Сам Portainer при цьому слухає HTTP на порту `9000` (увімкнений за замовчуванням) і HTTPS на `9443`; назовні не публікується жоден із них.

Якщо під час входу з'являється помилка `Origin invalid`, домен не збігається з `--trusted-origins`. Значення береться з `.env`:

```dotenv
PORTAINER_TRUSTED_ORIGINS=https://quizpet.mooo.com
```

Можна вказати кілька доменів через кому, обов'язково зі схемою `https://`.

### Змінні оточення

Шаблон — `.env.example`. Актуальний `.env` зберігається на VPS за шляхом `/home/petya/projects/main-nginx/.env` і копіюється під час деплою.

| Змінна | Призначення | Типове значення |
|---|---|---|
| `NETDATA_HOSTNAME` | Ім'я вузла в дашборді Netdata | `main-nginx` |
| `PORTAINER_TRUSTED_ORIGINS` | Домени, з яких дозволено вхід у Portainer | `https://quizpet.mooo.com` |

### Доступ до Docker-сокета

Portainer монтує `/var/run/docker.sock` на запис — без цього він не керуватиме контейнерами. Netdata монтує той самий сокет у режимі `ro`, щоб збирати метрики контейнерів. Це означає, що доступ до Portainer фактично дорівнює root-доступу на VPS, тому пароль адміністратора має бути сильним.

### Мережеві метрики Netdata

Netdata працює в bridge-мережі, а не в `network_mode: host`. Так дашборд недоступний ззовні в обхід basic-auth, але метрики мережевих інтерфейсів показують інтерфейси контейнера, а не хоста. CPU, пам'ять, диски, процеси й логи читаються з хоста через змонтовані `/proc`, `/sys`, `/host/root` і `/var/log`.

### Логи контейнерів у Netdata

Netdata показує логи лише з двох джерел: systemd journal і власний OTLP-приймач. Контейнери пишуть у `json-file` (`/var/lib/docker/containers/<id>/<id>-json.log`), тож ні там, ні там їх немає — вкладка Logs була б порожньою.

Міст між ними — сервіс `otelcol` (OpenTelemetry Collector Contrib). Ланцюжок такий:

```text
docker_observer → file_log на кожен контейнер → оператор container → OTLP/gRPC → main-netdata:4317
```

- `docker_observer` стежить за Docker API і повідомляє про кожен запущений контейнер (`include_all_containers: true`, бо контейнери без відкритих портів інакше не потрапляють у список);
- `receiver_creator` піднімає окремий `file_log` на json-лог кожного контейнера — шлях містить лише id, тому ім'я береться з Docker API і кладеться в `service.name`;
- оператор `container` розбирає формат json-file: `log` → тіло запису, `time` → час, `stream` → атрибут `log.iostream`.

Конфігурація — `otelcol.yaml` у корені репозиторію.

**Де дивитися:** вкладка **Logs** → джерело `otel-logs` → селектор **Services**, у якому імена контейнерів (`main-nginx`, `quizpet-backend`, …).

#### Приймач OTLP у Netdata

Плагін `otel` увімкнений за замовчуванням, але слухає `127.0.0.1:4317` — із сусіднього контейнера туди не достукатися. Тому в `docker-compose.yaml` задано:

```yaml
NETDATA_OTEL_CFG_ENDPOINT_PATH: 0.0.0.0:4317
```

Ім'я змінної — це шлях у `otel.yaml` (`endpoint.path`) великими літерами з префіксом `NETDATA_OTEL_CFG_`. **Невідоме ім'я плагін не ігнорує — він падає з помилкою і не приймає нічого.** Побачити стокову схему:

```bash
docker compose exec netdata cat /etc/netdata/orig/otel.yaml
```

Порт `4317` назовні не публікується: він доступний лише контейнерам у `monitoring_network`, тому без TLS і без автентифікації.

#### Томи й зберігання

| Том | Навіщо |
| --- | --- |
| `main-nginx-netdata-log` | `/var/log/netdata` — тут плагін тримає прийняті логи (`otel/v2`); без тому вони зникали б при кожному `make build` |
| `main-nginx-otelcol-data` | позиції читання файлів і черга відправки коллектора |

На VPS лише 30 ГБ, тому дефолтні ліміти урізані:

| Що | Дефолт | У нас | Де задано |
| --- | --- | --- | --- |
| Логи в Netdata | 1 ГБ / 7 днів | 512 МБ / 3 дні | `NETDATA_OTEL_CFG_LOGS_RETENTION_MAX_TOTAL_SIZE`, `..._MAX_AGE` |
| Трейси в Netdata | 1 ГБ | 128 МБ | `NETDATA_OTEL_CFG_TRACES_RETENTION_MAX_TOTAL_SIZE` |
| Черга коллектора | 1000 запитів (до 2 млн записів) | 50 000 записів | `sending_queue` в `otelcol.yaml` |
| json-файли Docker | — | 10 МБ × 3 на контейнер | `x-logging` у compose кожного проєкту |

Ліміт ретеншну не покриває WAL, каталог і кеш — вони йдуть понад нього, тож реальна стеля близько 700 МБ. Ротація файлу — 25 МБ. Netdata приймає записи не старші за добу і не більш ніж на 10 хвилин у майбутньому; решту відхиляє. При переповненні черги коллектор відкидає зайве і пише про це у свій лог.

Одні й ті самі рядки лежать двічі: у json-файлі контейнера і в сховищі Netdata. Коллектор файли лише читає й ніколи не видаляє.

Імена змінних повторюють шлях у `otel.yaml`, але рівень `default` у них пропускається: `logs.retention.default.max_age` → `NETDATA_OTEL_CFG_LOGS_RETENTION_MAX_AGE`. Повний перелік підтримуваних імен можна дістати з бінарника:

```bash
docker compose exec netdata sh -c 'grep -ao "NETDATA_OTEL_CFG[A-Z_]*" /usr/libexec/netdata/plugins.d/otel-plugin | sort -u'
```

#### Доступи коллектора

Контейнер працює від root і монтує `/var/lib/docker/containers` та `docker.sock` у режимі `ro` — інакше не прочитає чужі логи й не побачить списку контейнерів. Власні логи коллектор не читає (умова `name != "main-otelcol"` у правилі), щоб не закільцювати потік.

#### Перевірка

```bash
docker compose logs otelcol | tail -20
```

```bash
docker compose exec netdata ls /var/log/netdata/otel/v2/logs/wal/default
```

Порожній каталог WAL означає, що до Netdata не дійшло жодного запису — шукати причину в логах `otelcol`.

### Перевірка після деплою

```bash
make ps
```

```bash
make check-config
```

```bash
curl -I -u petya https://quizpet.mooo.com/netdata/
```

```bash
curl -I https://quizpet.mooo.com/portainer/
```

Перечитати конфігурацію Nginx без перезапуску контейнера:

```bash
make reload
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

```
cd /home/petya/projects/main-nginx && read -rsp 'Password: ' password && echo && printf '%s' "$password" | docker run --rm -i httpd:2.4-alpine htpasswd -niB petya | sed '/^$/d' >> .htpasswd && unset password
```
