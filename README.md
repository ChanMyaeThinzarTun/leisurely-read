# Leisurely Read

A Flutter app for sharing and reading books with role-based access control, community features, and Firebase backend.

## Features

### 1️⃣ User Roles

- **Admin** (Single Account)
  - Cannot be created by users; one-time setup only
  - Full platform control
  
- **Writer**
  - Sign up with admin-provided code
  - Requires admin approval before uploading content
  - Can upload books and chapters
  
- **Reader**
  - Free signup
  - Browse and read books
  - Build personal library
  - Comment and vote on chapters

### 2️⃣ Admin Features

- **User Management**
  - Ban/unban users with customizable durations (1 day, 7 days, 30 days, 1 year)
  - Delete user accounts
  - View all users and their roles
  
- **Writer Management**
  - Approve or reject writer signups
  - View pending writer approvals
  
- **Content Management**
  - Delete books or individual chapters
  - View all books and their creators
  
- **Notifications**
  - Send notifications to specific users or all users
  - Choose notification type: warning, info, or alert
  
- **Settings**
  - Change password anytime

### 3️⃣ Writer Features

- **Account Management**
  - Sign up with writer approval code (Phase 1: `123456`)
  - Wait for admin approval
  - Change password anytime
  
- **Content Creation**
  - Upload books with title and cover image URL
  - Upload chapters with:
    - Chapter number
    - Title
    - Text content
    - Optional image URLs (placeholder for Phase 2)
  - Edit/delete chapters and books
  
- **Analytics** (Future)
  - View chapter read counts
  - See reader feedback

### 4️⃣ Reader Features

- **Browse & Read**
  - Browse all published books with cover images
  - Read chapters organized by chapter number
  - Beautiful chapter reading interface
  
- **Personal Library**
  - Add/remove books from personal library
  - Quick access to saved books
  - Long-press on a book to remove it
  
- **Community Features**
  - **Voting**: Thumbs up vote on chapters
  - **Comments**: Comment on specific chapters
  - **View engagement**: See vote counts and comments from other readers
  
- **Notifications**
  - Receive notifications from admin
  - Mark notifications as read
  - View unread notification count
  
- **Account Management**
  - Change password anytime

### 5️⃣ General Features

- **Authentication**
  - Firebase Auth integration
  - Email/password authentication
  - Session persistence
  
- **Real-time Updates**
  - Firestore-based real-time data sync
  - Automatic updates when content changes
  
- **Ban System**
  - Admins can ban users temporarily or indefinitely
  - Banned users cannot access the app
  - Ban status displayed with unban date
  
- **Pending Approval**
  - Writers see pending approval screen until admin approves
  - Cannot access writer features until approved

## Project Structure

```
lib/
├── main.dart                 # App entry point & routing
├── models/                   # Data models
│   ├── user_model.dart
│   ├── book_model.dart
│   ├── chapter_model.dart
│   ├── comment_model.dart
│   ├── notification_model.dart
│   └── vote_model.dart
├── services/                 # Business logic
│   ├── auth_service.dart     # Authentication
│   └── firestore_service.dart # Database operations
└── screens/                  # UI screens
    ├── login_screen.dart
    ├── signup_screen.dart
    ├── admin_dashboard.dart
    ├── writer_home.dart
    └── reader_home.dart
```

## Database Structure

### Collections

- **users**: User profiles with role and approval status
  - `uid`, `email`, `role`, `isApproved`, `bannedUntil`, `createdAt`

- **books**: Published books
  - `id`, `writerId`, `title`, `coverImageUrl`, `createdAt`, `updatedAt`

- **chapters**: Book chapters
  - `id`, `bookId`, `chapterNumber`, `title`, `content`, `imageUrls`, `createdAt`, `updatedAt`

- **comments**: Chapter comments
  - `id`, `bookId`, `chapterId`, `userId`, `message`, `createdAt`

- **votes**: Chapter votes/likes
  - `id`, `chapterId`, `userId`, `voteValue`, `createdAt`

- **notifications**: User notifications
  - `id`, `userId`, `title`, `message`, `type`, `read`, `createdAt`

- **library** (subcollection): Reader's personal library
  - `bookId`, `addedAt`

## Getting Started

### Prerequisites

- Flutter SDK (3.10.7+)
- Firebase project setup
- Android/iOS emulator or device

### Setup

1. **Clone repository**
   ```bash
   git clone <repo-url>
   cd leisurely_read
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create Firebase project
   - Add Android app and download `google-services.json`
   - Add iOS app and download `GoogleService-Info.plist`
   - Update `lib/firebase_options.dart` with your config

4. **Create Admin Account**
   - On first run, sign up with any email/password as admin
   - In Firestore, manually set the first user's role to "admin" (this enforces single admin)

5. **Run the app**
   ```bash
   flutter run
   ```

## Writer Signup Code

**Phase 1 Default Code**: `123456`

Change in `lib/services/auth_service.dart`:
```dart
static const String writerSignupCode = '123456';
```

## Future Enhancements (Phase 2)

- [ ] Firebase Storage for image uploads
- [ ] Markdown support for chapters
- [ ] Reading statistics and analytics
- [ ] Social features (follow writers, bookmarks)
- [ ] Search and filtering
- [ ] Dark mode support
- [ ] Push notifications
- [ ] Offline reading cache

## Testing Users

### Default Admin Setup
Create first account as admin, then manually set role in Firestore

### Test Writer
- Email: `writer@test.com`
- Password: `password123`
- Code: `123456`

### Test Reader
- Email: `reader@test.com`
- Password: `password123`
- No code needed

## Troubleshooting

**Issue**: Writer account stuck on pending approval
- **Solution**: Check Firestore → users collection → user document → verify `isApproved` field. Admin can approve from Admin Dashboard → Writers tab.

**Issue**: Cannot create books after writer approval
- **Solution**: Refresh app or log out and log back in to see updated role.

**Issue**: Images not showing
- **Solution**: Ensure image URLs are valid public URLs. Use placeholder URLs for Phase 1.

## Support

For issues or feature requests, please create an issue in the repository.

---

**Version**: 1.0.0  
**Last Updated**: January 2026  
**Author**: Leisurely Read Team
