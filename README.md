This project implements a facial recognition pipeline for a building's security system. It analyzes images captured by a front-door camera, processing up to 500 employee scans daily. Using Amazon Rekognition, the system detects faces in images uploaded to S3. If a face is recognized, the results are stored in DynamoDB, and a notification is sent via SNS to authorize security to unlock the door, allowing employees to enter the building and begin work.
 
 ---

![alt text](image.png)
source:https://tutorialsdojo.com/5-best-cloud-projects-for-beginners/

---

# Services:

- Amazon S3
- AWS Lambda
- Amazon Rekognition
- Amazon DynamoDB
- Amazon SNS

---

# 📊 SQL Database Learning Component

This project includes a comprehensive SQL learning database (`rekognition_database.sql`) designed specifically for students learning SQL concepts while building skills relevant to image analysis applications.

## 🗄️ Database Schema

The SQL file creates a relational database with the following tables:
- **`users`** - Application user information
- **`images`** - Image metadata and S3 storage details
- **`analysis_results`** - Rekognition analysis results (labels, objects, faces)
- **`detected_labels`** - Labels/tags detected in images
- **`detected_objects`** - Objects detected with bounding box coordinates

## 🎓 SQL Concepts Covered

### Basic Operations
- **CRUD Operations**: CREATE, READ, UPDATE, DELETE
- **Table Relationships**: Foreign keys and data normalization
- **Data Types**: VARCHAR, INT, DECIMAL, TIMESTAMP, BOOLEAN

### Query Techniques
- **JOINs**: INNER JOIN, LEFT JOIN for multi-table queries
- **Filtering**: WHERE clauses, LIKE operators, range queries
- **Sorting**: ORDER BY with ASC/DESC
- **Aggregation**: COUNT, AVG, MIN, MAX, GROUP BY, HAVING

### Advanced Concepts
- **Subqueries**: Nested SELECT statements
- **Views**: Virtual tables for complex queries
- **Indexes**: Performance optimization
- **Sample Data**: Realistic test data for practice

## 🚀 How to Use

### Option 1: Online SQL Playground
```bash
# Use any online SQL editor like:
# - SQLFiddle (sqlfiddle.com)
# - DB-Fiddle (db-fiddle.com)
# - SQLite Online (sqliteonline.com)
```

### Option 2: Local Database Setup
```bash
# Install MySQL/PostgreSQL/SQLite locally
# Run the SQL file to create database and sample data
mysql -u root -p < rekognition_database.sql
```

### Option 3: Database IDE
```bash
# Use tools like:
# - MySQL Workbench
# - pgAdmin (for PostgreSQL)
# - DBeaver (universal)
# - VS Code SQL extensions
```

## 📝 Learning Exercises

The file includes 25+ practical exercises covering:

### Beginner Level
- List all users and their uploaded images
- Find high-confidence analysis results (>90%)
- Count images per user

### Intermediate Level
- Join tables to show complete analysis reports
- Calculate average confidence scores by analysis type
- Find most common detected labels

### Advanced Level
- Create reports with subqueries
- Build summary views
- Analyze performance statistics

## 💡 Example Queries

```sql
-- Find all beach-related images
SELECT DISTINCT i.filename, dl.label_name, dl.confidence
FROM images i
JOIN analysis_results ar ON i.image_id = ar.image_id
JOIN detected_labels dl ON ar.analysis_id = dl.analysis_id
WHERE dl.label_name LIKE '%Beach%'
ORDER BY dl.confidence DESC;

-- User activity report
SELECT u.username,
       COUNT(i.image_id) as images_uploaded,
       AVG(ar.confidence_score) as avg_confidence
FROM users u
LEFT JOIN images i ON u.user_id = i.uploaded_by
LEFT JOIN analysis_results ar ON i.image_id = ar.image_id
GROUP BY u.user_id, u.username;
```

## 🎯 Why This Database?

- **Relevant**: Uses real-world image analysis concepts
- **Progressive**: From basic to advanced SQL concepts
- **Practical**: Includes sample data and exercises
- **Educational**: Clear comments explaining each concept
- **Comprehensive**: Covers essential SQL skills for developers

This SQL learning component complements your AWS Rekognition project by teaching database design and querying skills that would be valuable for scaling your image analysis application with persistent storage.

---

# zone 

US East (Ohio) - us-east-2

---

# Architecture Workflow

## ✳️ Image Upload (S3)

+ A user uploads an image from their computer into an Amazon S3 bucket.

+ The bucket is configured with event notifications so that whenever a new image is uploaded, it automatically triggers the AWS Lambda function.

### 💰 *S3 pricing*
S3 Standard - General purpose storage for any type of data, typically used for frequently accessed data	
First 50 TB / Month	$0.023 per GB

##### Requests & data retrievals 
- PUT, COPY, POST, LIST requests $0.005/per 1,000 requests
- GET, SELECT, and all other request $0.0004/per 1,000 requests
###### TOTAL
- 1️⃣ S3 Storage

15,000 images × 0.5 MB = 7,500 MB = 7.5 GB stored per month.
Pricing (S3 Standard): $0.023 per GB
Cost: 7.5 × $0.023 = $0.1725 ≈ $0.18 per month

- 2️⃣ S3 Requests

PUT (uploads) = 15,000 / 1,000 × $0.005 = $0.075
GET (retrieval by Rekognition) = 15,000 / 1,000 × $0.0004 = $0.006
Total = $0.081 ≈ $0.08 per month

---

## 🧮 Processing (Lambda + Rekognition)

+ Lambda function is invoked when the new object (image) is created in S3.

```hcl
import boto3
import json
from decimal import Decimal

rekognition = boto3.client('rekognition', region_name='us-east-2')
dynamodb = boto3.resource('dynamodb', region_name='us-east-2')
sns = boto3.client('sns', region_name='us-east-2')

DYNAMO_TABLE = 'FaceMetadata'
SNS_TOPIC_ARN = 'arn:aws:sns:us-east-2:094092120892:FaceDetectedTopic'
REKOGNITION_COLLECTION = 'employeeFaces'

def lambda_handler(event, context):
    try:
        record = event['Records'][0]
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        print(f"Processing image: {key} from bucket: {bucket}")

        # Step 1: Detect faces
        response = rekognition.detect_faces(
            Image={'S3Object': {'Bucket': bucket, 'Name': key}},
            Attributes=['ALL']
        )

        face_details = response.get('FaceDetails', [])
        if not face_details:
            print("No face detected.")
            return {'statusCode': 200, 'body': 'No face detected.'}

        face = face_details[0]
        print("Face detected. Writing to DynamoDB...")

        # Step 2: Write to DynamoDB
        table = dynamodb.Table(DYNAMO_TABLE)
        table.put_item(Item={
            'FaceId': key,
            'AgeRange': {
                'Low': Decimal(str(face['AgeRange']['Low'])),
                'High': Decimal(str(face['AgeRange']['High']))
            },
            'Gender': {
                'Value': face['Gender']['Value'],
                'Confidence': Decimal(str(face['Gender']['Confidence']))
            },
            'Emotions': [
                {
                    'Type': e['Type'],
                    'Confidence': Decimal(str(e['Confidence']))
                } for e in face['Emotions']
            ]
        })

        # Step 3: Search for face match
        match_response = rekognition.search_faces_by_image(
            CollectionId=REKOGNITION_COLLECTION,
            Image={'S3Object': {'Bucket': bucket, 'Name': key}},
            MaxFaces=1,
            FaceMatchThreshold=90
        )

        matches = match_response.get('FaceMatches', [])
        match_info = matches[0]['Face']['ExternalImageId'] if matches else 'No match found'
        print(f"Match result: {match_info}")

        # Step 4: Publish to SNS
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=f"Face detected in image: {key}\nMatch result: {match_info}",
            Subject="Face Recognition Alert"
        )
        print("SNS notification sent.")

        return {'statusCode': 200, 'body': f'Face processed. Match result: {match_info}'}

    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}
```

### 💰 *lambda pricing*
 The Lambda free tier includes 1M free requests per month and 400,000 GB-seconds of compute time per month.

+ Inside the Lambda function, you call Amazon Rekognition.

+ Rekognition analyzes the uploaded image and checks whether it contains faces.

### 💰 *Rekognition pricing*
Group 1 AssociateFaces First 1 million images $0.001
- workload: 500/day × 30 days = 15,000 images/month.
- 15,000 × $0.001 = $15.00/month (ignoring any free-tier credits).

---

## Decision Making & Notifications

The system sends SNS notifications for **ALL scenarios**:

### 1. No Face Detected
+ **Notification**: Sent immediately
+ **Subject**: "🚫 Face Recognition Alert - No Face Detected"
+ **Action**: Access denied, door remains locked

### 2. Face Detected - Matched Employee
+ **Notification**: Sent with employee details
+ **Subject**: "✅ Face Recognition - Authorized Access"
+ **Action**: Door unlocked, employee authorized to enter
+ **Data Stored**: Employee ID, match confidence, face metadata

### 3. Face Detected - Unmatched (Unknown Person)
+ **Notification**: Sent immediately (⚠️ **SECURITY ALERT**)
+ **Subject**: "🚫 Face Recognition - Unauthorized Access Attempt"
+ **Action**: Door remains locked, security notified
+ **Data Stored**: Face metadata for investigation

### 4. Processing Error
+ **Notification**: Sent if any error occurs
+ **Subject**: "❌ Face Recognition - Processing Error"
+ **Action**: Requires manual investigation

### DynamoDB Storage
+ The Lambda function writes metadata to DynamoDB for all processed images:
  - Match status (MATCHED/UNMATCHED)
  - Employee ID (if matched)
  - Match confidence score
  - Face attributes (age, gender, emotions)
  - Processing timestamp

### 💰 *DynamoDB pricing* 
DynamoDB Standard table class > On-Demand Throughput Type
DynamoDB Monthly Cost Estimate
500 uploads/day × 30 days = 15,000 writes/month
- Writes = ~$0.02
- Reads = ~$0.003 (depends on usage)
- Storage = ~$0.004
- Total ≈ $0.03/month
---

## Notification Examples

### Matched Employee (Authorized)
```
✅ AUTHORIZED ACCESS - Employee Recognized

Image: employee_photo.jpg
Bucket: rekognition-upload-bucket1
Employee ID: EMP001
Match Confidence: 95.50%
Status: MATCHED

Action: Door should be UNLOCKED. Employee is authorized to enter.
```

### Unmatched Face (Unauthorized)
```
🚫 UNAUTHORIZED ACCESS - Unknown Person

Image: unknown_person.jpg
Bucket: rekognition-upload-bucket1
Status: UNMATCHED
Match Result: No matching employee found in database

Action: Door should remain LOCKED. Unauthorized access attempt detected.
Security should be notified immediately.
```

### No Face Detected
```
Image Processing Result

Image: invalid_image.jpg
Status: No face detected

The uploaded image does not contain any detectable faces.
Access should be denied.
```

### 💰 *sns pricing*
--- 
![alt text](image-1.png)
--- 
$2 per 100,000 emails → your 15,000/month is only $0.30/month.

# TOTAL PROJECT WILL COST AROUND $15.56 per month

---

# 🔍 Monitoring 
## Amazon CloudWatch (Core Monitoring)

Tracks metrics for:
- Lambda: invocations, duration, errors
- S3: object count, storage size
- DynamoDB: read/write capacity, throttling
- SNS: messages published/delivered/failed
