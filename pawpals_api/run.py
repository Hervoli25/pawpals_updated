from app import create_app, db
from app.models import models # Import all models to ensure they are known to SQLAlchemy and Flask-Migrate

app = create_app()

if __name__ == "__main__":
    # For development, you might want to run with debug=True
    # Ensure to set FLASK_ENV=development and FLASK_DEBUG=1 in your .env or environment
    app.run(host="0.0.0.0", port=5000, debug=True)

