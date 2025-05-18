import os
from dotenv import load_dotenv

basedir = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(basedir, ".env"))

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY") or "you-will-never-guess"
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL") or \
        "postgresql://user:password@localhost:5432/pawpalsdb" # Replace with your actual DB URI
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY") or "super-secret-jwt-key" # Change this!
    # Add other configurations as needed, e.g., for mail, Nominatim API URL
    NOMINATIM_API_URL = "https://nominatim.openstreetmap.org"

