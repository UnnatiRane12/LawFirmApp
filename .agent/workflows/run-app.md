---
description: how to run the Mercury Legal app
---

To run the Mercury Legal application, follow these steps:

### 1. Supabase Backend Setup
- Create a new project at [supabase.com](https://supabase.com).
- Open the "SQL Editor" in your Supabase dashboard.
- Copy the contents of the [schema.sql](file:///c:/Users/Unnati/.gemini/antigravity/brain/b16d7b60-e8e9-4ae3-bd23-7e3c175557c5/schema.sql) file and run it to create your tables.

### 2. Configure App Constants
- In your Supabase project settings, go to "API" and find your `Project URL` and `anon public` key.
- Update the following lines in your [constants.dart](file:///c:/Users/Unnati/ml/lib/utils/constants.dart) file:
  ```dart
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  ```

### 3. Install Dependencies
// turbo
- `flutter pub get`

### 4. Launch the App
- Ensure you have a device or emulator running.
- Execute:
  ```bash
  flutter run
  ```

### 5. Access Roles
- **Client**: Use the "Sign Up" button on the login screen.
- **Lawyer/Admin**: Since there is no public signup, you'll need to create your first Admin or Lawyer record manually in the Supabase `profiles` table to log in initially, or use the SQL editor to insert.
