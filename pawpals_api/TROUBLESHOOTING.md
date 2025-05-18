# PawPals API Troubleshooting Guide

This guide addresses common issues that may arise when setting up and running the PawPals API.

## Database Enum Type Issues

If you encounter errors related to enum types in PostgreSQL, such as:

```
invalid input value for enum dog_size_enum: "Medium"
```

This is because PostgreSQL enum types are case-sensitive, and the frontend is sending capitalized values ("Small", "Medium", "Large") while the database expects lowercase values ("small", "medium", "large").

### Solution:

1. Run the setup script to create the required enum types in PostgreSQL:

```bash
python setup_db.py
```

2. Restart your Flask application:

```bash
python run.py
```

The API now automatically converts the case of dog sizes to lowercase before storing them in the database.

## CORS Issues

If you encounter CORS errors when trying to access the API from the frontend, such as:

```
Access to fetch at 'http://localhost:5000/api/dogs' from origin 'http://localhost:44533' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

### Solution:

The CORS configuration has been updated to explicitly allow requests from the frontend origin. Make sure your frontend is running on one of the allowed origins (http://localhost:44533 or http://127.0.0.1:44533).

If you need to add additional origins, modify the CORS configuration in `app/__init__.py`:

```python
CORS(app, resources={r"/api/*": {"origins": ["http://localhost:44533", "http://127.0.0.1:44533", "your-additional-origin"]}}, supports_credentials=True)
```

## Database Connection Issues

If you encounter database connection errors:

1. Verify that PostgreSQL is running
2. Check your database connection string in `.env` or `config.py`
3. Make sure the database exists and is accessible

## API Endpoint Testing

You can test if the API is running correctly by accessing the health check endpoint:

```
http://localhost:5000/health
```

This should return "API is healthy!" if the API is running correctly.

## Common Error Messages and Solutions

### "Invalid dog ID format"
- Make sure you're passing a valid UUID for the dog ID

### "User not found"
- Verify that the user exists in the database
- Check that the JWT token is valid and contains the correct user ID

### "Dog not found"
- Verify that the dog exists in the database
- Check that the dog ID is correct

### "Unauthorized to view/update/delete this dog"
- Verify that the user has permission to access the dog
- Check that the user ID in the JWT token matches the dog's owner ID
