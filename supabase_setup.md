# Supabase Setup for MotoTracker

## 1. Create a Supabase Project
1. Go to https://supabase.com and sign up
2. Create a new project 
3. Note down the project URL and API key (we'll need these later)

## 2. Database Schema
Execute the following SQL in the Supabase SQL Editor:

```sql
-- Create profiles table linked to Supabase auth
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  total_rides INTEGER DEFAULT 0,
  total_distance FLOAT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for viewing profiles
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

-- Create policy for users to update their own profile
CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Modify existing rides table to link with profiles
ALTER TABLE rides ADD COLUMN user_id UUID REFERENCES profiles(id);
ALTER TABLE rides ENABLE ROW LEVEL SECURITY;

-- Policies for rides
CREATE POLICY "Users can view their own rides" ON rides
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own rides" ON rides
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own rides" ON rides
  FOR UPDATE USING (auth.uid() = user_id);

-- Function to create profile after signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, avatar_url)
  VALUES (new.id, new.email, 'https://supabase.com/dashboard/img/avatars/avatar.png');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

## 3. Add Supabase to the iOS App
Add the Swift package:
```
https://github.com/supabase-community/supabase-swift.git
```

## 4. Configure MotoTracker to use Supabase
1. Create SupabaseManager.swift
2. Implement auth and profile management
3. Update ride saving/loading to use Supabase
