resource "aws_s3_bucket" "customer" {
  bucket = "customerimageprocess"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  force_destroy = true

  tags = {
    Name        = "customer"
    Environment = "Dev"
  }
}
resource "aws_s3_bucket" "process1" {
  bucket = "process1imageprocess"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "process1"
    Environment = "Dev"
  }
}

resource "aws_iam_role" "imageprocess_lambda_role" {
  name = "image_process_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_cloudwatch_log_group" "image_process" {
  name              = "/aws/lambda/imageprocess-lambda-function"
  retention_in_days = 14
}

resource "aws_lambda_function" "image_process" {
  function_name = "imageprocess-lambda-function"
  handler      = "lambda_function.lambda_handler"
  runtime      = "python3.9"
  filename     = "${path.module}/lambda_function.zip"
  role         = aws_iam_role.imageprocess_lambda_role.arn
  layers       = [ "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p39-pillow:1" ]
  timeout      = 360
  environment {
    variables = {
      DESTINATION_BUCKET = aws_s3_bucket.process1.id,
      WATERMARK_TEXT  = "Test"
    }
  }
}

resource "aws_iam_policy" "imageprocess_lambda_policy" {
  name   = "example_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.customer.arn}/*",
          "${aws_s3_bucket.customer.arn}",
          "${aws_s3_bucket.process1.arn}/*",
          "${aws_s3_bucket.process1.arn}"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.image_process.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_process.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.customer.arn
}

resource "aws_iam_role_policy_attachment" "imageprocess" {
  policy_arn = aws_iam_policy.imageprocess_lambda_policy.arn
  role       = aws_iam_role.imageprocess_lambda_role.name
}

resource "aws_s3_bucket_notification" "image_notification" {
  bucket = aws_s3_bucket.customer.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_process.arn
    events              = ["s3:ObjectCreated:*"]
  }
  depends_on = [
    aws_lambda_function.image_process,
    aws_iam_role_policy_attachment.imageprocess,
    aws_cloudwatch_log_group.image_process
  ]
}

