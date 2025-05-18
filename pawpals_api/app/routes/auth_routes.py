from flask import Blueprint, request, jsonify
from app import db, jwt
from app.models.models import User
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from datetime import timedelta

bp = Blueprint("auth", __name__)

@bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    if not data or not data.get("email") or not data.get("password") or not data.get("name"):
        return jsonify({"message": "Missing name, email, or password"}), 400

    if User.query.filter_by(email=data["email"]).first():
        return jsonify({"message": "User already exists"}), 400

    user = User(name=data["name"], email=data["email"])
    user.set_password(data["password"])
    # Optionally set location if provided
    if data.get("location_latitude") and data.get("location_longitude"):
        user.location_latitude = data["location_latitude"]
        user.location_longitude = data["location_longitude"]
    
    db.session.add(user)
    db.session.commit()

    access_token = create_access_token(identity=str(user.id), expires_delta=timedelta(days=7))
    return jsonify({"message": "User registered successfully", "token": access_token, "user": user.to_dict()}), 201

@bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    if not data or not data.get("email") or not data.get("password"):
        return jsonify({"message": "Missing email or password"}), 400

    user = User.query.filter_by(email=data["email"]).first()

    if user is None or not user.check_password(data["password"]):
        return jsonify({"message": "Invalid credentials"}), 401

    access_token = create_access_token(identity=str(user.id), expires_delta=timedelta(days=7))
    return jsonify({"token": access_token, "user": user.to_dict()}), 200

@bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    data = request.get_json()
    if not data or not data.get("email"):
        return jsonify({"message": "Email is required"}), 400

    user = User.query.filter_by(email=data["email"]).first()
    if not user:
        # Still return 200 to prevent user enumeration, but don't send email
        return jsonify({"message": "If your email is registered, you will receive a password reset link."}), 200

    # Placeholder for password reset email logic
    # This would typically involve generating a unique, short-lived token,
    # storing it (e.g., in a new table or a cache like Redis),
    # and sending an email to the user with a link containing this token.
    # For now, we just simulate success.
    print(f"Simulating password reset email for {user.email}")
    # In a real app: send_password_reset_email(user)
    
    return jsonify({"message": "If your email is registered, you will receive a password reset link."}), 200

@bp.route("/me", methods=["GET"])
@jwt_required()
def get_me():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404
    return jsonify(user.to_dict()), 200

# Example of a protected route
@bp.route("/protected", methods=["GET"])
@jwt_required()
def protected():
    current_user_id = get_jwt_identity()
    return jsonify(logged_in_as=current_user_id), 200

