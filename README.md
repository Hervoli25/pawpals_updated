# PawPals Application Setup Guide

This guide provides step-by-step instructions for setting up and running the PawPals application, which consists of a Flutter frontend and a Flask backend API with PostgreSQL database.

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Python](https://www.python.org/downloads/) (3.8 or newer)
- [PostgreSQL](https://www.postgresql.org/download/) (latest version)
- [Git](https://git-scm.com/downloads) (for version control)

## Repository Structure

```
pawpals_project/
├── pawpals/                  # Flutter frontend application
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── providers/        # Contains API service providers
│   │   ├── screens/
│   │   ├── utils/
│   │   └── widgets/
│   └── pubspec.yaml
│
└── pawpals_api/              # Flask backend API
    ├── app/
    │   ├── __init__.py
    │   ├── models/
    │   └── routes/
    ├── migrations/
    ├── .env                  # Environment variables (DB connection, etc.)
    ├── config.py
    ├── requirements.txt
    ├── run.py
    └── pawpals/              # Python virtual environment
```

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Hervoli25/pawpals_updated.git
cd pawpals_updated
```

### 2. Set Up the PostgreSQL Database

1. Create a new PostgreSQL database:
   ```sql
   CREATE DATABASE PawPalsDB;
   ```

2. Make note of your PostgreSQL credentials (username, password, host, port) for the next step.

### 3. Set Up the Flask Backend API

1. Navigate to the Flask API directory:
   ```bash
   cd pawpals_api
   ```

2. Create a virtual environment:
   ```bash
   python -m venv pawpals
   ```

3. Activate the virtual environment:
   - Windows:
     ```bash
     .\pawpals\Scripts\activate
     ```
   - macOS/Linux:
     ```bash
     source pawpals/bin/activate
     ```

4. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

5. Create or update the `.env` file with your PostgreSQL credentials:
   ```
   FLASK_APP=run.py
   FLASK_ENV=development
   FLASK_DEBUG=1
   DATABASE_URL="postgresql://postgres:your_password@localhost/PawPalsDB"
   SECRET_KEY="your_secret_key"
   JWT_SECRET_KEY="your_jwt_secret_key"
   NOMINATIM_USER_AGENT_EMAIL="your-email@example.com"
   ```
   Replace `your_password`, `your_secret_key`, `your_jwt_secret_key`, and `your-email@example.com` with your actual values.

6. Initialize the database:
   ```bash
   flask db init
   flask db migrate -m "Initial migration"
   flask db upgrade
   ```

### 4. Set Up the Flutter Frontend

1. Navigate to the Flutter app directory:
   ```bash
   cd ../pawpals
   ```

2. Get the Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Ensure the API base URL in `lib/utils/constants.dart` is correctly set to your Flask API URL (default is `http://localhost:5000/api`).

## Running the Application

### 1. Run the Flask Backend API

1. Navigate to the Flask API directory (if not already there):
   ```bash
   cd pawpals_api
   ```

2. Activate the virtual environment (if not already activated):
   - Windows:
     ```bash
     .\pawpals\Scripts\activate
     ```
   - macOS/Linux:
     ```bash
     source pawpals/bin/activate
     ```

3. Run the Flask application:
   ```bash
   python run.py
   ```

   The API should now be running at `http://localhost:5000`.

### 2. Run the Flutter Frontend

1. Open a new terminal window (keep the Flask API running in the first terminal).

2. Navigate to the Flutter app directory:
   ```bash
   cd pawpals
   ```

3. Run the Flutter application:
   ```bash
   flutter run
   ```

   If you have multiple devices connected, you'll be prompted to select one. Choose the device you want to run the app on.

   Alternatively, you can specify the device:
   ```bash
   flutter run -d chrome  # For web
   flutter run -d windows # For Windows desktop
   flutter run -d android # For Android device/emulator
   ```

## Verifying the Setup

1. The Flask API health check endpoint should be accessible at:
   ```
   http://localhost:5000/health
   ```
   It should return "API is healthy!" if everything is working correctly.

2. The Flutter app should connect to the API and display data if the backend is properly set up.

## Troubleshooting

### API Connection Issues

- Verify the Flask API is running (`http://localhost:5000/health` should return "API is healthy!")
- Check that the API base URL in the Flutter app is correctly set to `http://localhost:5000/api`
- Look for CORS errors in the browser console (if running on web)

### Database Issues

- Ensure PostgreSQL is running
- Verify the database connection string in `.env` is correct
- Check if the required tables exist in your database

### Flutter Issues

- Run `flutter doctor` to check for any Flutter configuration issues
- Try `flutter clean` followed by `flutter pub get` to refresh dependencies

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
