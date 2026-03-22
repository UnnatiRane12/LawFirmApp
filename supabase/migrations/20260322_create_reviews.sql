-- Create reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(client_id, lawyer_id) -- One review per client per lawyer
);

-- Update lawyer_profiles table
ALTER TABLE public.lawyer_profiles 
ADD COLUMN IF NOT EXISTS average_rating FLOAT8 DEFAULT 0,
ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0;

-- Function to update lawyer rating
CREATE OR REPLACE FUNCTION public.update_lawyer_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE public.lawyer_profiles
        SET 
            average_rating = (SELECT AVG(rating)::FLOAT8 FROM public.reviews WHERE lawyer_id = NEW.lawyer_id),
            review_count = (SELECT COUNT(*) FROM public.reviews WHERE lawyer_id = NEW.lawyer_id)
        WHERE id = NEW.lawyer_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.lawyer_profiles
        SET 
            average_rating = COALESCE((SELECT AVG(rating)::FLOAT8 FROM public.reviews WHERE lawyer_id = OLD.lawyer_id), 0),
            review_count = (SELECT COUNT(*) FROM public.reviews WHERE lawyer_id = OLD.lawyer_id)
        WHERE id = OLD.lawyer_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automate rating calculation
DROP TRIGGER IF EXISTS tr_update_lawyer_rating ON public.reviews;
CREATE TRIGGER tr_update_lawyer_rating
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.update_lawyer_rating();

-- RLS Policies
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view reviews" 
ON public.reviews FOR SELECT 
USING (true);

CREATE POLICY "Clients can insert their own reviews" 
ON public.reviews FOR INSERT 
WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Clients can update their own reviews" 
ON public.reviews FOR UPDATE 
USING (auth.uid() = client_id);

CREATE POLICY "Clients can delete their own reviews" 
ON public.reviews FOR DELETE 
USING (auth.uid() = client_id);
