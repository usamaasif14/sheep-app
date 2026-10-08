"""
cli.py - Terminal Command Line Interface for Sheep Farm Management
Enables farmers to manage flock records, inspect finances, and generate backups directly from terminal.
"""

import sys
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

import uuid
import argparse
from datetime import datetime
from db_manager import DatabaseManager

db = DatabaseManager()

def list_sheep():
    sheep = db.get_all_sheep()
    if not sheep:
        print("No sheep registered in the database.")
        return

    print("\n" + "="*80)
    print(f"{'TAG':<12} | {'NAME':<15} | {'BREED':<12} | {'GENDER':<8} | {'WEIGHT (KG)':<12} | {'STATUS':<10}")
    print("="*80)
    for s in sheep:
        name = s['name'] if s['name'] else "—"
        breed = s['breed'] if s['breed'] else "—"
        weight = f"{s['weight']:.1f}" if s['weight'] else "—"
        print(f"{s['tagNumber']:<12} | {name:<15} | {breed:<12} | {s['gender']:<8} | {weight:<12} | {s['status']:<10}")
    print("="*80)
    print(f"Total Sheep Count: {len(sheep)}\n")

def add_sheep():
    print("\n--- Add New Sheep ---")
    tag = input("Enter Tag Number (e.g. SHP-101): ").strip()
    if not tag:
        print("Error: Tag Number cannot be empty!")
        return

    name = input("Enter Sheep Name (optional): ").strip()
    breed = input("Enter Breed (e.g. Merino, Dorper): ").strip() or "Merino"
    gender = input("Gender (1 for Female, 2 for Male) [1]: ").strip()
    gender = "Male" if gender == "2" else "Female"

    try:
        weight = float(input("Current Weight in kg [0.0]: ").strip() or "0.0")
    except ValueError:
        weight = 0.0

    color = input("Color [White]: ").strip() or "White"
    now_str = datetime.utcnow().isoformat()

    sheep_id = str(uuid.uuid4())
    data = {
        "id": sheep_id,
        "tagNumber": tag,
        "name": name,
        "breed": breed,
        "gender": gender,
        "dateOfBirth": now_str,
        "weight": weight,
        "color": color,
        "status": "Active",
        "dateAdded": now_str,
        "lastUpdated": now_str,
    }
    db.insert_sheep(data)
    print(f"✅ Successfully registered sheep {tag} ({name or 'Unnamed'})!\n")

def show_stats():
    stats = db.get_sheep_stats()
    finances = db.get_financial_summary()

    print("\n" + "="*50)
    print("📊 SHEEP FARM OVERVIEW & ANALYTICS")
    print("="*50)
    print(f"Total Flock:      {stats['total']}")
    print(f"Active Ewes:      {stats['ewes']}")
    print(f"Active Rams:      {stats['rams']}")
    print(f"Sold Sheep:       {stats['sold']}")
    print(f"Deceased:         {stats['deceased']}")
    print("-" * 50)
    print(f"Total Income:     Rs {finances['income']:,.2f}")
    print(f"Total Expenses:   Rs {finances['expense']:,.2f}")
    net = finances['net_profit']
    status = "PROFIT" if net >= 0 else "LOSS"
    print(f"Net Profit / Loss: Rs {net:,.2f} ({status})")
    print("="*50 + "\n")

def export_backup():
    backup = db.export_full_backup()
    filename = f"sheep_farm_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    import json
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(backup, f, indent=2)
    print(f"✅ Full farm database exported to '{filename}' successfully!")

def main():
    parser = argparse.ArgumentParser(description="Sheep Farm Management CLI")
    parser.add_argument("command", nargs="?", default="menu",
                        choices=["menu", "list", "add", "stats", "backup"],
                        help="Action to perform")
    args = parser.parse_args()

    if args.command == "list":
        list_sheep()
    elif args.command == "add":
        add_sheep()
    elif args.command == "stats":
        show_stats()
    elif args.command == "backup":
        export_backup()
    else:
        while True:
            print("\n🐑 SHEEP FARM MANAGER CLI")
            print("1. View Flock List")
            print("2. Add New Sheep")
            print("3. Farm Statistics & Finance Summary")
            print("4. Export Full JSON Backup")
            print("5. Exit")
            choice = input("\nEnter choice (1-5): ").strip()
            if choice == "1":
                list_sheep()
            elif choice == "2":
                add_sheep()
            elif choice == "3":
                show_stats()
            elif choice == "4":
                export_backup()
            elif choice == "5":
                print("Goodbye!")
                break
            else:
                print("Invalid option, please choose 1-5.")

if __name__ == "__main__":
    main()
