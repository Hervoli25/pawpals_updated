from app import db
from werkzeug.security import generate_password_hash, check_password_hash
import uuid # For generating UUIDs if not handled by DB default directly in model
from sqlalchemy.dialects.postgresql import UUID, ARRAY, JSONB

# Enum Types (mirroring PostgreSQL ENUMs, can be handled by SQLAlchemy if needed or validated at app level)
# For simplicity, we'll use string fields and validate them in routes or services if not using SQLAlchemy-Utils for ENUMs.

class User(db.Model):
    __tablename__ = "users"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = db.Column(db.String(255), nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.Text, nullable=False)
    location_latitude = db.Column(db.Float, nullable=True)
    location_longitude = db.Column(db.Float, nullable=True)
    profile_image_url = db.Column(db.String(2048), nullable=True)
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    dogs = db.relationship("Dog", backref="owner", lazy="dynamic", cascade="all, delete-orphan")
    # Relationship for places added by user
    added_places = db.relationship("Place", backref="adder", lazy="dynamic", foreign_keys="Place.added_by_user_id")

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "id": str(self.id),
            "name": self.name,
            "email": self.email,
            "location_latitude": self.location_latitude,
            "location_longitude": self.location_longitude,
            "profile_image_url": self.profile_image_url,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }

class Dog(db.Model):
    __tablename__ = "dogs"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = db.Column(UUID(as_uuid=True), db.ForeignKey("users.id"), nullable=False, index=True)
    name = db.Column(db.String(255), nullable=False)
    breed = db.Column(db.String(100), nullable=True)
    age_years = db.Column(db.Integer, nullable=True)
    size = db.Column(db.String(50), nullable=True)  # Corresponds to dog_size_enum
    temperament = db.Column(ARRAY(db.Text), nullable=True)
    profile_image_url = db.Column(db.String(2048), nullable=True)
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    # Relationships for playdates
    playdates_as_dog1 = db.relationship("Playdate", foreign_keys="Playdate.dog1_id", backref="dog1", lazy="dynamic", cascade="all, delete-orphan")
    playdates_as_dog2 = db.relationship("Playdate", foreign_keys="Playdate.dog2_id", backref="dog2", lazy="dynamic", cascade="all, delete-orphan")
    playdates_requested = db.relationship("Playdate", foreign_keys="Playdate.requester_dog_id", backref="requester_dog", lazy="dynamic")

    def to_dict(self):
        return {
            "id": str(self.id),
            "user_id": str(self.user_id),
            "name": self.name,
            "breed": self.breed,
            "age_years": self.age_years,
            "size": self.size,
            "temperament": self.temperament if self.temperament else [],
            "profile_image_url": self.profile_image_url,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }

class Place(db.Model):
    __tablename__ = "places"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = db.Column(db.String(255), nullable=False)
    type = db.Column(db.String(50), nullable=False, index=True) # Corresponds to place_type_enum
    address_street = db.Column(db.String(255), nullable=True)
    address_city = db.Column(db.String(100), nullable=True)
    address_state_province = db.Column(db.String(100), nullable=True)
    address_postal_code = db.Column(db.String(20), nullable=True)
    address_country = db.Column(db.String(100), nullable=True)
    location_latitude = db.Column(db.Float, nullable=False)
    location_longitude = db.Column(db.Float, nullable=False)
    description = db.Column(db.Text, nullable=True)
    rating = db.Column(db.Numeric(2, 1), nullable=True)
    phone_number = db.Column(db.String(30), nullable=True)
    website_url = db.Column(db.String(2048), nullable=True)
    hours_of_operation = db.Column(JSONB, nullable=True)
    images_urls = db.Column(ARRAY(db.Text), nullable=True)
    added_by_user_id = db.Column(UUID(as_uuid=True), db.ForeignKey("users.id"), nullable=True)
    is_verified = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    # If using PostGIS, you would add a Geometry column here
    # geom = db.Column(Geometry(geometry_type='POINT', srid=4326), nullable=True)
    def to_dict(self):
        return {
            "id": str(self.id),
            "name": self.name,
            "type": self.type,
            "address_street": self.address_street,
            "address_city": self.address_city,
            "address_state_province": self.address_state_province,
            "address_postal_code": self.address_postal_code,
            "address_country": self.address_country,
            "location_latitude": self.location_latitude,
            "location_longitude": self.location_longitude,
            "description": self.description,
            "rating": float(self.rating) if self.rating is not None else None,
            "phone_number": self.phone_number,
            "website_url": self.website_url,
            "hours_of_operation": self.hours_of_operation,
            "images_urls": self.images_urls if self.images_urls else [],
            "added_by_user_id": str(self.added_by_user_id) if self.added_by_user_id else None,
            "is_verified": self.is_verified,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }

class Playdate(db.Model):
    __tablename__ = "playdates"
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dog1_id = db.Column(UUID(as_uuid=True), db.ForeignKey("dogs.id"), nullable=False, index=True)
    dog2_id = db.Column(UUID(as_uuid=True), db.ForeignKey("dogs.id"), nullable=False, index=True)
    requester_dog_id = db.Column(UUID(as_uuid=True), db.ForeignKey("dogs.id"), nullable=False)
    playdate_time = db.Column(db.DateTime, nullable=False)
    location_description = db.Column(db.Text, nullable=True)
    location_latitude = db.Column(db.Float, nullable=True)
    location_longitude = db.Column(db.Float, nullable=True)
    status = db.Column(db.String(50), default="pending", nullable=False, index=True) # Corresponds to playdate_status_enum
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    __table_args__ = (db.CheckConstraint("dog1_id != dog2_id", name="check_different_dogs_in_playdate"),)

    def to_dict(self):
        return {
            "id": str(self.id),
            "dog1_id": str(self.dog1_id),
            "dog2_id": str(self.dog2_id),
            "requester_dog_id": str(self.requester_dog_id),
            "playdate_time": self.playdate_time.isoformat() if self.playdate_time else None,
            "location_description": self.location_description,
            "location_latitude": self.location_latitude,
            "location_longitude": self.location_longitude,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }

