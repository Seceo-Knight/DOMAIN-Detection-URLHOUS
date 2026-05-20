#  ✅ PRODUCTION-READY

## 📊 ARCHITECTURE
```
         ↓
Update Script (Every 30 minutes)
         ├─ Download & Extract
         ├─ Filter Whitelist
         ├─ Deduplicate
         └─ Deploy to SeceoKnight
         ↓
SeceoKnight Domain Blacklist (12K+ unique entries)
         ↓
Detection Rule 100702 (DNS Detection)
         ├─ Sysmon Event 22: DNS Query
         └─ Match against URLhaus blacklist
         ↓
SeceoKnight Alerts
    ├─ URLhaus DNS Detections (Rule 100702)
    └─ 
         ↓
SeceoKnight Dashboard & Logs
```
## 🚀 INTEGRATION IN 8 SIMPLE STEPS
STEP 1: Create Directory
```
sudo mkdir -p /var/ossec/etc/lists/urlhaus/backups
sudo chown -R wazuh:wazuh /var/ossec/etc/lists/urlhaus
sudo chmod 750 /var/ossec/etc/lists/urlhaus
```
STEP 2: Create Whitelist
```
sudo nano /var/ossec/etc/lists/urlhaus/whitelist.txt
```

Add example :
```
google.com:
microsoft.com:
cloudflare.com:
amazon.com:
facebook.com:
github.com:
stackoverflow.com:
docker.com:
ec2-52-6-145-153.compute-1.amazonaws.com:
8.8.8.8:
8.8.4.4:
1.1.1.1:
1.0.0.1:
```

## ✅ CREATE CORRECT RULES FILE
```
sudo nano /var/ossec/etc/rules/urlhaus_rules.xml
```
## ✅ PERMISSION
```
sudo chown wazuh:wazuh /var/ossec/etc/rules/urlhaus_rules.xml
sudo chmod 640 /var/ossec/etc/rules/urlhaus_rules.xml
```
## ✅ SCRIPT: UPDATE SCRIPT (NO DUPLICATES)
```
sudo nano /var/ossec/etc/lists/urlhaus/update_urlhaus.sh
```
Make executable:
```
sudo chmod +x /var/ossec/etc/lists/urlhaus/update_urlhaus.sh
```
## ✅ Run the Script
```
sudo /var/ossec/etc/lists/urlhaus/update_urlhaus.sh
```
Wait 30 seconds, then check:
```
tail -30 /var/ossec/etc/lists/urlhaus/update.log
```
Should show:
```
[2026-05-20 07:30:00] ========== URLhaus Update Started ==========
[2026-05-20 07:30:10] ✓ Downloaded 45823 lines
[2026-05-20 07:30:11]   Extracted 12456 unique domains
[2026-05-20 07:30:11]   Extracted 300 unique IPs
[2026-05-20 07:30:11] Filtered: 234 domains, 5 IPs (whitelisted)
[2026-05-20 07:30:12] Final: 12521 lines → 12517 unique entries (removed 4 duplicates)
[2026-05-20 07:30:12] ✓ Deployed: 12517 unique entries (NO DUPLICATES)
[2026-05-20 07:30:12] Cleaned: Deleted 0 old backups
[2026-05-20 07:30:12] Kept: 2 backups in 30-day window
[2026-05-20 07:30:12] ========== Update Complete ==========
```
## ✅ FIX 3: UPDATE CRONTAB (More Frequent Updates)
```
sudo crontab -e
```
Add this cron (update every 30 minutes):
```
# URLhaus update - Every 30 minutes (0, 30)
0,30 * * * * /var/ossec/etc/lists/urlhaus/update_urlhaus.sh >> /var/ossec/etc/lists/urlhaus/cron.log 2>&1

# Clean old backups - Daily at 5 AM, keep 30-day window
0 5 * * * find /var/ossec/etc/lists/urlhaus/backups -name "urlhaus_blacklist.*" -mtime +30 -delete
```
## This means:
- ✅ **Updates at: 00, 30 minutes of every hour (2x per hour = 48 times daily)**
- ✅ **Cleans old backups daily at 5 AM**
- ✅ **Keeps last 30 days of backups**
