"""
reports.py - Farm Performance & Financial Reports Generator
Generates CSV spreadsheets and HTML summaries for farm record-keeping and Play Store distribution.
"""

import csv
import json
from datetime import datetime
from db_manager import DatabaseManager

db = DatabaseManager()

def generate_flock_csv(filepath: str = "flock_inventory.csv") -> str:
    sheep = db.get_all_sheep()
    fieldnames = ["Tag", "Name", "Breed", "Gender", "Weight_kg", "Color", "Status", "DateAdded"]
    with open(filepath, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for s in sheep:
            writer.writerow({
                "Tag": s["tagNumber"],
                "Name": s["name"],
                "Breed": s["breed"],
                "Gender": s["gender"],
                "Weight_kg": s["weight"],
                "Color": s["color"],
                "Status": s["status"],
                "DateAdded": s["dateAdded"][:10],
            })
    return filepath

def generate_financial_csv(filepath: str = "financial_ledger.csv") -> str:
    records = db.get_all_financial_records()
    fieldnames = ["Date", "Type", "Category", "Description", "Amount", "Notes"]
    with open(filepath, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in records:
            writer.writerow({
                "Date": r["date"][:10],
                "Type": r["type"],
                "Category": r["category"],
                "Description": r["description"],
                "Amount": r["amount"],
                "Notes": r.get("notes", ""),
            })
    return filepath

def generate_summary_html(filepath: str = "farm_report.html") -> str:
    stats = db.get_sheep_stats()
    fin = db.get_financial_summary()
    sheep = db.get_all_sheep()

    html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Sheep Farm Management Report</title>
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0D1B2A; color: #F0F4F8; margin: 40px; }}
        .header {{ display: flex; justify-content: space-between; border-bottom: 2px solid #E8A838; padding-bottom: 15px; margin-bottom: 30px; }}
        h1 {{ color: #E8A838; margin: 0; }}
        .grid {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 30px; }}
        .card {{ background: #1B2A3D; border: 1px solid #2D3F54; border-radius: 12px; padding: 20px; }}
        .card-title {{ color: #B0BEC5; font-size: 13px; text-transform: uppercase; }}
        .card-value {{ font-size: 28px; font-weight: bold; margin-top: 8px; }}
        .income {{ color: #4CAF7D; }}
        .expense {{ color: #EF5350; }}
        .profit {{ color: #E8A838; }}
        table {{ width: 100%; border-collapse: collapse; background: #1B2A3D; border-radius: 12px; overflow: hidden; }}
        th, td {{ padding: 12px 16px; text-align: left; border-bottom: 1px solid #2D3F54; }}
        th {{ background: #243447; color: #E8A838; }}
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>🐑 Sheep Farm Performance Report</h1>
            <p>Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </div>
    </div>

    <div class="grid">
        <div class="card">
            <div class="card-title">Total Active Flock</div>
            <div class="card-value">{stats['active']}</div>
        </div>
        <div class="card">
            <div class="card-title">Ewes / Rams</div>
            <div class="card-value">{stats['ewes']} / {stats['rams']}</div>
        </div>
        <div class="card">
            <div class="card-title">Total Income</div>
            <div class="card-value income">Rs {fin['income']:,.0f}</div>
        </div>
        <div class="card">
            <div class="card-title">Net Profit</div>
            <div class="card-value profit">Rs {fin['net_profit']:,.0f}</div>
        </div>
    </div>

    <h2>Flock Inventory Details</h2>
    <table>
        <thead>
            <tr>
                <th>Tag #</th>
                <th>Name</th>
                <th>Breed</th>
                <th>Gender</th>
                <th>Weight</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
"""
    for s in sheep:
        html += f"""            <tr>
                <td><strong>{s['tagNumber']}</strong></td>
                <td>{s['name'] or '—'}</td>
                <td>{s['breed']}</td>
                <td>{s['gender']}</td>
                <td>{s['weight']} kg</td>
                <td>{s['status']}</td>
            </tr>
"""

    html += """        </tbody>
    </table>
</body>
</html>"""

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(html)
    return filepath

if __name__ == "__main__":
    c1 = generate_flock_csv()
    c2 = generate_financial_csv()
    h = generate_summary_html()
    print(f"Generated {c1}, {c2}, {h}")
