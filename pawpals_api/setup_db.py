"""
Script to set up the PostgreSQL database with required enum types.
Run this script after creating the database but before running Flask migrations.
"""

import os
import psycopg2
from dotenv import load_dotenv
from config import Config

# Load environment variables
load_dotenv()

# Get database connection string from environment or config
db_url = os.environ.get("DATABASE_URL") or Config.SQLALCHEMY_DATABASE_URI

# Parse the database URL to get connection parameters
# Format: postgresql://username:password@host:port/dbname
if db_url.startswith("postgresql://"):
    db_url = db_url.replace("postgresql://", "")
    credentials, rest = db_url.split("@", 1)
    if ":" in credentials:
        username, password = credentials.split(":", 1)
    else:
        username, password = credentials, ""
    
    host_port, dbname = rest.split("/", 1)
    if ":" in host_port:
        host, port = host_port.split(":", 1)
    else:
        host, port = host_port, "5432"
else:
    print("Invalid database URL format. Expected: postgresql://username:password@host:port/dbname")
    exit(1)

# SQL commands to create enum types
sql_commands = """
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
"""

def setup_database():
    """Connect to the database and execute the SQL commands."""
    try:
        # Connect to the database
        conn = psycopg2.connect(
            dbname=dbname,
            user=username,
            password=password,
            host=host,
            port=port
        )
        conn.autocommit = True
        
        # Create a cursor
        cursor = conn.cursor()
        
        # Execute the SQL commands
        cursor.execute(sql_commands)
        
        # Close the cursor and connection
        cursor.close()
        conn.close()
        
        print("Database setup completed successfully!")
        return True
    except Exception as e:
        print(f"Error setting up database: {e}")
        return False

if __name__ == "__main__":
    setup_database()
