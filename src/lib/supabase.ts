import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.PUBLIC_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export interface BlogPost {
  id: string;
  title: string;
  date: string;
  category: '生活隨筆' | '兒少議題' | '興趣分享' | '茶葉蛋';
  excerpt: string;
  body: string;
  cover_image: string | null;
  tags: string[];
  created_at: string;
}

export interface TimelineEntry {
  id: string;
  date: string;
  title: string;
  description: string;
  pdf_url: string | null;
  link_url: string | null;
  status: string | null;
  government_response: string | null;
  created_at: string;
}

export interface Quote {
  id: string;
  text: string;
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

export interface StudentSuggestion {
  id: string;
  message: string;
  school: string | null;
  grade: string | null;
  contact_name: string | null;
  contact_email: string | null;
  attachment_paths: string[] | null;
  admin_reply: string | null;
  reply_status: 'pending' | 'sent' | null;
  reply_sent_at: string | null;
  created_at: string;
}

export interface AppSetting {
  key: string;
  value: string;
}

export interface SurveyOption {
  id: string;
  text: string;
  correct: boolean;
  isOther?: boolean;
  goto?: string | null;
}

export interface Survey {
  id: string;
  title: string;
  description: string;
  is_active: boolean;
  theme: 'clay' | 'sage' | 'butter' | 'ink';
  link_url: string | null;
  pdf_url: string | null;
  opens_at: string | null;
  closes_at: string | null;
  access_mode: 'public' | 'gmail_whitelist' | 'qr_code' | 'password';
  access_password: string | null;
  access_password_expires_at: string | null;
  qr_token: string | null;
  qr_token_expires_at: string | null;
  created_at: string;
}

export interface SurveyAllowedEmail {
  id: string;
  survey_id: string;
  email: string;
  max_submissions: number;
  used_count: number;
  created_at: string;
}

export interface SurveyQuestion {
  id: string;
  survey_id: string;
  position: number;
  question_text: string;
  type: 'text' | 'single' | 'multiple';
  required: boolean;
  options: SurveyOption[];
  created_at: string;
}

export interface SurveyResponse {
  id: string;
  survey_id: string;
  answers: Record<string, string | string[]>;
  respondent_email: string | null;
  submitted_at: string;
}

export interface SurveyProgress {
  id: string;
  survey_id: string;
  furthest_position: number;
  status: 'in_progress' | 'submitted' | 'closed';
  started_at: string;
  updated_at: string;
}

export interface NewsletterSubscriber {
  id: string;
  email: string;
  unsubscribe_token: string;
  subscribed_at: string;
  unsubscribed_at: string | null;
}

export interface Newsletter {
  id: string;
  subject: string;
  content: string;
  status: 'draft' | 'sending' | 'sent';
  sent_at: string | null;
  recipient_count: number | null;
  target_emails: string[] | null;
  created_at: string;
}
