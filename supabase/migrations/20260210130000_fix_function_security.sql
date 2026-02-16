-- Migration: Fix Function Search Path Security
-- Date: 2026-02-10

-- These functions likely exist in your remote database.
-- Setting an explicit search_path is a security best practice for Postgres functions.

-- Fix for public.update_chat_session_timestamp
ALTER FUNCTION public.update_chat_session_timestamp() SET search_path = public;

-- Fix for public.handle_new_user
ALTER FUNCTION public.handle_new_user() SET search_path = public;
