from flask import Blueprint, request, jsonify
from app import db
from app.models.models import Place, User
from flask_jwt_extended import jwt_required, get_jwt_identity
import uuid
import requests # For Nominatim
from sqlalchemy import func # For ST_DWithin if using PostGIS

bp = Blueprint("places", __name__)

# Helper function to geocode address using Nominatim (example)
def geocode_address_nominatim(street, city, postal_code, country):
    # This is a very basic example. Robust geocoding requires error handling, rate limiting awareness, etc.
    # Consider using a dedicated geocoding library or service for production.
    query = f"{street}, {postal_code} {city}, {country}"
    # It is CRUCIAL to set a custom User-Agent for Nominatim requests
    headers = {"User-Agent": "PawPalsApp/1.0 (your-email@example.com)"} # REPLACE with actual app info
    params = {"q": query, "format": "json", "limit": 1}
    try:
        response = requests.get("https://nominatim.openstreetmap.org/search", params=params, headers=headers)
        response.raise_for_status() # Raise an exception for HTTP errors
        data = response.json()
        if data:
            return float(data[0]["lat"]), float(data[0]["lon"])
    except requests.exceptions.RequestException as e:
        print(f"Nominatim API request failed: {e}")
    except (KeyError, IndexError, ValueError) as e:
        print(f"Error parsing Nominatim response: {e}")
    return None, None

@bp.route("/places", methods=["POST"])
@jwt_required()
def create_place():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"message": "User not found"}), 404

    data = request.get_json()
    if not data or not data.get("name") or not data.get("type"):
        return jsonify({"message": "Place name and type are required"}), 400

    latitude = data.get("location_latitude")
    longitude = data.get("location_longitude")

    # If lat/lon not provided, try to geocode from address (if address parts are present)
    if not latitude or not longitude:
        if data.get("address_street") and data.get("address_city") and data.get("address_country"):
            lat, lon = geocode_address_nominatim(
                data.get("address_street", ""),
                data.get("address_city", ""),
                data.get("address_postal_code", ""),
                data.get("address_country", "")
            )
            if lat and lon:
                latitude = lat
                longitude = lon
            else:
                # Optionally, you could make geocoding mandatory or handle this error differently
                print("Geocoding failed for place, coordinates will be null or place creation might fail if coords are mandatory")
        # If still no lat/lon and they are mandatory by your schema, return error
        # For now, assuming they can be null if not geocoded and not provided directly

    new_place = Place(
        name=data["name"],
        type=data["type"],
        address_street=data.get("address_street"),
        address_city=data.get("address_city"),
        address_state_province=data.get("address_state_province"),
        address_postal_code=data.get("address_postal_code"),
        address_country=data.get("address_country"),
        location_latitude=latitude,
        location_longitude=longitude,
        description=data.get("description"),
        rating=data.get("rating"),
        phone_number=data.get("phone_number"),
        website_url=data.get("website_url"),
        hours_of_operation=data.get("hours_of_operation"), # Expects JSON
        images_urls=data.get("images_urls"), # Expects a list of strings
        added_by_user_id=user.id,
        is_verified=False # New places added by users are not verified by default
    )
    # If using PostGIS: new_place.geom = f"SRID=4326;POINT({longitude} {latitude})"

    db.session.add(new_place)
    db.session.commit()
    return jsonify(new_place.to_dict()), 201

@bp.route("/places", methods=["GET"])
def get_places(): # Publicly accessible, or add @jwt_required() if needed
    # Add pagination, filtering by type, etc.
    category = request.args.get("category")
    query = Place.query
    if category:
        query = query.filter_by(type=category)
    
    # Simple pagination example
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 10, type=int)
    places_page = query.paginate(page=page, per_page=per_page, error_out=False)
    
    places_data = [place.to_dict() for place in places_page.items]
    return jsonify({
        "places": places_data,
        "total_pages": places_page.pages,
        "current_page": places_page.page,
        "total_items": places_page.total
    }), 200

@bp.route("/places/nearby", methods=["GET"])
def get_nearby_places():
    try:
        lat = float(request.args.get("latitude"))
        lon = float(request.args.get("longitude"))
        radius_km = float(request.args.get("radius", 10)) # Default 10km radius
    except (TypeError, ValueError):
        return jsonify({"message": "Invalid latitude, longitude, or radius parameters"}), 400

    category = request.args.get("category")

    # Earth radius in kilometers
    earth_radius_km = 6371
    # Convert radius from km to degrees (approximate)
    # 1 degree latitude is approx 111 km. For longitude, it varies.
    # A more accurate way is to use ST_DWithin with PostGIS or Haversine formula.
    # For simplicity with basic SQL, we use an approximate bounding box or a simpler distance calc.
    
    # Approximate bounding box (less accurate for larger distances or near poles)
    # lat_diff = radius_km / 111.0
    # lon_diff = radius_km / (111.0 * func.cos(func.radians(lat)))
    # query = Place.query.filter(
    #     Place.location_latitude.between(lat - lat_diff, lat + lat_diff),
    #     Place.location_longitude.between(lon - lon_diff, lon + lon_diff)
    # )

    # Using Haversine formula in SQL (more complex to write directly in SQLAlchemy without specific DB functions)
    # For PostgreSQL with PostGIS, you would use ST_DWithin:
    # query = Place.query.filter(func.ST_DWithin(
    #     Place.geom, # Assuming geom is a Geography type column
    #     func.ST_MakePoint(lon, lat).cast(Geography()),
    #     radius_km * 1000 # ST_DWithin expects meters
    # ))
    # If not using PostGIS, you might have to fetch more results and filter in Python, or use a complex SQL expression.

    # Simplified approach: fetch all and filter in Python (NOT EFFICIENT FOR LARGE DATASETS)
    # This is just a placeholder for a proper geospatial query.
    # In a real app, use PostGIS ST_DWithin or a similar geospatial index query.
    all_places = Place.query
    if category:
        all_places = all_places.filter_by(type=category)
    all_places = all_places.all()

    nearby_places_list = []
    for place in all_places:
        if place.location_latitude is not None and place.location_longitude is not None:
            # Haversine distance calculation (example)
            R = 6371  # Radius of Earth in kilometers
            dLat = func.radians(place.location_latitude - lat)
            dLon = func.radians(place.location_longitude - lon)
            a = (func.sin(dLat / 2) * func.sin(dLat / 2) +
                 func.cos(func.radians(lat)) * func.cos(func.radians(place.location_latitude)) *
                 func.sin(dLon / 2) * func.sin(dLon / 2))
            c = 2 * func.atan2(func.sqrt(a), func.sqrt(1 - a))
            distance = R * c
            # This distance calculation is symbolic here, needs to be executed by DB or in Python
            # For Python calculation:
            import math
            lat1_rad = math.radians(lat)
            lon1_rad = math.radians(lon)
            lat2_rad = math.radians(place.location_latitude)
            lon2_rad = math.radians(place.location_longitude)
            dlon = lon2_rad - lon1_rad
            dlat = lat2_rad - lat1_rad
            a_py = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
            c_py = 2 * math.atan2(math.sqrt(a_py), math.sqrt(1 - a_py))
            distance_py = R * c_py
            if distance_py <= radius_km:
                nearby_places_list.append(place.to_dict())
    
    return jsonify(nearby_places_list), 200

@bp.route("/places/<place_id>", methods=["GET"])
def get_place_details(place_id):
    try:
        place_uuid = uuid.UUID(place_id)
    except ValueError:
        return jsonify({"message": "Invalid place ID format"}), 400

    place = Place.query.get(place_uuid)
    if not place:
        return jsonify({"message": "Place not found"}), 404
    return jsonify(place.to_dict()), 200

@bp.route("/places/<place_id>", methods=["PUT"])
@jwt_required() # Or admin only
def update_place(place_id):
    current_user_id = get_jwt_identity()
    # Add logic to check if user is admin or owner of the place if applicable
    try:
        place_uuid = uuid.UUID(place_id)
    except ValueError:
        return jsonify({"message": "Invalid place ID format"}), 400

    place = Place.query.get(place_uuid)
    if not place:
        return jsonify({"message": "Place not found"}), 404
    
    # Authorization check: only adder or admin can update?
    # if str(place.added_by_user_id) != current_user_id and not User.query.get(current_user_id).is_admin:
    #     return jsonify({"message": "Unauthorized"}), 403

    data = request.get_json()
    place.name = data.get("name", place.name)
    place.type = data.get("type", place.type)
    place.address_street=data.get("address_street", place.address_street)
    place.address_city=data.get("address_city", place.address_city)
    place.address_state_province=data.get("address_state_province", place.address_state_province)
    place.address_postal_code=data.get("address_postal_code", place.address_postal_code)
    place.address_country=data.get("address_country", place.address_country)
    place.location_latitude=data.get("location_latitude", place.location_latitude)
    place.location_longitude=data.get("location_longitude", place.location_longitude)
    place.description=data.get("description", place.description)
    place.rating=data.get("rating", place.rating)
    place.phone_number=data.get("phone_number", place.phone_number)
    place.website_url=data.get("website_url", place.website_url)
    place.hours_of_operation=data.get("hours_of_operation", place.hours_of_operation)
    place.images_urls=data.get("images_urls", place.images_urls)
    place.is_verified=data.get("is_verified", place.is_verified) # Admin might change this

    db.session.commit()
    return jsonify(place.to_dict()), 200

@bp.route("/places/<place_id>", methods=["DELETE"])
@jwt_required() # Or admin only
def delete_place(place_id):
    current_user_id = get_jwt_identity()
    # Add logic to check if user is admin or owner of the place
    try:
        place_uuid = uuid.UUID(place_id)
    except ValueError:
        return jsonify({"message": "Invalid place ID format"}), 400

    place = Place.query.get(place_uuid)
    if not place:
        return jsonify({"message": "Place not found"}), 404

    # Authorization check
    # if str(place.added_by_user_id) != current_user_id and not User.query.get(current_user_id).is_admin:
    #     return jsonify({"message": "Unauthorized"}), 403

    db.session.delete(place)
    db.session.commit()
    return jsonify({"message": "Place deleted successfully"}), 200

