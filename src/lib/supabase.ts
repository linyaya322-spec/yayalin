import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export interface BlogPost {
  id: string;
  title: string;
  date: string;
  category: '生活隨筆' | '兒少議題' | '興趣分享';
  excerpt: string;
  body: string;
  cover_image: string | null;
  created_at: string;
}

export interface TimelineEntry {
  id: string;
  date: string;
  title: string;
  description: string;
  pdf_url: string | null;
  link_url: string | null;
  created_at: string;
}

export interface Quote {
  id: string;
  text: string;
  created_at: string;
}

export interface GuestbookMessage {
  id: string;
  name: string;
  message: string;
  is_approved: boolean;
  created_at: string;
}

export interface SitePage {
  slug: string;
  title: string;
  content: string;
  updated_at: string;
}

export interface ContactSubmission {
  id: string;
  name: string;
  email: string;
  message: string;
  created_at: string;
}
