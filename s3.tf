provider "aws" {
  region = "us-east-1"
}
resource "aws_s3_bucket" "source-bucket" {
  bucket = "${var.source}"
  acl = "private"
  tags {
    Name="s3-source bucket"
  }
}
resource "aws_s3_bucket" "desti-bucket" {
  bucket = "${var.desti}"
  acl = "private"
  tags {
    Name="s3-dest bucket"
  }
}
resource "aws_s3_bucket" "s3-cloudtrail" {
  bucket = "${var.cloudtrail_bucket}"
  acl = "private"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Effect": "Allow",
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.cloudtrail_bucket}"
        },
        {
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.cloudtrail_bucket}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudtrail" "cloudtrail" {
  name = "s3-trail"
  s3_bucket_name = "${aws_s3_bucket.s3-cloudtrail.id}"
  include_global_service_events = "false"

  event_selector {
    read_write_type = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = ["${aws_s3_bucket.source-bucket.arn}/"]
    }
  }
}

resource "aws_cloudwatch_event_rule" "Cloud-event" {
  name        = "capture-aws-sign-in"
  description = "Cloudtrail to cloudevent"

  event_pattern = <<PATTERN
  {
    "source": [
      "aws.s3"
    ],
    "detail-type": [
      "AWS API Call via CloudTrail"
    ],
    "detail": {
      "eventSource": [
        "s3.amazonaws.com"
    ],
    "eventName": [
      "PutObject"
    ],
    "requestParameters": {
      "bucketName": [
        "${var.source}"
      ]
    }
  }
  }
PATTERN
}
resource "aws_cloudwatch_event_target" "cloudevent-lambda" {
  arn = "${aws_lambda_function.lambda.arn}"
  rule = "${aws_cloudwatch_event_rule.Cloud-event.name}"
}

resource "aws_iam_role_policy" "s3-lambda-policy" {
  role = "${aws_iam_role.lambda-role.id}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Action": [
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::*"
    }
  ]
}
POLICY
}
resource "aws_iam_role" "lambda-role" {
  name = "lambda-s3"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda" {
  function_name = "lambdaTos3"
  filename = "lambdas3.zip"
  handler = "lambdas3.sample"
  role = "${aws_iam_role.lambda-role.arn}"
  source_code_hash = "${base64sha256(file("lambdas3.zip"))}"
  runtime = "python2.7"
}
resource "aws_lambda_permission" "lambda-access" {
  statement_id = "AllowCloudEventInvokeLambda"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.Cloud-event.arn}"
}

