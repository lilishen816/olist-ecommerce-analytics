import csv

with open(r'C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\sample_data\olist_geolocation_dataset.csv', encoding='utf-8-sig') as f:
    rows = list(csv.DictReader(f))

clean = []
for r in rows:
    lat = float(r['geolocation_lat'])
    lng = float(r['geolocation_lng'])
    # 保留合法范围内的行，其余丢弃
    if -35 <= lat <= 6 and -75 <= lng <= -30:
        clean.append(r)

print('清洗前:', len(rows), '行 → 清洗后:', len(clean), '行')

with open(r'C:\Users\李深\Documents\Codex\olist-ecommerce-analytics\data\sample_data\olist_geolocation_dataset.csv', 'w', encoding='utf-8-sig', newline='') as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(clean)
