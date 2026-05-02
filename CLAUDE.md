# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Boo** is a Flutter-based pet service marketplace MVP targeting the Kenya market (Nairobi). It connects pet owners with service providers (boarding, grooming, sitting, veterinary). Pricing is in KSh.

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter run -d chrome    # Run on web
flutter analyze          # Static analysis / lint
flutter test             # Run tests
flutter build apk        # Build Android APK
```

## Architecture

### App Flows
Two distinct user roles with separate screen trees:
- **Pet Owner** — primary flow; uses `PetOwnerShell` (bottom nav with Home, Bookings, Chat, Profile tabs)
- **Pet Provider** — profile/service management screens

### Routing (`lib/main.dart`)
Named routes via `MaterialApp.routes` and `onGenerateRoute`:
- `/` → `PetOwnerShell`
- `/login` → `BooAuthScreen`
- `/provider-profile` → `ProviderProfileScreen` (receives `ProviderModel` as route argument)

### Screen Organization (`lib/screens/`)
- `auth.dart` — Login/signup UI (Supabase auth partially integrated, TODO items remain)
- `pet_owner_shell.dart` — Bottom nav container for owner tabs
- `pet_owner/` — Home dashboard, bookings (stub), chat (stub), profile
- `pet_provider/` — Provider listing, profile screen, recommendation card
- `services/utilities/calendar.dart` — Provider availability calendar (partial)

### Data Layer
- **Models** (`lib/models/provider_models.dart`): `ProviderModel`, `ServiceModel`, `ReviewModel`, `BookingRecord`, `ProviderType`, `BookingStatus` enums — in-memory for now
- **Demo data** lives in `ProviderDemoList` (hardcoded) and `_demoBookings` in `bookings_page.dart`
- **Database**: Supabase Postgres, accessed exclusively through the NestJS backend — Flutter never calls Supabase directly
- **No `supabase_flutter` package** — removed entirely

### Backend
- **NestJS** REST API, running at `http://10.0.2.2:3000` (Android emulator host) or a Render URL in production
- **Auth**: Custom JWT — `POST /auth/login`, `POST /auth/register`; tokens stored in `flutter_secure_storage`
- **HTTP client**: `lib/services/auth_service.dart` contains both `AuthService` (auth calls) and `ApiService` (generic authenticated GET/POST/PATCH/DELETE)

### State Management
Basic `setState` only — no state management library in use.

### UI/Theme
- Material 3 enabled
- Brand orange: `#F68B1F`
- Background: `#F6F7FB`

## Current Development Status

- **Auth**: Fully wired to NestJS JWT — login, register, token persistence, `_AuthGate` on startup
- **Booking flow UI**: Complete — `BookAppointmentScreen` (calendar + time slots), `BookingConfirmedScreen`, `BookingFailedScreen`; `_confirmBooking` currently simulates with a delay (no real API call yet)
- **Bookings page**: Upcoming/Past tab UI built; pulls from hardcoded `_demoBookings` — not wired to backend
- **Chat**: Placeholder screen only
- **Maps**: `google_maps_flutter` dependency added but not integrated
- **Calendar**: Custom calendar built into `BookAppointmentScreen`; `syncfusion_flutter_calendar` dependency still present but unused

Key TODOs: wire booking creation to NestJS, wire bookings list to real data, forgot-password flow, social login (Google/Apple), map view for providers.

## Auth TODOs (deferred, post-MVP)

These are stubbed in `lib/screens/auth.dart` and intentionally left for later:

- **Forgot password** (`auth.dart:189`) — button exists but navigates nowhere; needs a forgot-password screen + `POST /auth/forgot-password` backend endpoint
- **Google sign-in** (`auth.dart:257`) — button exists; needs OAuth flow wired through NestJS (not Supabase OAuth directly)
- **Apple sign-in** (`auth.dart:267`) — button exists; needed for iOS App Store compliance
- **Provider shell routing** (`auth.dart:540`) — `_PostAuthRedirect` always sends to `PetOwnerShell`; needs to route to `ProviderShell` when `role == 'provider'` (once provider shell is built)
