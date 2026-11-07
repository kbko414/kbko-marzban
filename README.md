# KBKO Marzban — One-Line Installer

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-E95420?logo=ubuntu&logoColor=white)
![Panel](https://img.shields.io/badge/Panel-Marzban-blue)

**One command. Full VPN panel. Burmese subscription page included.**

Marzban VPN panel ကို **KBKO subscription page** နဲ့အတူ command တစ်ကြောင်းတည်းနဲ့ သွင်းပေးတဲ့ installer ပါ။

- ✅ Marzban panel (official Docker image — SQLite)
- ✅ KBKO ပုံစံ subscription page — မြန်မာဘာသာ၊ data သုံးထားတာ bar နဲ့ပြ၊ ကျန်ရက်၊ config copy / QR၊ app ထဲ တစ်ချက်နှိပ် import (v2rayNG · Hiddify · Streisand)
- ✅ `marzban` CLI ပါ တစ်ခါတည်း သွင်းပေးတယ်
- ✅ Script ကို နောက်တစ်ခါ ပြန် run ရင် panel ကို မထိဘူး — subscription page ပဲ အသစ် ပြန်သွင်းပေးတယ်

## လိုအပ်ချက်များ

- Ubuntu / Debian VPS (အသစ် ဖြစ်ရင် ပိုကောင်း)
- RAM 1 GB အနည်းဆုံး
- root access

## သွင်းနည်း

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kbko414/kbko-marzban/main/install.sh)
```

သွင်းနေရင်း **domain မေးပါမယ်** — domain ကို VPS IP ဆီ အရင် point ထားပြီး ရိုက်ထည့်လိုက်ရင် Let's Encrypt SSL အထိ တစ်ခါတည်း ပြီးသွားမယ်။ Domain မရှိသေးရင် Enter ပဲ နှိပ်ပါ၊ panel လိပ်စာ `http://YOUR_IP:8000/dashboard` ရမယ်။

## သွင်းပြီးရင် လုပ်ရန်

**၁။ Admin account ဆောက်ပါ**

```bash
marzban cli admin create --sudo
```

**၂။ Domain + SSL (installer က မလုပ်ခဲ့ရင် manual)**

Installer run တုန်းက domain ပေးခဲ့ရင် ဒီအဆင့် ပြီးပြီးသား — cert သက်တမ်းတိုးတိုင်းလည်း Marzban ဘက်ကို အလိုအလျောက် လဲပေးတဲ့ renewal hook ပါ ထည့်ပေးထားတယ်။

Manual လုပ်ချင်ရင် domain ကို VPS IP ဆီ point ပြီး `.env` ( /opt/marzban/.env ) ထဲမှာ ဒါတွေ ဖြည့်ပါ —

```
UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/YOUR_DOMAIN.cert.pem"
UVICORN_SSL_KEYFILE = "/var/lib/marzban/certs/YOUR_DOMAIN.key.pem"
XRAY_SUBSCRIPTION_URL_PREFIX = "https://YOUR_DOMAIN:8000"
```

Cert ကို certbot နဲ့ ထုတ်ပြီး `/var/lib/marzban/certs/` ထဲ copy ထည့်၊ ပြီးရင် —

```bash
cd /opt/marzban && docker compose up -d
```

`XRAY_SUBSCRIPTION_URL_PREFIX` မထည့်ရင် subscription link တွေထဲမှာ URL အပြည့်အစုံ မပါဘဲ page ပဲ ပေါ်နေတတ်တယ် — ကိုယ့် domain နဲ့ ထည့်ထားတာ အကောင်းဆုံးပဲ။

**၃။ User ဆောက်ပြီး စမ်းပါ**

Panel ထဲမှာ Inbound (VLESS Reality အကြံပြု) အရင် ထည့်၊ user ဆောက်၊ subscription link ကို ဖုန်းထဲ ထည့်ပြီး connect ဖြစ်တာ စစ်ပါ။

## ဖျက်နည်း

```bash
marzban uninstall
```

## Credit

- Panel: [Gozargah/Marzban](https://github.com/Gozargah/Marzban) — ဒီ repo က installer wrapper + subscription page ပဲ ဖြစ်ပြီး panel code မဟုတ်ပါ
- Subscription page + installer: KBKO

## License

MIT — [LICENSE](LICENSE) ကို ကြည့်ပါ
