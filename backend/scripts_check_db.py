import sqlite3

conn = sqlite3.connect("app/jeevandoot.db")
n_viewed = conn.execute(
    "SELECT COUNT(*) FROM case_file_audit_log"
    " WHERE patient_id='PT-9942' AND action='CASE_FILE_VIEWED'"
).fetchone()[0]
updated = conn.execute(
    "SELECT updated_at FROM case_files WHERE patient_id='PT-9942'"
).fetchone()[0]
print("CASE_FILE_VIEWED rows for PT-9942:", n_viewed)
print("updated_at:", updated)
conn.close()
