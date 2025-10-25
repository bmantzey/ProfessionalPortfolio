# Professional Portfolio - Setup Instructions

## Firebase Configuration

This project uses Firebase for authentication and other services. To set up the project:

### 1. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Add an iOS app to your Firebase project
4. Download the `GoogleService-Info.plist` file
5. **IMPORTANT**: Add the downloaded file to your Xcode project
6. **DO NOT** commit this file to Git - it's already in `.gitignore`

### 2. Project Structure

**Files you need locally:**
- `GoogleService-Info.plist` - The actual Firebase configuration file (NOT committed to Git)

**Files that are committed to Git:**
- `GoogleService-Info-Template.plist` - Safe template showing the required structure
- `ConfigurationManager.swift` - Handles Firebase configuration validation

### 3. Security Notes
- The actual `GoogleService-Info.plist` with real values is in `.gitignore` and should never be committed
- Use the `GoogleService-Info-Template.plist` as a reference for the required structure
- Firebase will automatically read configuration from `GoogleService-Info.plist`
- The app includes a `ConfigurationManager` that validates Firebase configuration at runtime
- Use different Firebase projects for development and production

### 4. Team Setup
When sharing this project:
1. Share the actual `GoogleService-Info.plist` file securely (encrypted email, etc.)
2. New team members should add their copy to the project root
3. The template file shows what the structure should look like