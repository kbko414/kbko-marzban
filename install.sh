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

# ---- wait + report ----
# container တက်လာတာ ခဏ စောင့်တာ — မတက်သေးရင်လည်း message က print ပြီးသား
for _ in $(seq 1 30); do
  if curl -s -o /dev/null "http://127.0.0.1:$PANEL_PORT/dashboard"; then break; fi
  sleep 2
done
IP="$(curl -fsSL https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')"
echo
say "ပြီးပါပြီ ✅"
echo "Panel:   http://$IP:$PANEL_PORT/dashboard"
echo "Admin အရင် ဆောက်ပါ:   marzban cli admin create --sudo"
echo "မှတ်ချက်: production သုံးမယ်ဆို domain + SSL ခံပြီးမှ သုံးပါ (README မှာ အသေးစိတ် ရှိတယ်)"
