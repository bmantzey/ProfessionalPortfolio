# Professional Portfolio - Setup Instructions

## Firebase Configuration

This project uses Firebase for authentication and other services. To set up the project:

### 1. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Add an iOS app to your Firebase project
4. Download the `GoogleService-Info.plist` file
5. **IMPORTANT**: Copy the downloaded file to your project root as `GoogleService-Info.plist`
6. **DO NOT** commit this file to Git - it's already in `.gitignore`

### 2. Secure Configuration Setup

**Important**: Never commit your actual API keys to version control!

1. Create a `Secrets.xcconfig` file in the project root (this file is ignored by Git):
   ```
   GOOGLE_API_KEY = your_actual_api_key_here
   GOOGLE_CLIENT_ID = your_actual_client_id_here
   FIREBASE_PROJECT_ID = your_firebase_project_id
   GOOGLE_GCM_SENDER_ID = your_gcm_sender_id
   GOOGLE_APP_ID = your_google_app_id
   GOOGLE_REVERSED_CLIENT_ID = your_reversed_client_id
   ```

2. In Xcode, add the `Secrets.xcconfig` file to your project target:
   - Select your project in the navigator
   - Go to your target's "Build Settings"
   - Search for "Configuration Files"
   - Set `Secrets` for both Debug and Release configurations

3. Update your `Info.plist` to use these environment variables:
   ```xml
   <key>GOOGLE_API_KEY</key>
   <string>$(GOOGLE_API_KEY)</string>
   <key>GOOGLE_CLIENT_ID</key>
   <string>$(GOOGLE_CLIENT_ID)</string>
   <!-- etc. -->
   ```

### 3. Alternative: Environment-based GoogleService-Info.plist
Instead of hardcoded values, you can use the template file `GoogleService-Info-Template.plist` and rename it to `GoogleService-Info.plist`, then configure your build settings to populate the variables.

### 4. Verification
The app includes a `ConfigurationManager` that validates all required configuration values are present at runtime.

## Security Notes
- The `Secrets.xcconfig` file is in `.gitignore` and should never be committed
- The actual `GoogleService-Info.plist` with real values is in `.gitignore` and should never be committed
- Use the `GoogleService-Info-Template.plist` as a reference for the required structure
- Share configuration files securely with team members through encrypted channels
- Use different Firebase projects for development and production