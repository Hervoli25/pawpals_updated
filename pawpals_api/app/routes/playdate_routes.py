from flask import Blueprint, request, jsonify
from app import db
from app.models.models import Playdate, Dog, User
from flask_jwt_extended import jwt_required, get_jwt_identity
import uuid
from datetime import datetime

bp = Blueprint("playdates", __name__)

@bp.route("/playdates", methods=["POST"])
@jwt_required()
def create_playdate():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404

    data = request.get_json()
    required_fields = ["dog1_id", "dog2_id", "requester_dog_id", "playdate_time"]
    if not all(field in data for field in required_fields):
        return jsonify({"message": "Missing required fields for playdate"}), 400

    try:
        dog1_uuid = uuid.UUID(data["dog1_id"])
        dog2_uuid = uuid.UUID(data["dog2_id"])
        requester_dog_uuid = uuid.UUID(data["requester_dog_id"])
        playdate_dt = datetime.fromisoformat(data["playdate_time"])
    except (ValueError, TypeError) as e:
        return jsonify({"message": f"Invalid ID or date format: {e}"}), 400

    if dog1_uuid == dog2_uuid:
        return jsonify({"message": "A dog cannot have a playdate with itself."}), 400

    # Check if dogs exist and if the current user owns the requester_dog_id
    dog1 = Dog.query.get(dog1_uuid)
    dog2 = Dog.query.get(dog2_uuid)
    requester_dog = Dog.query.get(requester_dog_uuid)

    if not dog1 or not dog2 or not requester_dog:
        return jsonify({"message": "One or more dogs not found"}), 404
    
    # Ensure the requester dog belongs to the current user
    if str(requester_dog.user_id) != current_user_id:
        return jsonify({"message": "Requester dog does not belong to the authenticated user"}), 403
    
    # Ensure one of the playdate dogs is the requester dog
    if requester_dog_uuid not in [dog1_uuid, dog2_uuid]:
         return jsonify({"message": "Requester dog must be one of the participants in the playdate"}), 400

    new_playdate = Playdate(
        dog1_id=dog1_uuid,
        dog2_id=dog2_uuid,
        requester_dog_id=requester_dog_uuid,
        playdate_time=playdate_dt,
        location_description=data.get("location_description"),
        location_latitude=data.get("location_latitude"),
        location_longitude=data.get("location_longitude"),
        status=data.get("status", "pending") # Default to pending
    )
    db.session.add(new_playdate)
    db.session.commit()
    return jsonify(new_playdate.to_dict()), 201

@bp.route("/playdates/user", methods=["GET"])
@jwt_required()
def get_user_playdates():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404

    # Get all dogs belonging to the user
    user_dog_ids = [dog.id for dog in user.dogs]
    if not user_dog_ids:
        return jsonify([]), 200 # No dogs, so no playdates

    # Find playdates where any of the user's dogs are dog1_id or dog2_id
    playdates = Playdate.query.filter(
        (Playdate.dog1_id.in_(user_dog_ids)) | (Playdate.dog2_id.in_(user_dog_ids))
    ).order_by(Playdate.playdate_time.desc()).all()
    
    return jsonify([playdate.to_dict() for playdate in playdates]), 200

@bp.route("/playdates/dog/<dog_id>", methods=["GET"])
@jwt_required()
def get_dog_playdates(dog_id):
    current_user_id = get_jwt_identity()
    try:
        dog_uuid = uuid.UUID(dog_id)
    except ValueError:
        return jsonify({"message": "Invalid dog ID format"}), 400

    dog = Dog.query.get(dog_uuid)
    if not dog:
        return jsonify({"message": "Dog not found"}), 404
    
    # Ensure the current user owns this dog to view its playdates
    if str(dog.user_id) != current_user_id:
        return jsonify({"message": "Unauthorized to view this dog's playdates"}), 403

    status_filter = request.args.get("status")
    query = Playdate.query.filter((Playdate.dog1_id == dog_uuid) | (Playdate.dog2_id == dog_uuid))

    if status_filter == "upcoming":
        query = query.filter(Playdate.playdate_time >= datetime.utcnow(), Playdate.status.in_(["pending", "accepted"]))
    elif status_filter:
        query = query.filter(Playdate.status == status_filter)
        
    playdates = query.order_by(Playdate.playdate_time.desc()).all()
    return jsonify([playdate.to_dict() for playdate in playdates]), 200

@bp.route("/playdates/<playdate_id>", methods=["GET"])
@jwt_required()
def get_playdate_details(playdate_id):
    current_user_id = get_jwt_identity()
    try:
        playdate_uuid = uuid.UUID(playdate_id)
    except ValueError:
        return jsonify({"message": "Invalid playdate ID format"}), 400

    playdate = Playdate.query.get(playdate_uuid)
    if not playdate:
        return jsonify({"message": "Playdate not found"}), 404

    # Check if the current user is involved in this playdate (owner of dog1 or dog2)
    dog1_owner_id = str(playdate.dog1.user_id)
    dog2_owner_id = str(playdate.dog2.user_id)

    if current_user_id not in [dog1_owner_id, dog2_owner_id]:
        return jsonify({"message": "Unauthorized to view this playdate"}), 403

    return jsonify(playdate.to_dict()), 200

@bp.route("/playdates/<playdate_id>/status", methods=["PATCH"])
@jwt_required()
def update_playdate_status(playdate_id):
    current_user_id = get_jwt_identity()
    try:
        playdate_uuid = uuid.UUID(playdate_id)
    except ValueError:
        return jsonify({"message": "Invalid playdate ID format"}), 400

    data = request.get_json()
    new_status = data.get("status")
    if not new_status or new_status not in ["accepted", "declined", "cancelled", "completed"]:
        return jsonify({"message": "Invalid or missing status"}), 400

    playdate = Playdate.query.get(playdate_uuid)
    if not playdate:
        return jsonify({"message": "Playdate not found"}), 404

    # Authorization: Only the owner of the non-requester dog can accept/decline a pending playdate.
    # Both involved users can cancel (if pending/accepted) or complete (if accepted).
    requester_dog_owner_id = str(playdate.requester_dog.user_id)
    dog1_owner_id = str(playdate.dog1.user_id)
    dog2_owner_id = str(playdate.dog2.user_id)
    
    is_involved = current_user_id in [dog1_owner_id, dog2_owner_id]
    if not is_involved:
        return jsonify({"message": "Unauthorized to update this playdate status"}), 403

    # Specific logic for status changes
    if playdate.status == "pending":
        if new_status == "accepted" or new_status == "declined":
            # Only the recipient (non-requester's owner) can accept/decline
            if current_user_id == requester_dog_owner_id:
                return jsonify({"message": "Requester cannot accept/decline their own request"}), 403
        elif new_status == "cancelled":
            pass # Either party can cancel a pending request
        else:
            return jsonify({"message": f"Cannot change status from pending to {new_status}"}), 400
    elif playdate.status == "accepted":
        if new_status == "cancelled" or new_status == "completed":
            pass # Either party can cancel or complete an accepted playdate
        else:
            return jsonify({"message": f"Cannot change status from accepted to {new_status}"}), 400
    elif playdate.status in ["declined", "cancelled", "completed"]:
         return jsonify({"message": f"Playdate is already {playdate.status} and cannot be changed"}), 400
    else:
        return jsonify({"message": "Invalid current playdate status for update"}), 400

    playdate.status = new_status
    db.session.commit()
    return jsonify(playdate.to_dict()), 200

@bp.route("/playdates/<playdate_id>", methods=["DELETE"])
@jwt_required()
def delete_playdate(playdate_id): # Typically, playdates might be cancelled rather than hard deleted by users
    current_user_id = get_jwt_identity()
    try:
        playdate_uuid = uuid.UUID(playdate_id)
    except ValueError:
        return jsonify({"message": "Invalid playdate ID format"}), 400

    playdate = Playdate.query.get(playdate_uuid)
    if not playdate:
        return jsonify({"message": "Playdate not found"}), 404

    # Authorization: e.g., only requester can delete if it's still pending, or admin only
    requester_dog_owner_id = str(playdate.requester_dog.user_id)
    if current_user_id != requester_dog_owner_id or playdate.status != "pending":
        # More complex auth might be needed, or this endpoint might be admin-only
        return jsonify({"message": "Unauthorized or playdate not in a deletable state"}), 403

    db.session.delete(playdate)
    db.session.commit()
    return jsonify({"message": "Playdate deleted successfully"}), 200

