"""
Deterministic synthetic seed generator for product-metrics-playbook.

Regenerates seed_customers.csv, seed_orders.csv, and seed_product_events.csv
in this same directory. Fixed random seed (42) means re-running this script
produces byte-identical output — the seeds under version control are exactly
this script's output, not hand-edited afterwards.

No real data of any kind is used or referenced; every id, date, and amount
here is synthetic. Run with: `python3 seeds/generate_seeds.py` from the repo
root.
"""
import os
import random
import csv
from datetime import date, datetime, timedelta

random.seed(42)

START = date(2026, 1, 1)
END = date(2026, 6, 30)

COUNTRIES = ["PT"] * 55 + ["ES"] * 15 + ["FR"] * 12 + ["DE"] * 10 + ["IT"] * 8

PRODUCTS = {
    "SKU-101": 9.99,
    "SKU-102": 14.50,
    "SKU-103": 24.00,
    "SKU-104": 39.90,
    "SKU-105": 12.25,
    "SKU-106": 59.00,
    "SKU-107": 19.99,
    "SKU-108": 89.00,
    "SKU-109": 6.50,
    "SKU-110": 44.00,
    "SKU-111": 119.00,
    "SKU-112": 27.75,
}
PRODUCT_IDS = list(PRODUCTS.keys())

N_CUSTOMERS = 60


def month_range(d1, d2):
    months = []
    cur = date(d1.year, d1.month, 1)
    while cur <= d2:
        months.append(cur)
        if cur.month == 12:
            cur = date(cur.year + 1, 1, 1)
        else:
            cur = date(cur.year, cur.month + 1, 1)
    return months


def days_in_month(m):
    if m.month == 12:
        nxt = date(m.year + 1, 1, 1)
    else:
        nxt = date(m.year, m.month + 1, 1)
    return (nxt - m).days


ALL_MONTHS = month_range(START, END)

customers = []
for i in range(1, N_CUSTOMERS + 1):
    cid = f"C-{i:03d}"
    # signup weighted towards the first 4 months, tapering off
    signup_month_idx = min(int(random.triangular(0, 5, 0)), 4)
    signup_month = ALL_MONTHS[signup_month_idx]
    signup_day = random.randint(1, days_in_month(signup_month))
    signup_date = date(signup_month.year, signup_month.month, signup_day)
    country = random.choice(COUNTRIES)
    cohort_roll = random.random()
    if cohort_roll < 0.25:
        behavior = "loyal"
    elif cohort_roll < 0.60:
        behavior = "engaged_then_churn"
    elif cohort_roll < 0.85:
        behavior = "one_and_done"
    else:
        behavior = "sporadic"
    customers.append({
        "customer_id": cid,
        "signup_date": signup_date,
        "country": country,
        "behavior": behavior,
    })


def active_months_for(customer):
    signup_month = date(customer["signup_date"].year, customer["signup_date"].month, 1)
    idx0 = ALL_MONTHS.index(signup_month)
    remaining = ALL_MONTHS[idx0:]
    behavior = customer["behavior"]
    if behavior == "loyal":
        return [m for m in remaining if random.random() > 0.1]
    elif behavior == "engaged_then_churn":
        span = random.randint(1, min(3, len(remaining)))
        return remaining[:span]
    elif behavior == "one_and_done":
        return remaining[:1]
    else:  # sporadic
        return [m for m in remaining if random.random() < 0.35] or remaining[:1]


events = []
orders = []
event_seq = 1
order_seq = 1001


def emit(cid, t, event_type):
    global event_seq
    events.append({
        "event_id": f"E-{event_seq}",
        "customer_id": cid,
        "event_ts": t,
        "event_type": event_type,
    })
    event_seq += 1
    return t


def run_session(cid, session_start):
    t = session_start
    if random.random() < 0.8:
        t = t + timedelta(seconds=0)
        emit(cid, t, "login")
    n_views = random.randint(1, 3)
    for _ in range(n_views):
        t = t + timedelta(seconds=random.randint(15, 90))
        emit(cid, t, "view_product")

    checked_out = False
    checkout_ts = None
    if random.random() < 0.55:
        t = t + timedelta(seconds=random.randint(10, 60))
        emit(cid, t, "add_to_cart")
        if random.random() < 0.70:
            t = t + timedelta(seconds=random.randint(20, 120))
            checkout_ts = emit(cid, t, "checkout")
            checked_out = True

    if checked_out:
        global order_seq
        n_items = random.randint(1, 3)
        chosen = random.sample(PRODUCT_IDS, n_items)
        item_parts = []
        total = 0.0
        for pid in chosen:
            qty = random.randint(1, 3)
            price = PRODUCTS[pid]
            total += qty * price
            item_parts.append(f"{pid}:{qty}:{price:.2f}")
        orders.append({
            "order_id": f"O-{order_seq}",
            "customer_id": cid,
            "order_ts": checkout_ts,
            "amount": round(total, 2),
            "currency": "EUR",
            "items": "|".join(item_parts),
        })
        order_seq += 1


for customer in customers:
    cid = customer["customer_id"]
    signup_month = date(customer["signup_date"].year, customer["signup_date"].month, 1)
    for month in active_months_for(customer):
        n_sessions = random.randint(1, 3)
        dim = days_in_month(month)
        # a customer can't have events before their own signup day
        min_day = customer["signup_date"].day if month == signup_month else 1
        available_days = range(min_day, dim + 1)
        session_days = sorted(random.sample(list(available_days), min(n_sessions, len(available_days))))
        for day in session_days:
            hour = random.randint(8, 21)
            minute = random.randint(0, 59)
            session_start = datetime(month.year, month.month, day, hour, minute)
            run_session(cid, session_start)

events.sort(key=lambda e: (e["event_ts"], e["event_id"]))
orders.sort(key=lambda o: (o["order_ts"], o["order_id"]))
customers.sort(key=lambda c: c["customer_id"])

OUT = os.path.dirname(os.path.abspath(__file__))

with open(f"{OUT}/seed_customers.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["customer_id", "signup_date", "country"])
    for c in customers:
        w.writerow([c["customer_id"], c["signup_date"].isoformat(), c["country"]])

with open(f"{OUT}/seed_orders.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["order_id", "customer_id", "order_ts", "amount", "currency", "items"])
    for o in orders:
        w.writerow([o["order_id"], o["customer_id"], o["order_ts"].isoformat(), f'{o["amount"]:.2f}', o["currency"], o["items"]])

with open(f"{OUT}/seed_product_events.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["event_id", "customer_id", "event_ts", "event_type"])
    for e in events:
        w.writerow([e["event_id"], e["customer_id"], e["event_ts"].isoformat(), e["event_type"]])

print(f"customers={len(customers)} orders={len(orders)} events={len(events)}")
print("behavior mix:", {b: sum(1 for c in customers if c["behavior"] == b) for b in ["loyal", "engaged_then_churn", "one_and_done", "sporadic"]})
print("months with any activity:", len(set((e['event_ts'].year, e['event_ts'].month) for e in events)))
