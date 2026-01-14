# Troubleshooting Login & Signup Issues

## Issue 1: "Cannot Sign In with Admin Account"

### Root Cause
Admin account needs to be created in **Firebase Console**, not in the app.

### Solution

#### Step 1: Create in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **leisurely-read**
3. Click **Authentication** in left menu
4. Click **Users** tab
5. Click **+ Create user** button
6. Enter:
   - **Email**: `admin.leisurelyread@gmail.com`
   - **Password**: (your password)
7. Click **Create user**

#### Step 2: Set Role in Firestore
1. Click **Firestore Database** in left menu
2. Click **Data** tab
3. Click **users** collection
4. Find document matching your admin UID
5. Click the document
6. Edit the `role` field: change to `"admin"`
7. Click **Update**

Document should look like:
```
uid: "YOUR_UID"
email: "admin.leisurelyread@gmail.com"
role: "admin"  ← Change this to "admin"
isApproved: true
bannedUntil: null
createdAt: timestamp
```

#### Step 3: Now Try Login in App
- **Email**: `admin.leisurelyread@gmail.com`
- **Password**: (the password from Firebase Console)

---

## Issue 2: "Cannot Create User Account in App"

### Possible Causes

#### A. Password Too Short
**Error**: "Password must be at least 6 characters"
- **Fix**: Enter password with 6+ characters

#### B. Passwords Don't Match
**Error**: "Passwords do not match"
- **Fix**: Make sure confirm password matches exactly

#### C. Empty Email
**Error**: "Please enter an email"
- **Fix**: Enter valid email (e.g., user@example.com)

#### D. Writer Code Missing
**Error**: "Please enter the writer signup code"
- **Fix**: For Writer signup, enter code: `123456`

#### E. Email Already Exists
**Error**: "The email address is already in use by another account"
- **Fix**: Use a different email address

#### F. Invalid Email Format
**Error**: "Invalid email format"
- **Fix**: Use format like: `yourname@example.com`

#### G. Firebase Connection Issue
**Error**: "Network error" or no response
- **Fix**: 
  - Check internet connection
  - Verify Firebase project ID in `firebase_options.dart`
  - Check that Firebase is initialized before signup

### Debugging Steps

1. **Check Console Logs**
   - Look at the terminal/console output from Flutter
   - It will show detailed error messages

2. **Verify Input**
   - Email: Must be valid email format
   - Password: Must be 6+ characters
   - Confirm: Must match password exactly
   - Writer Code (if writer): Must be `123456`

3. **Check Network**
   - Make sure you have internet connection
   - Firebase needs to communicate with backend

---

## Issue 3: "Successfully Signed Up But Can't Login"

### Root Cause
Firestore document wasn't created or role is missing.

### Check Firestore
1. Go to [Firestore Console](https://console.firebase.google.com/)
2. Select project
3. Click **Firestore Database**
4. Click **Data** tab
5. Click **users** collection
6. Look for your email in the list

### If Document Exists
- Verify these fields:
  - `email`: correct email
  - `role`: should be "reader" or "writer"
  - `isApproved`: should be true (for reader) or false (for writer)

### If Document Missing
- **Try again**: Go back to signup and try again
- **Check errors**: Look at console for specific errors
- **Check quota**: Firebase may have limits on free tier

---

## Common Error Messages & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "user-not-found" | Email not registered in Firebase Auth | Sign up first |
| "wrong-password" | Password is incorrect | Double-check password |
| "invalid-email" | Email format is wrong | Use valid email (name@domain.com) |
| "email-already-in-use" | This email already has account | Use different email |
| "weak-password" | Password less than 6 characters | Use 6+ character password |
| "too-many-requests" | Too many failed attempts | Wait 5-10 minutes then retry |
| "network-request-failed" | No internet connection | Check WiFi/mobile connection |
| "Invalid writer signup code" | Wrong code entered | Use exactly: `123456` |
| "Passwords do not match" | Confirm password different | Make sure they're identical |

---

## Quick Verification Checklist

### Before Trying to Login
- [ ] Firebase Auth user created in Console
- [ ] Firestore document exists with correct role
- [ ] Email is correct
- [ ] Password is correct (6+ characters)
- [ ] You have internet connection

### Before Trying to Sign Up
- [ ] Email is valid format (name@domain.com)
- [ ] Password is 6+ characters
- [ ] Confirm password matches
- [ ] If Writer: code is exactly `123456`
- [ ] You have internet connection

### After Successful Signup
- [ ] Document appears in Firestore users collection
- [ ] Email in document matches what you entered
- [ ] Role field is set correctly
- [ ] isApproved field is correct (true for reader, false for writer)

---

## Reset Everything (If Needed)

1. **Delete all Firestore documents**
   - Go to Firestore Database
   - Right-click each collection → Delete collection
   - Confirm deletion

2. **Delete users from Firebase Auth**
   - Go to Authentication → Users
   - Click menu (•••) on each user → Delete user

3. **Start over from Step 1** of "Create in Firebase Console" above

---

## Still Having Issues?

1. **Check Flutter Console Output**
   - Look for error messages
   - Copy full error text

2. **Verify Firebase Config**
   - File: `lib/firebase_options.dart`
   - Project ID: `leisurely-read`
   - API Keys should match Firebase Console

3. **Restart App**
   - Stop Flutter: Press `q` in terminal
   - Run again: `flutter run`

4. **Check Firebase Rules** (if needed)
   - Go to Firestore Database → Rules
   - Make sure set to test mode or proper rules

---

**Last Updated**: January 14, 2026
