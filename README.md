BaytarAPP 🐾
BaytarAPP is a comprehensive and modern mobile healthcare application that brings pet owners and veterinarians together on a digital platform. Developed with Flutter, it features advanced communication infrastructures such as real-time messaging and video calling.

🌟 Key Features
👤 User Roles
Pet Owner: Can register their pets to the system, request live support from veterinarians, send messages, and initiate video calls.
Veterinarian: Can view incoming live support requests, accept/reject them, chat instantly with pet owners, and initiate/answer video calls in emergency situations.
💬 Communication & Support
Live Messaging: Real-time, fast, and secure messaging powered by Firebase Firestore.
Video Calling (Agora RTC): High-quality, low-latency video calling using the Agora infrastructure. Features a fully comprehensive call flow (ringing/accepting/declining) that allows instant connection between the vet and the pet owner.
🛠 Technical Stack
Framework: Flutter
 (Dart)
State Management: Riverpod
 (In-app state management, reactive UIs, and Stream architecture)
Backend as a Service (BaaS): Firebase
Firebase Auth: Secure email and password authentication system.
Cloud Firestore: Real-time database for users, pets, chat messages, support requests, and call statuses.
Video Call: Agora RTC Engine
 (Fast P2P connection integrated with Testing Mode)
🚀 Installation and Setup
To run the project on your local machine, you can follow the steps below:

Prerequisites
Flutter SDK (Latest version recommended)
Android Studio / VS Code
A valid Agora App ID
Firebase Project (google-services.json file)
Setup Steps
Clone the Repository: git clone https://github.com/sacelikk/Veteriner_App.git
 cd Veteriner_App

Fetch Dependencies: flutter pub get

Agora and Firebase Configuration: Create your own Firebase project and add the necessary configuration file (google-services.json) to the android/app/ directory. Add your own Agora App ID to the appId variable inside the lib/features/chat/video_call_screen.dart file.

Run the Application: flutter run

📦 Building an APK
If you want to build a compiled version (APK) for Android, use the following commands in order: flutter clean flutter pub get flutter build apk

Once the build is complete, you can find your file in the build\app\outputs\flutter-apk\app-release.apk directory.

📱 Screenshots and Workflow
Live Support System: When a pet owner clicks the Request Support button, a request instantly appears on the veterinarian's screen.
Video Call Module: Clicking the camera icon on the messaging screen initiates a call. A custom Incoming Call dialog appears on the receiver's screen. When the call ends, the cameras turn off, and users seamlessly return to their chat screen.
🤝 Contributing
Contributions are welcome! If you'd like to contribute, you can open a Pull Request (PR) or report any issues you encounter in the Issues tab.

