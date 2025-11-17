# Globant Data Engineering Coding Challenge

This repository contains proposal for Globant’s Data Engineering Coding Challenge.

The objective is to design and implement:
- A REST API that receives historical CSV files
- A process to ingest the data into a SQL database
- Batch insert support for 1 to 1000 rows
- SQL-based analytics endpoints
- A scalable, production-oriented architecture using AWS ecosystem

This solution prioritizes clean architecture, scalability, testability, and best practices for modern data engineering systems.


## 1. Challenge Requirements

### Section 1 — REST API

The API must:
- Receive historical data from CSV files
- Load this data into a SQL database
- Support bulk inserts (1–1000 rows per request)

### Section 2 — SQL Metrics
Expose endpoints that return the following:

#### Metric 1 – Hires per Job & Department by Quarter (2021)

Output format:
```
department | job | Q1 | Q2 | Q3 | Q4
```

Sorted alphabetically by:
- department
- job


#### Metric 2 – Departments Above Average Hires (2021)

Output format:
```
id | department | hired
```

Sorted by hired count (descending).



## 2. Database Schema

The challenge defines three CSV structures:

- `departments.csv`
- `jobs.csv`
- `hired_employees.csv`

PostgreSQL Schema:
```
CREATE TABLE departments (
    id INT PRIMARY KEY,
    department TEXT NOT NULL
);

CREATE TABLE jobs (
    id INT PRIMARY KEY,
    job TEXT NOT NULL
);

CREATE TABLE hired_employees (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    datetime TIMESTAMPTZ NOT NULL,
    department_id INT REFERENCES departments(id),
    job_id INT REFERENCES jobs(id)
);
```



## 3. High-Level Architecture

This solution uses a scalable AWS ingestion design:
```
Client → API Gateway → Lambda (CreateUpload) → S3

S3 → SQS → Step Functions → Lambda (CSV Processor) → PostgreSQL

Metrics API → Lambda → PostgreSQL (Read Replica)
```


Why this architecture?

- Presigned S3 uploads support large CSV files efficiently
- SQS provides buffering, retry handling, and decoupling
- Step Functions orchestrate validation → parsing → loading
- Lambda provides serverless scalability
- PostgreSQL satisfies SQL requirements
- Endpoints provide metrics directly from SQL



## 4. Section 1 — API Design

### POST /uploads

Creates an upload job and returns a presigned S3 URL.

Request:
```
{
  "fileName": "hired_employees.csv",
  "contentType": "text/csv",
  "schema": "hired_employees"
}
```

Response:
```
{
  "uploadId": "uuid",
  "objectKey": "uploads/2025/11/16/uuid.csv",
  "uploadUrl": "https://s3-url...",
  "expiresIn": 900
}
```

### PUT (via presigned S3 URL)

Upload the CSV directly to S3.


### GET /uploads/{uploadId}

Returns ingestion status:
```
REQUESTED
UPLOADED
PROCESSING
SUCCEEDED
FAILED
```



## 5. Ingestion Workflow (CSV → SQL)

1. User requests upload slot
2. CSV is uploaded directly to S3
3. S3 triggers an ObjectCreated event → SQS
4. Step Functions state machine starts
5. CSV Processor Lambda:
    - Downloads file
    - Validates schema/header
    - Parses rows
    - Inserts batches of 1–1000 rows into PostgreSQL
6. Metadata table is updated
7. Final ingestion status is set



## 6. Ingestion Metadata Table

```
CREATE TABLE ingestion_uploads (
    upload_id UUID PRIMARY KEY,
    object_key TEXT NOT NULL UNIQUE,
    file_name TEXT NOT NULL,
    schema TEXT NOT NULL,
    status TEXT NOT NULL,
    row_count BIGINT,
    error_count BIGINT,
    last_error TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```



## 7. Section 2 – SQL Metric Endpoints

### 7.1 GET /metrics/hired/2021/by-quarter

### 7.2 GET /metrics/departments/above-mean



## 8. Infrastructure as Code (AWS CDK)

AWS CDK (Python) is used to define:
- S3 upload bucket
- SQS queue
- Lambda functions (CreateUpload, CSV Processor, Metrics API)
- Step Functions ingestion workflow
- API Gateway REST API
- PostgreSQL (Amazon RDS)
- IAM roles and permissions


Deployment Commands
```
npm install -g aws-cdk
cdk bootstrap
cdk synth
cdk deploy
```



## 9. Testing Strategy

A layered testing approach ensures correctness and reliability.

### 9.1 Unit Tests (pytest)

- CSV row parsing
- Validation logic
- SQL parameter mapping
- Business rules

### 9.2 AWS-Mocked Tests (moto or localstack)

- Mock S3 object uploads
- Mock SQS event consumption
- Validate presigned URL logic
- Test Lambdas without real AWS calls

### 9.3 Integration Tests

- Call `POST /uploads`
- Upload a CSV using the presigned URL
- Poll `/uploads/{id}` until state = `SUCCEEDED`
- Validate rows in PostgreSQL
- Call `/metrics/...` endpoints



## 10. Diagrams

This repo includes diagrams created using the diagrams Python package:

- `images/globant_upload_arch.png`
- `images/globant_logical_layers_architecture.png`
- `images/globant_csv_workflow_state_machine.png`



## 11. CI/CD – AWS CodePipeline, CodeBuild

This project can be deployed using a simple CI/CD pipeline built on **AWS CodePipeline** and **AWS CodeBuild**.

### 11.1 Pipeline Overview

The CI/CD pipeline has three main stages:
1. **Source**
   - Triggered on changes to the GitHub repository (e.g., pushes to `main`).
   - CodePipeline pulls the latest source code.

2. **Build & Test (CodeBuild)**
   - Installs Python and CDK dependencies.
   - Runs unit tests (via `pytest`).
   - Runs `cdk synth` to validate the AWS CDK stack and generate CloudFormation templates.

3. **Deploy (CDK / CloudFormation)**
   - Deploys the CDK stack to a **dev** environment using `cdk deploy`.
   - For a production environment, a manual approval step can be added before deployment.
   - Lambdas, API Gateway, S3, SQS, Step Functions, and RDS are all managed by the CDK stack.

### 11.2 Example buildspec for Build & Test

```
phases:
  install:
    commands:
      - echo "[install] Updating pip and installing dependencies"
      - pip install --upgrade pip
      - pip install -r requirements.txt
      - pip install -r requirements-dev.txt || echo "No dev requirements file"
      - npm install -g aws-cdk

  pre_build:
    commands:
      - echo "[pre_build] Running unit tests"
      - pytest

  build:
    commands:
      - echo "[build] Synthesizing CDK template"
      - cdk synth

  post_build:
    commands:
      - echo "[post_build] Build phase completed successfully"

artifacts:
  files:
    - cdk.out/**/*
```



## 12. Why This Architecture Is Scalable

- S3 handles large uploads effortlessly
- SQS prevents overloading downstream systems
- Step Functions add resiliency and orchestration
- Lambda provides fully serverless compute
- RDS read replica supports analytics at scale
- CDK ensures consistent environments and easy redeployment



## 13. Conclusion

This solution fully satisfies the challenge:

✔ Section 1: CSV ingestion + REST API + batch inserts
✔ Section 2: Stakeholder metrics via SQL endpoints
✔ Scalable cloud-native architecture
✔ Strong testing strategy
✔ Infrastructure as Code using AWS CDK
