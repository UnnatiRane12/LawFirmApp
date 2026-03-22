-- Add performance tracking to cases
ALTER TABLE public.cases 
ADD COLUMN IF NOT EXISTS is_won BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ DEFAULT NULL;

-- Index for performance queries
CREATE INDEX IF NOT EXISTS idx_cases_lawyer_performance ON public.cases(lawyer_id, status, is_won);
