from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from config import Config

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    CORS(app)  # Enable CORS for all routes, or configure specific origins

    # Register Blueprints here
    from app.routes.auth_routes import bp as auth_bp
    app.register_blueprint(auth_bp, url_prefix=
"/api/auth")

    from app.routes.dog_routes import bp as dog_bp
    app.register_blueprint(dog_bp, url_prefix=
"/api")

    from app.routes.place_routes import bp as place_bp
    app.register_blueprint(place_bp, url_prefix=
"/api")

    from app.routes.playdate_routes import bp as playdate_bp
    app.register_blueprint(playdate_bp, url_prefix=
"/api")

    # Basic route for testing
    @app.route("/health")
    def health_check():
        return "API is healthy!", 200

    return app

