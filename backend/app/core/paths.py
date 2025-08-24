# app/core/paths.py
import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))  # .../app/core
UPLOAD_DIR = os.getenv("UPLOAD_DIR", os.path.abspath(os.path.join(BASE_DIR, "..", "uploads")))
