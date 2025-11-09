# FIFA DB Tools for 14, 15 & 16

**FIFA DB Tools** is a set of scripts and utilities to convert, edit, and manage FIFA 14, 15, and 16 databases.  
It allows easy modification of transfers, loans, players, leagues, and other database values.

---

## 🛠 Workflow / How to use

1. **Export FIFA database to TXT**  
   Use `dbmaster` to export the database to a `.txt` file.

2. **Import TXT to SQL**  
   Run `txt2sql.sh` to convert the TXT file into SQL format.

3. **Modify the database**  
   Edit or convert values such as:
   - Transfers
   - Loans
   - Players
   - Leagues

4. **Export modified database to TXT**  
   Use `sql2txt.sh` to export the SQL database back to TXT and export to utf-16.

5. **Import TXT back to DB Master**  
   Import the modified TXT file back into with db master.

---

## 📁 Supported Versions

- FIFA 14 (full-modification)
- FIFA 15 (full modification & migration)
- FIFA 16 (full modification & migration)

---

## ⚙️ Scripts Included
- `txt2sql.sh` — convert TXT → SQL  
- `sql2txt.sh` — convert SQL → TXT  
- `transfers/` — transfer-related modifications  
- `loans/` — loan management  
- `players/` — player information edits  
- `league/` — league and competition modifications  
- `to_fifa15/`, `to_fifa16/` — migration scripts for FIFA15/16  
- `container.sh` — prepare local environment
