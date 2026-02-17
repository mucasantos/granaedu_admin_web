-- Create books table
CREATE TABLE IF NOT EXISTS public.books (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    level TEXT CHECK (level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
    content TEXT, -- Full text content or description
    cover_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on books
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read books (Global Library)
DROP POLICY IF EXISTS "Allow public read access" ON public.books;
CREATE POLICY "Allow public read access" ON public.books
    FOR SELECT
    USING (true);

-- Policy: Only admins/teachers can insert/update (simplified for now, allows authenticated)
DROP POLICY IF EXISTS "Allow authenticated insert" ON public.books;
CREATE POLICY "Allow authenticated insert" ON public.books
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated update" ON public.books;
CREATE POLICY "Allow authenticated update" ON public.books
    FOR UPDATE
    TO authenticated
    USING (true);


-- Create class_books junction table
CREATE TABLE IF NOT EXISTS public.class_books (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    class_id UUID NOT NULL, -- Assumes classes table exists or will be created. NOT enforcing FK strict constraint yet to avoid breakage if classes table is missing in this context, but ideally should be: REFERENCES public.classes(id) ON DELETE CASCADE
    book_id UUID NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(class_id, book_id)
);

-- Enable RLS on class_books
ALTER TABLE public.class_books ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can read (Teachers/Students)
DROP POLICY IF EXISTS "Allow authenticated read class_books" ON public.class_books;
CREATE POLICY "Allow authenticated read class_books" ON public.class_books
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Teachers can assign books
DROP POLICY IF EXISTS "Allow authenticated insert class_books" ON public.class_books;
CREATE POLICY "Allow authenticated insert class_books" ON public.class_books
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy: Teachers can unassign books
DROP POLICY IF EXISTS "Allow authenticated delete class_books" ON public.class_books;
CREATE POLICY "Allow authenticated delete class_books" ON public.class_books
    FOR DELETE
    TO authenticated
    USING (true);

-- Seed initial data (Classic Public Domain Books)
INSERT INTO public.books (title, author, level, content, cover_url)
VALUES 
    ('Alice''s Adventures in Wonderland', 'Lewis Carroll', 'B1', 'Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do...', 'https://books.google.com/books/content?id=3s0CAAAAQAAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    ('The Adventures of Sherlock Holmes', 'Arthur Conan Doyle', 'B2', 'To Sherlock Holmes she is always THE woman. I have seldom heard him mention her under any other name.', 'https://books.google.com/books/content?id=7s0CAAAAQAAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    ('Dracula', 'Bram Stoker', 'C1', '3 May. Bistritz.—Left Munich at 8:35 P.M., on 1st May, arriving at Vienna early next morning.', 'https://books.google.com/books/content?id=8s0CAAAAQAAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    ('The Little Prince', 'Antoine de Saint-Exupéry', 'A2', 'Once when I was six years old I saw a magnificent picture in a book, called True Stories from Nature, about the primeval forest.', 'https://books.google.com/books/content?id=9s0CAAAAQAAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api'),
    ('Pride and Prejudice', 'Jane Austen', 'C2', 'It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.', 'https://books.google.com/books/content?id=As0CAAAAQAAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api')
ON CONFLICT DO NOTHING;
