-- SQL script to create or update the required enum types for PawPals

-- Drop existing enum types if they exist (for re-running the script)
DROP TYPE IF EXISTS dog_size_enum CASCADE;
DROP TYPE IF EXISTS place_type_enum CASCADE;
DROP TYPE IF EXISTS playdate_status_enum CASCADE;

-- Create dog size enum
CREATE TYPE dog_size_enum AS ENUM ('small', 'medium', 'large');

-- Create place type enum
CREATE TYPE place_type_enum AS ENUM (
    'park',
    'cafe',
    'hotel',
    'beach',
    'restaurant',
    'store',
    'other'
);

-- Create playdate status enum
CREATE TYPE playdate_status_enum AS ENUM (
    'pending',
    'accepted',
    'declined',
    'canceled'
);

-- Comment on the enum types for documentation
COMMENT ON TYPE dog_size_enum IS 'Valid dog sizes: small, medium, large';
COMMENT ON TYPE place_type_enum IS 'Valid place types: park, cafe, hotel, beach, restaurant, store, other';
COMMENT ON TYPE playdate_status_enum IS 'Valid playdate statuses: pending, accepted, declined, canceled';
