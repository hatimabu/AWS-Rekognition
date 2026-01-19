-- ===========================================
-- Rekognition Database - SQL Learning Project
-- ===========================================
-- This SQL file demonstrates database design for an image analysis application
-- using AWS Rekognition. It covers essential SQL concepts including:
-- • Database design and relationships
-- • CRUD operations (Create, Read, Update, Delete)
-- • JOINs and aggregations
-- • Data filtering and sorting

-- ===========================================
-- 1. DATABASE SETUP
-- ===========================================

-- Create the database
CREATE DATABASE IF NOT EXISTS rekognition_db;
USE rekognition_db;

-- ===========================================
-- 2. TABLE CREATION (Database Schema)
-- ===========================================

-- Users table - stores information about application users
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Images table - stores metadata about uploaded images
CREATE TABLE images (
    image_id INT PRIMARY KEY AUTO_INCREMENT,
    filename VARCHAR(255) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,  -- S3 object key
    uploaded_by INT NOT NULL,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    file_size_bytes INT,
    image_width INT,
    image_height INT,
    content_type VARCHAR(50),
    FOREIGN KEY (uploaded_by) REFERENCES users(user_id)
);

-- Analysis results table - stores Rekognition analysis results
CREATE TABLE analysis_results (
    analysis_id INT PRIMARY KEY AUTO_INCREMENT,
    image_id INT NOT NULL,
    analysis_type VARCHAR(50) NOT NULL,  -- 'LABELS', 'OBJECTS', 'TEXT', 'FACES'
    confidence_score DECIMAL(5,2),  -- 0.00 to 100.00
    analyzed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processing_time_ms INT,
    FOREIGN KEY (image_id) REFERENCES images(image_id)
);

-- Detected labels table - stores labels detected in images
CREATE TABLE detected_labels (
    label_id INT PRIMARY KEY AUTO_INCREMENT,
    analysis_id INT NOT NULL,
    label_name VARCHAR(100) NOT NULL,
    confidence DECIMAL(5,2) NOT NULL,
    parent_label VARCHAR(100),  -- For hierarchical labels
    FOREIGN KEY (analysis_id) REFERENCES analysis_results(analysis_id)
);

-- Detected objects table - stores objects detected in images
CREATE TABLE detected_objects (
    object_id INT PRIMARY KEY AUTO_INCREMENT,
    analysis_id INT NOT NULL,
    object_name VARCHAR(100) NOT NULL,
    confidence DECIMAL(5,2) NOT NULL,
    bounding_box_x DECIMAL(5,4),  -- Normalized coordinates (0.0 to 1.0)
    bounding_box_y DECIMAL(5,4),
    bounding_box_width DECIMAL(5,4),
    bounding_box_height DECIMAL(5,4),
    FOREIGN KEY (analysis_id) REFERENCES analysis_results(analysis_id)
);

-- ===========================================
-- 3. SAMPLE DATA INSERTION
-- ===========================================

-- Insert sample users
INSERT INTO users (username, email) VALUES
('john_doe', 'john@example.com'),
('alice_smith', 'alice@example.com'),
('bob_wilson', 'bob@example.com');

-- Insert sample images
INSERT INTO images (filename, s3_key, uploaded_by, file_size_bytes, image_width, image_height, content_type) VALUES
('beach_sunset.jpg', 'images/beach_sunset.jpg', 1, 2048576, 1920, 1080, 'image/jpeg'),
('city_street.png', 'images/city_street.png', 2, 1536000, 1280, 720, 'image/png'),
('mountain_landscape.jpg', 'images/mountain_landscape.jpg', 1, 3145728, 2560, 1440, 'image/jpeg'),
('office_meeting.jpg', 'images/office_meeting.jpg', 3, 1048576, 1024, 768, 'image/jpeg');

-- Insert analysis results
INSERT INTO analysis_results (image_id, analysis_type, confidence_score, processing_time_ms) VALUES
(1, 'LABELS', 95.50, 1250),
(1, 'OBJECTS', 92.30, 980),
(2, 'LABELS', 97.80, 1100),
(2, 'OBJECTS', 89.40, 920),
(3, 'LABELS', 96.20, 1350),
(4, 'LABELS', 94.10, 1050);

-- Insert detected labels
INSERT INTO detected_labels (analysis_id, label_name, confidence, parent_label) VALUES
(1, 'Beach', 98.5, 'Nature'),
(1, 'Sunset', 95.2, 'Nature'),
(1, 'Ocean', 92.8, 'Nature'),
(1, 'Sky', 89.3, 'Nature'),
(3, 'City', 97.1, 'Urban'),
(3, 'Street', 94.7, 'Urban'),
(3, 'Building', 91.2, 'Urban'),
(3, 'Car', 88.9, 'Transportation'),
(5, 'Mountain', 99.2, 'Nature'),
(5, 'Landscape', 96.8, 'Nature'),
(5, 'Snow', 93.5, 'Nature');

-- Insert detected objects
INSERT INTO detected_objects (analysis_id, object_name, confidence, bounding_box_x, bounding_box_y, bounding_box_width, bounding_box_height) VALUES
(2, 'Person', 87.3, 0.1234, 0.2345, 0.3456, 0.4567),
(2, 'Umbrella', 78.9, 0.4567, 0.5678, 0.1234, 0.2345),
(4, 'Car', 92.1, 0.2345, 0.3456, 0.4567, 0.1234),
(4, 'Building', 85.7, 0.5678, 0.6789, 0.2345, 0.3456),
(4, 'Tree', 76.4, 0.7890, 0.8901, 0.1234, 0.2345);

-- ===========================================
-- 4. BASIC SELECT QUERIES (Reading Data)
-- ===========================================

-- View all users
SELECT * FROM users;

-- View all images with uploader information
SELECT i.image_id, i.filename, u.username, i.upload_date, i.file_size_bytes
FROM images i
JOIN users u ON i.uploaded_by = u.user_id;

-- View analysis results for a specific image
SELECT ar.analysis_id, ar.analysis_type, ar.confidence_score, ar.analyzed_at
FROM analysis_results ar
WHERE ar.image_id = 1;

-- ===========================================
-- 5. FILTERING AND SORTING
-- ===========================================

-- Find images uploaded by a specific user
SELECT filename, upload_date, file_size_bytes
FROM images
WHERE uploaded_by = 1
ORDER BY upload_date DESC;

-- Find high-confidence analysis results (>90%)
SELECT ar.analysis_id, i.filename, ar.analysis_type, ar.confidence_score
FROM analysis_results ar
JOIN images i ON ar.image_id = i.image_id
WHERE ar.confidence_score > 90.00
ORDER BY ar.confidence_score DESC;

-- Find images containing specific labels
SELECT DISTINCT i.filename, dl.label_name, dl.confidence
FROM images i
JOIN analysis_results ar ON i.image_id = ar.image_id
JOIN detected_labels dl ON ar.analysis_id = dl.analysis_id
WHERE dl.label_name LIKE '%Beach%'
ORDER BY dl.confidence DESC;

-- ===========================================
-- 6. AGGREGATION QUERIES
-- ===========================================

-- Count total images per user
SELECT u.username, COUNT(i.image_id) as total_images
FROM users u
LEFT JOIN images i ON u.user_id = i.uploaded_by
GROUP BY u.user_id, u.username
ORDER BY total_images DESC;

-- Average confidence scores by analysis type
SELECT analysis_type, AVG(confidence_score) as avg_confidence, COUNT(*) as total_analyses
FROM analysis_results
GROUP BY analysis_type
ORDER BY avg_confidence DESC;

-- Most common labels detected
SELECT label_name, COUNT(*) as frequency, AVG(confidence) as avg_confidence
FROM detected_labels
GROUP BY label_name
HAVING COUNT(*) > 1
ORDER BY frequency DESC;

-- ===========================================
-- 7. JOINS (Combining Data from Multiple Tables)
-- ===========================================

-- Get complete analysis report for an image
SELECT
    i.filename,
    ar.analysis_type,
    ar.confidence_score,
    dl.label_name,
    dl.confidence as label_confidence,
    do.object_name,
    do.confidence as object_confidence
FROM images i
LEFT JOIN analysis_results ar ON i.image_id = ar.image_id
LEFT JOIN detected_labels dl ON ar.analysis_id = dl.analysis_id
LEFT JOIN detected_objects do ON ar.analysis_id = do.analysis_id
WHERE i.image_id = 1;

-- Find users and their analysis statistics
SELECT
    u.username,
    COUNT(DISTINCT i.image_id) as images_uploaded,
    COUNT(ar.analysis_id) as analyses_performed,
    AVG(ar.confidence_score) as avg_analysis_confidence
FROM users u
LEFT JOIN images i ON u.user_id = i.uploaded_by
LEFT JOIN analysis_results ar ON i.image_id = ar.image_id
GROUP BY u.user_id, u.username;

-- ===========================================
-- 8. SUBQUERIES
-- ===========================================

-- Find images with above-average file sizes
SELECT filename, file_size_bytes
FROM images
WHERE file_size_bytes > (SELECT AVG(file_size_bytes) FROM images);

-- Find users who have uploaded more images than the average user
SELECT username, COUNT(i.image_id) as image_count
FROM users u
JOIN images i ON u.user_id = i.uploaded_by
GROUP BY u.user_id, u.username
HAVING COUNT(i.image_id) > (
    SELECT AVG(image_count)
    FROM (
        SELECT COUNT(image_id) as image_count
        FROM images
        GROUP BY uploaded_by
    ) as user_counts
);

-- ===========================================
-- 9. UPDATE OPERATIONS
-- ===========================================

-- Update user email
UPDATE users
SET email = 'john.doe@example.com'
WHERE user_id = 1;

-- Update analysis confidence score (simulating improved analysis)
UPDATE analysis_results
SET confidence_score = confidence_score + 1.00
WHERE confidence_score < 95.00;

-- ===========================================
-- 10. DELETE OPERATIONS
-- ===========================================

-- Delete a specific detected label (be careful with foreign keys!)
DELETE FROM detected_labels
WHERE label_id = 5;

-- Delete analysis results for a specific image (cascade effect)
DELETE FROM detected_objects
WHERE analysis_id IN (
    SELECT analysis_id FROM analysis_results WHERE image_id = 4
);

DELETE FROM detected_labels
WHERE analysis_id IN (
    SELECT analysis_id FROM analysis_results WHERE image_id = 4
);

DELETE FROM analysis_results
WHERE image_id = 4;

-- ===========================================
-- 11. ADVANCED QUERIES
-- ===========================================

-- Find images with multiple high-confidence objects
SELECT
    i.filename,
    COUNT(do.object_id) as object_count,
    AVG(do.confidence) as avg_object_confidence
FROM images i
JOIN analysis_results ar ON i.image_id = ar.image_id
JOIN detected_objects do ON ar.analysis_id = do.analysis_id
WHERE do.confidence > 80.00
GROUP BY i.image_id, i.filename
HAVING COUNT(do.object_id) >= 2
ORDER BY object_count DESC;

-- Analysis performance report
SELECT
    ar.analysis_type,
    COUNT(*) as total_analyses,
    AVG(ar.processing_time_ms) as avg_processing_time,
    MIN(ar.confidence_score) as min_confidence,
    MAX(ar.confidence_score) as max_confidence,
    AVG(ar.confidence_score) as avg_confidence
FROM analysis_results ar
GROUP BY ar.analysis_type
ORDER BY avg_processing_time DESC;

-- ===========================================
-- 12. INDEXES (For Performance - Optional)
-- ===========================================

-- Create indexes for better query performance
CREATE INDEX idx_images_uploaded_by ON images(uploaded_by);
CREATE INDEX idx_analysis_results_image_id ON analysis_results(image_id);
CREATE INDEX idx_detected_labels_analysis_id ON detected_labels(analysis_id);
CREATE INDEX idx_detected_objects_analysis_id ON detected_objects(analysis_id);
CREATE INDEX idx_detected_labels_name ON detected_labels(label_name);

-- ===========================================
-- 13. VIEWS (Virtual Tables - Optional)
-- ===========================================

-- Create a view for easy image analysis summary
CREATE VIEW image_analysis_summary AS
SELECT
    i.image_id,
    i.filename,
    u.username as uploader,
    i.upload_date,
    COUNT(DISTINCT ar.analysis_id) as analysis_count,
    AVG(ar.confidence_score) as avg_confidence,
    COUNT(dl.label_id) as label_count,
    COUNT(do.object_id) as object_count
FROM images i
JOIN users u ON i.uploaded_by = u.user_id
LEFT JOIN analysis_results ar ON i.image_id = ar.image_id
LEFT JOIN detected_labels dl ON ar.analysis_id = dl.analysis_id
LEFT JOIN detected_objects do ON ar.analysis_id = do.analysis_id
GROUP BY i.image_id, i.filename, u.username, i.upload_date;

-- Query the view
SELECT * FROM image_analysis_summary ORDER BY upload_date DESC;

-- ===========================================
-- LEARNING EXERCISES TO TRY:
-- ===========================================
--
-- 1. Basic Queries:
--    - List all images uploaded by 'alice_smith'
--    - Find the most recently uploaded image
--    - Count how many labels were detected with >90% confidence
--
-- 2. JOIN Practice:
--    - Show all analysis results with image filenames and uploader names
--    - Find objects detected in images uploaded by 'john_doe'
--
-- 3. Aggregation:
--    - Calculate the average file size of images per user
--    - Find the analysis type with the highest average confidence
--
-- 4. Advanced:
--    - Create a report showing the top 3 most common objects detected
--    - Find images that have both 'Car' and 'Building' detected
--    - Calculate processing time statistics by analysis type
--
-- 5. Data Modification:
--    - Add a new user and upload an image for them
--    - Update confidence scores for all 'LABELS' analyses
--    - Remove all analysis results for images uploaded before a certain date