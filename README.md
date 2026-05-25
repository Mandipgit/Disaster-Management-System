# Disaster 360: Disaster Management System

Disaster Management System is a Nepal-focused e-governance mobile application built using Flutter (frontend) and FastAPI (backend). It enables GPS-based disaster reporting, intelligent duplicate detection using cosine similarity, admin verification, rescue coordination, and offline/SMS support to enhance emergency response and public safety.

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites

*   **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
*   **Python 3.10+**: [Download Python](https://www.python.org/downloads/)
*   **PostgreSQL**: Ensure you have a running PostgreSQL instance.

---

## 🛠️ Backend Setup (FastAPI)

1.  **Navigate to the Backend directory**:
    ```bash
    cd Backend
    ```

2.  **Create a Virtual Environment**:
    ```bash
    python -m venv myenv
    ```

3.  **Activate the Virtual Environment**:
    *   **Windows**: `.\myenv\Scripts\activate`
    *   **Mac/Linux**: `source myenv/bin/activate`

4.  **Install Dependencies**:
    ```bash
    pip install -r ../requirements.txt
    ```

5.  **Configure Environment Variables**:
    *   Go to the **root directory** of the project.
    *   Copy `.env.example` to a new file named `.env`.
    *   Update the `DATABASE_URL` with your actual PostgreSQL credentials:
        ```env
        DATABASE_URL="postgresql://username:password@localhost:5432/disaster360_db"
        ```

6.  **Run the Backend**:
    ```bash
    uvicorn app.main2:app2 --reload
    ```
    The API will be available at `http://127.0.0.1:8000`.

---

## 📱 Frontend Setup (Flutter)

1.  **Navigate to the Frontend directory**:
    ```bash
    cd Frontend360
    ```

2.  **Install Flutter Packages**:
    ```bash
    flutter pub get
    ```

3.  **Configure Environment Variables**:
    *   Inside the `Frontend360` folder, copy `.env.example` to `.env`.
    *   Set the `API_BASE_URL` (use your local IP if testing on a physical device):
        ```env
        API_BASE_URL=http://127.0.0.1:8000
        ```

4.  **Run the Application**:
    ```bash
    flutter run
    ```

---

## 🚀 Running the Full Stack (VS Code)

If you are using Visual Studio Code, you don't need to manually open multiple terminals to run the frontend and backend separately. 

A custom VS Code Task is included to start both simultaneously in a split terminal:

1. Open VS Code.
2. Press `Ctrl + Shift + P` (or `Cmd + Shift + P` on Mac).
3. Type **Run Task** and press Enter.
4. Select **🔥 Run Everything 🔥**.

VS Code will automatically open two terminal panels side-by-side, activate the backend virtual environment, start the FastAPI server on `0.0.0.0`, and launch the Flutter app!

---

## 📁 Project Structure

*   `/Backend`: FastAPI source code, database models, and API routes.
*   `/Frontend360`: Flutter application source code.
*   `/.env`: Global configuration for the backend (Database URL).
*   `/Frontend360/.env`: Local configuration for the mobile app (API URL).

## 📝 License
This project is for educational purposes as part of a Final Year Project.
