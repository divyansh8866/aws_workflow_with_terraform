# Please need changes to this template according to need, this is not actual run and play code. You will need to enter details
# as per your requirement to make this templet work
# Author : Divyansh Patel

# Aws credentials variable
variable "aws_credentials" {
  type = map
}

# name of the folder in which Spark script ar to be stored.
variable "named_folder" {
  type    = string
  default = "None"
}

# name of the bucket in the S3 where script ar to be stored.
variable "bucket_name" {
    type = string
    default = "None"
}

# AWS initilizer code.
provider "aws"{
    region     = var.aws_credentials.region
    access_key = var.aws_credentials.access_key
    secret_key = var.aws_credentials.secret_key
    token = var.aws_credentials.token
}

# Upload all the spark scripts to the s3 bucket.
resource "aws_s3_bucket_object" "file_upload" {
  bucket   = var.bucket_name
  for_each = fileset("glue_jobs_script/", "*")
  key      = "${var.named_folder}/${each.value}"
  source   = "glue_jobs_script/${each.value}"
  etag     = filemd5("glue_jobs_script/${each.value}")
}

# Create a glue job for table job_posting_dynam
resource "aws_glue_job" "revelio_job_posting_dynam" {
  name     = "revelio_job_posting_dynam"
  role_arn = ""           # <<<------ Put which role to use
  command {
    script_location = "s3://${var.bucket_name}/${var.named_folder}/<file name here>"
  }
  number_of_workers = 10
  timeout = 2880
}

# Create a glue job for table transition_outflow
resource "aws_glue_job" "revelio_transition_outflow" {
  name     = "" # <<< Change here
  role_arn = ""           # <<<------ Put which role to use
  command {
    script_location = "s3://${var.bucket_name}/${var.named_folder}/<file name here>"
  }
  number_of_workers = 10
  timeout = 2880
  tags = {} # # <<< Change here
}

# Create a glue job for table wf_dynam_skill_breakdown
resource "aws_glue_job" "revelio_wf_dynam_skill_breakdown" {
  name     = "revelio_wf_dynam_skill_breakdown"
  role_arn = "arn:aws:iam::231009317852:user/qa-datateam-gluecrawler"           # <<<------ Put which role to use
  command {
    script_location = "s3://${var.bucket_name}/${var.named_folder}/<file name here>"
  }
  number_of_workers = 10
  timeout = 2880
  tags = {} # <<< Change here
}

#Create a crawler to crawl folder job_posting_dynam
resource "aws_glue_crawler" "revelio_crawler_job_posting_dynam" {
  database_name = "revelio"
  name          = "revelio_crawler_job_posting_dynam"
  role      = ""  # <<< Change here
  number_of_workers = 2
  tags = {}   # <<< Change here
  s3_target {
    path = ""   # <<< Change here
  }
}

#Create a crawler to crawl folder transition_outflow
resource "aws_glue_crawler" "revelio_crawler_transition_outflow" {
  database_name = "revelio"
  name          = "" # <<< Change here
  role      = ""  # <<< Change here
  number_of_workers = 2
  tags = {}   # <<< Change here
  s3_target {
    path = "" # <<< Change here
  }
}

#Create a crawler to crawl folder wf_dynam_skill_breakdown
resource "aws_glue_crawler" "revelio_crawler_wf_dynam_skill_breakdown" {
  database_name = ""
  name          = ""
  role      = ""
  number_of_workers = 2
  tags = {}
  s3_target {
    path = ""
  }
}

# Creat work flow
resource "aws_glue_workflow" "revelio_data_elt" {
  name = ""
}

# AWS glue workflow to trigger jobs
resource "aws_glue_trigger" "revelio_main_trigger" {
  name          = ""
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.revelio_data_elt.name
  actions {
    job_name = aws_glue_job.revelio_job_posting_dynam.name
  }
  actions {
    job_name = aws_glue_job.revelio_transition_outflow.name
  }
  actions {
    job_name = aws_glue_job.revelio_wf_dynam_skill_breakdown.name
  }
}

# AWS crawler trigger
resource "aws_glue_trigger" "crawler_trigger_job_posting_dynam" {
  name          = ""
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.revelio_data_elt.name
  predicate {
    conditions {
      job_name = aws_glue_job.revelio_job_posting_dynam.name
      state    = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_crawler.revelio_crawler_job_posting_dynam.name
  }
}

# AWS crawler trigger
resource "aws_glue_trigger" "crawler_trigger_transition_outflow" {
  name          = ""
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.revelio_data_elt.name
  predicate {
    conditions {
      job_name = aws_glue_job.revelio_transition_outflow.name
      state    = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_crawler.revelio_crawler_transition_outflow.name
  }
}

# AWS crawler trigger
resource "aws_glue_trigger" "crawler_trigger_wf_dynam_skill_breakdown" {
  name          = ""
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.revelio_data_elt.name
  predicate {
    conditions {
      job_name = aws_glue_job.revelio_wf_dynam_skill_breakdown.name
      state    = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_crawler.revelio_crawler_wf_dynam_skill_breakdown.name
  }
}