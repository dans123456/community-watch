# Community Watch

A Flutter mobile final-year project for community insecurity reporting and monitoring.

## Setup

1. Install Flutter and Android Studio.
2. Create a Supabase project.
3. Open `supabase/schema.sql` in the Supabase SQL Editor and run it.
4. Create a Storage bucket named `report-images`.
5. Copy your Supabase project URL and anon key into `lib/config.dart`.
6. Run:
   flutter pub get
   flutter run

## Admin

Create a normal account first. Find its user UUID in Supabase Authentication, then run:

update profiles set role = 'admin' where id = 'YOUR-USER-UUID';

Log in again. The Admin Dashboard will then appear on the home screen.

## Important

The included RLS policies are a starting point for the project. Before production deployment, tighten admin policies using a secure database function/role check so clients cannot self-promote to admin.