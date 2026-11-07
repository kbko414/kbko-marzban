#!/usr/bin/env bash
# KBKO Marzban — one-line installer: Marzban panel + KBKO subscription page.
set -e

# ---- config ----
REPO_RAW="https://raw.githubusercontent.com/kbko414/kbko-marzban/main"
MARZBAN_RAW="https://raw.githubusercontent.com/Gozargah/Marzban/master"
MARZBAN_SCRIPT="https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh"
APP_DIR="/opt/marzban"
DATA_DIR="/var/lib/marzban"
TEMPLATE_DIR="$DATA_DIR/templates/subscription"
PANEL_PORT=8000

# ---- helpers ----
say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
# .env ထဲ key တစ်ခု ထည့်/ပြင် — comment ဖြစ်နေရင် uncomment လုပ်၊ မရှိရင် အသစ်ထည့်
set_env() {
  if grep -q "^#* *$1 *=" "$APP_DIR/.env"; then
    sed -i "s|^#* *$1 *=.*|$1 = \"$2\"|" "$APP_DIR/.env"
  else
    echo "$1 = \"$2\"" >> "$APP_DIR/.env"
  fi
}

# ---- checks ----
# root မဟုတ်ရင် docker ရော compose ရော သွင်းလို့မရဘူး
[ "$(id -u)" = "0" ] || die "root နဲ့ run ပါ — ဥပမာ: sudo bash install.sh"
grep -qiE 'ubuntu|debian' /etc/os-release || die "Ubuntu / Debian ပဲ support လုပ်တယ်"

# ---- docker ----
if ! command -v docker >/dev/null 2>&1; then
  say "Docker သွင်းနေတယ်…"
  curl -fsSL https://get.docker.com | sh
fi

# ---- marzban files ----
# Official installer (marzban.sh @ install) က နောက်ဆုံးမှာ `logs -f` နဲ့
# တွယ်ကပ်နေလို့ one-line ထဲကနေ တိုက်ရိုက် ခေါ်လို့မရဘူး (2026-11-07 စစ်ပြီး)။
# ဒါကြောင့် သူ့ထဲက file ချတဲ့ အဆင့်တွေကိုပဲ ဒီမှာ ပြန်လုပ်ထားတာ —
# ရလဒ်က official အတိုင်းပဲ၊ logs တွယ်တာပဲ မပါတာ။
if [ ! -f "$APP_DIR/docker-compose.yml" ]; then
  say "Marzban file တွေ ဆွဲနေတယ်…"
  mkdir -p "$APP_DIR" "$DATA_DIR"
  curl -fsSL "$MARZBAN_RAW/docker-compose.yml" -o "$APP_DIR/docker-compose.yml"
  curl -fsSL "$MARZBAN_RAW/.env.example" -o "$APP_DIR/.env"
  # .env.example ထဲက default တွေကို uncomment လုပ်ပြီး path ညှိတာ — value အသစ် မထည့်ဘူး
  sed -i 's|^# *XRAY_JSON *=.*|XRAY_JSON = "/var/lib/marzban/xray_config.json"|' "$APP_DIR/.env"
  sed -i 's|^# *\(SQLALCHEMY_DATABASE_URL *=.*\)|\1|' "$APP_DIR/.env"
  curl -fsSL "$MARZBAN_RAW/xray_config.json" -o "$DATA_DIR/xray_config.json"
  # marzban CLI — admin create / restart / update တွေအတွက် official script ကိုယ်တိုင်
  curl -fsSL "$MARZBAN_SCRIPT" | install -m 755 /dev/stdin /usr/local/bin/marzban
  say "Marzban စတင်နေတယ်…"
  (cd "$APP_DIR" && docker compose up -d)
else
  say "Marzban ရှိပြီးသား — subscription page ပဲ အသစ် ပြန်သွင်းမယ်"
fi

# ---- subscription page ----
say "KBKO subscription page သွင်းနေတယ်…"
mkdir -p "$TEMPLATE_DIR"
curl -fsSL "$REPO_RAW/templates/subscription/index.html" -o "$TEMPLATE_DIR/index.html"
(cd "$APP_DIR" && docker compose restart)

# ---- wait ----
# container တက်လာတာ ခဏ စောင့်တာ — မတက်သေးရင်လည်း message က print ပြီးသား
for _ in $(seq 1 30); do
  if curl -s -o /dev/null "http://127.0.0.1:$PANEL_PORT/dashboard"; then break; fi
  sleep 2
done
IP="$(curl -fsSL https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"

# ---- domain + ssl ----
# Domain ရှိရင် ဒီတစ်ခေါက်တည်းမှာ SSL ပါ ခံပေးတာ — panel ကို http/IP နဲ့
# internet ပေါ် ဒီအတိုင်း ဖွင့်မထားစေချင်လို့ (2026-11-07 သူ့အမိန့်)။
# Domain မပေးရင် ဒီအဆင့် ကျော်ပြီး http panel ပဲ ရမယ်။
DOMAIN=""
if [ -e /dev/tty ]; then
  printf 'Domain ရှိလား (ဥပမာ vpn.example.com) — SSL ခံပေးမယ်၊ မရှိရင် Enter ပဲ နှိပ်ပါ: '
  read -r DOMAIN < /dev/tty || DOMAIN=""
fi
SSL_OK=""
if [ -n "$DOMAIN" ]; then
  echo "$DOMAIN" | grep -qE '^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' || die "Domain ပုံစံ မမှန်ဘူး: $DOMAIN"
  if grep -q '^UVICORN_SSL_CERTFILE' "$APP_DIR/.env"; then
    say "SSL ခံပြီးသားပဲ — ဒီအဆင့် ကျော်မယ်"
    SSL_OK="1"
  else
    # DNS က ဒီ server ဆီ မရောက်ရင် cert ထုတ်တာ ကျိန်းသေ fail မယ် — အရင် စစ်တာ
    RESOLVED="$(getent hosts "$DOMAIN" | awk '{print $1}' | head -n 1)"
    if [ "$RESOLVED" != "$IP" ]; then
      say "သတိ: $DOMAIN က $RESOLVED ဆီ point နေတယ်၊ ဒီ server က $IP — DNS အရင် ပြင်ပြီးမှ script ပြန် run ပါ။ SSL ကျော်လိုက်မယ်"
    else
      command -v certbot >/dev/null 2>&1 || { say "certbot သွင်းနေတယ်…"; apt-get update -qq && apt-get install -y -qq certbot; }
      CERT_DIR="$DATA_DIR/certs"
      mkdir -p "$CERT_DIR"
      if [ ! -f "$CERT_DIR/$DOMAIN.cert.pem" ]; then
        say "Let's Encrypt cert ထုတ်နေတယ် ($DOMAIN)…"
        # port 80 လွတ်နေမှ standalone ရတယ် — fresh VPS မှာ ပုံမှန် လွတ်နေကျ
        certbot certonly --standalone -d "$DOMAIN" --agree-tos --register-unsafely-without-email --non-interactive \
          || say "cert ထုတ် မရဘူး — port 80 / DNS စစ်ပြီး script ပြန် run ပါ။ SSL ကျော်လိုက်မယ်"
        if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
          cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$CERT_DIR/$DOMAIN.cert.pem"
          cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$CERT_DIR/$DOMAIN.key.pem"
          chmod 600 "$CERT_DIR/$DOMAIN.key.pem"
          # cert သက်တမ်း တိုးတိုင်း Marzban ဘက် copy + restart အလိုအလျောက် ဖြစ်အောင် hook ချန်ခဲ့တာ
          mkdir -p /etc/letsencrypt/renewal-hooks/deploy
          cat > /etc/letsencrypt/renewal-hooks/deploy/marzban-certs.sh <<EOF
#!/usr/bin/env bash
cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$CERT_DIR/$DOMAIN.cert.pem"
cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$CERT_DIR/$DOMAIN.key.pem"
(cd "$APP_DIR" && docker compose up -d)
EOF
          chmod +x /etc/letsencrypt/renewal-hooks/deploy/marzban-certs.sh
        fi
      fi
      if [ -f "$CERT_DIR/$DOMAIN.cert.pem" ]; then
        set_env UVICORN_SSL_CERTFILE "/var/lib/marzban/certs/$DOMAIN.cert.pem"
        set_env UVICORN_SSL_KEYFILE "/var/lib/marzban/certs/$DOMAIN.key.pem"
        # ဒါမပါရင် sub link တွေမှာ URL အပြည့် မပါဘူး (ကိုယ်တိုင် ကြုံဖူးတဲ့ lesson)
        set_env XRAY_SUBSCRIPTION_URL_PREFIX "https://$DOMAIN:$PANEL_PORT"
        say "SSL နဲ့ panel ပြန်တင်နေတယ်…"
        (cd "$APP_DIR" && docker compose up -d)
        for _ in $(seq 1 30); do
          if curl -sk -o /dev/null "https://127.0.0.1:$PANEL_PORT/dashboard"; then break; fi
          sleep 2
        done
        SSL_OK="1"
      fi
    fi
  fi
fi

# ---- report ----
echo
say "ပြီးပါပြီ ✅"
if [ -n "$SSL_OK" ]; then
  echo "Panel:   https://$DOMAIN:$PANEL_PORT/dashboard"
else
  echo "Panel:   http://$IP:$PANEL_PORT/dashboard"
  echo "မှတ်ချက်: production သုံးမယ်ဆို domain + SSL ခံပြီးမှ သုံးပါ (README မှာ အသေးစိတ် ရှိတယ်)"
fi
echo "Admin အရင် ဆောက်ပါ:   marzban cli admin create --sudo"
