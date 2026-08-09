"""Run the test suite against a throwaway SQLite DB instead of the dev DB.

Isolation requires DATABASE_URL to be set before `app.*` is imported (pytest
imports conftest first), and before TestClient bootstrap/seeding runs.
"""
import os
import tempfile

_fd, _path = tempfile.mkstemp(prefix="jeevandoot_test_", suffix=".db")
os.close(_fd)
os.environ["DATABASE_URL"] = f"sqlite:///{_path.replace(os.sep, '/')}"

del _fd  # keep the path referenced for the session