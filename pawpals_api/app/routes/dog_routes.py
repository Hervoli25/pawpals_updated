from flask import Blueprint, request, jsonify
from app import db
from app.models.models import Dog, User
from flask_jwt_extended import jwt_required, get_jwt_identity
import uuid

bp = Blueprint("dogs", __name__)

@bp.route("/dogs", methods=["POST"])
@jwt_required()
def create_dog():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404

    data = request.get_json()
    if not data or not data.get("name"):
        return jsonify({"message": "Dog name is required"}), 400

    new_dog = Dog(
        user_id=user.id,
        name=data["name"],
        breed=data.get("breed"),
        age_years=data.get("age_years"),
        size=data.get("size"),
        temperament=data.get("temperament"),
        profile_image_url=data.get("profile_image_url")
    )
    db.session.add(new_dog)
    db.session.commit()
    return jsonify(new_dog.to_dict()), 201

@bp.route("/dogs", methods=["GET"])
@jwt_required()
def get_user_dogs():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404
    
    dogs = Dog.query.filter_by(user_id=user.id).all()
    return jsonify([dog.to_dict() for dog in dogs]), 200

@bp.route("/dogs/<dog_id>", methods=["GET"])
@jwt_required()
def get_dog(dog_id):
    current_user_id = get_jwt_identity()
    try:
        dog_uuid = uuid.UUID(dog_id)
    except ValueError:
        return jsonify({"message": "Invalid dog ID format"}), 400

    dog = Dog.query.filter_by(id=dog_uuid, user_id=current_user_id).first()
    if not dog:
        # Check if the dog exists at all, to differentiate between not found and not authorized
        if not Dog.query.get(dog_uuid):
             return jsonify({"message": "Dog not found"}), 404
        return jsonify({"message": "Unauthorized to view this dog"}), 403
        
    return jsonify(dog.to_dict()), 200

@bp.route("/dogs/<dog_id>", methods=["PUT"])
@jwt_required()
def update_dog(dog_id):
    current_user_id = get_jwt_identity()
    try:
        dog_uuid = uuid.UUID(dog_id)
    except ValueError:
        return jsonify({"message": "Invalid dog ID format"}), 400

    dog = Dog.query.filter_by(id=dog_uuid, user_id=current_user_id).first()
    if not dog:
        if not Dog.query.get(dog_uuid):
             return jsonify({"message": "Dog not found"}), 404
        return jsonify({"message": "Unauthorized to update this dog"}), 403

    data = request.get_json()
    dog.name = data.get("name", dog.name)
    dog.breed = data.get("breed", dog.breed)
    dog.age_years = data.get("age_years", dog.age_years)
    dog.size = data.get("size", dog.size)
    dog.temperament = data.get("temperament", dog.temperament)
    dog.profile_image_url = data.get("profile_image_url", dog.profile_image_url)
    
    db.session.commit()
    return jsonify(dog.to_dict()), 200

@bp.route("/dogs/<dog_id>", methods=["DELETE"])
@jwt_required()
def delete_dog(dog_id):
    current_user_id = get_jwt_identity()
    try:
        dog_uuid = uuid.UUID(dog_id)
    except ValueError:
        return jsonify({"message": "Invalid dog ID format"}), 400

    dog = Dog.query.filter_by(id=dog_uuid, user_id=current_user_id).first()
    if not dog:
        if not Dog.query.get(dog_uuid):
             return jsonify({"message": "Dog not found"}), 404
        return jsonify({"message": "Unauthorized to delete this dog"}), 403

    db.session.delete(dog)
    db.session.commit()
    return jsonify({"message": "Dog deleted successfully"}), 200

