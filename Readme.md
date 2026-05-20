📊 ARCHITECTURE
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
