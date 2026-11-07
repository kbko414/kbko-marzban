# KBKO Marzban — One-Line Installer

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

ပြီးသွားရင် terminal မှာ panel လိပ်စာ ပေါ်လာမယ် — ဥပမာ `http://YOUR_IP:8000/dashboard`

## သွင်းပြီးရင် လုပ်ရန်

**၁။ Admin account ဆောက်ပါ**

```bash
marzban cli admin create --sudo
```

**၂။ Domain + SSL ခံပါ (production သုံးမယ်ဆို မဖြစ်မနေ)**

Panel ကို IP + http နဲ့ ဒီအတိုင်း internet ဖွင့်ထားတာ မလုံခြုံဘူး။ Domain တစ်ခုကို VPS IP ဆီ point လုပ်ပြီး `.env` ထဲမှာ ဒါတွေ ဖြည့်ပါ —

```
UVICORN_HOST = "0.0.0.0"
UVICORN_PORT = 8000
UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/YOUR_DOMAIN.cert.pem"
UVICORN_SSL_KEYFILE = "/var/lib/marzban/certs/YOUR_DOMAIN.key.pem"
XRAY_SUBSCRIPTION_URL_PREFIX = "https://YOUR_DOMAIN:8000"
```

Cert ကို `marzban` CLI ထဲက SSL ထုတ်တဲ့ command ဒါမှမဟုတ် certbot နဲ့ ထုတ်လို့ရတယ်။ ပြီးရင် —

```bash
marzban restart
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
