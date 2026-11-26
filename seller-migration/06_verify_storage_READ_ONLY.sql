-- ============================================================================
-- 06_verify_storage_READ_ONLY.sql
-- ============================================================================
-- TARGET : Run on BOTH projects (OLD = read only, NEW = read only) and
--          compare. Purpose: prove the product-images bucket, its settings,
--          its security policies and — after the file copy — its file count
--          all match.
-- SAFETY : ONLY SELECT statements. Safe everywhere.
--
-- HOW TO RUN: SQL Editor -> paste -> Run -> save as STORAGE-OLD.txt and
--             STORAGE-NEW.txt -> compare.
-- NOTE   : Run on the NEW project only AFTER Phase 8 (bucket creation) and
--          Phase 9 (file copy) — the file_count comparison is the proof
--          that every image made it across.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- A) Bucket configuration.
--    Expect in BOTH: bucket "product-images", public = true,
--    file_size_limit = 10485760 (10 MB),
--    allowed_mime_types = image/jpeg, image/png, image/webp, image/gif.
-- ---------------------------------------------------------------------------
select id as bucket_name,
       public as is_public,
       file_size_limit,
       allowed_mime_types,
       created_at
from storage.buckets
order by id;

-- ---------------------------------------------------------------------------
-- B) File counts per bucket — THE number that must match after copying.
--    Expect: product-images file_count identical in OLD and NEW.
--    Any other bucket listed (for example a KYC bucket used by the Render
--    backend) is OUT of this migration's scope — note it, decide in
--    Phase 13 whether it also needs copying.
-- ---------------------------------------------------------------------------
select bucket_id,
       count(*) as file_count,
       count(*) filter (where name like '%/%') as files_in_subfolders
from storage.objects
group by bucket_id
order by bucket_id;

-- ---------------------------------------------------------------------------
-- C) Largest files (helps judge whether the manual upload path is feasible).
--    Expect: everything under 10 MB (the bucket limit).
-- ---------------------------------------------------------------------------
select bucket_id,
       name as file_path,
       (metadata->>'size') as size_bytes,
       metadata->>'mimetype' as mime_type
from storage.objects
where bucket_id = 'product-images'
order by (metadata->>'size')::bigint desc
limit 20;

-- ---------------------------------------------------------------------------
-- D) Storage security policies (who may read/upload/delete).
--    Expect: 3 policies in BOTH projects, scoped to bucket_id =
--    'product-images': public read, anyone upload, anyone delete.
-- ---------------------------------------------------------------------------
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
order by policyname;

-- ============================================================================
-- END of 06_verify_storage_READ_ONLY.sql  (run on BOTH, compare)
-- ============================================================================
