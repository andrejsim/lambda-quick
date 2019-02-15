
locals {
  bucket = "datafabric-nonprod-lambdas"

  dynamo_table_name = "dynamo_table"

  lambda_zip = "dummy-lambda-quick.zip"
}

data "aws_iam_policy_document" "output_lambda_doc" {
  statement {
    actions = [
      "sts:AssumeRole"]
    principals {
      identifiers = [
        "lambda.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_dynamodb_table" "metadata_table" {
  name = "${local.dynamo_table_name}"
}

data "aws_iam_policy_document" "db_policy_doc" {
  "statement" {
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"]
    resources = [
      "${data.aws_dynamodb_table.metadata_table.arn}"]
  }
}

resource "aws_iam_policy" "db_access_policy" {
  name = "${terraform.workspace}_api_lambda_db_access_policy"
  policy = "${data.aws_iam_policy_document.db_policy_doc.json}"
}

resource "aws_iam_role" "lambad_output_role" {
  name = "${terraform.workspace}_api_lambad_output_role"
  assume_role_policy = "${data.aws_iam_policy_document.output_lambda_doc.json}"
}

resource "aws_iam_policy_attachment" "lambda_exec-role-policy-attachment" {
  name       = "${terraform.workspace}_lambda_policy_atachment"
  roles      = ["${aws_iam_role.lambad_output_role.name}"]
  #policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
  policy_arn = "${aws_iam_policy.db_access_policy.arn}"
}

resource "aws_lambda_function" "lambda_out" {
  function_name = "${terraform.workspace}-lambda-output"

  s3_bucket = "${local.bucket}"
  s3_key = "${local.lambda_zip}"

  handler = "lambda_function.lambda_handler"
  runtime = "python3.6"

  role = "${aws_iam_role.lambad_output_role.arn}"

  environment {
    variables = {
      TABLE_NAME = "${data.aws_dynamodb_table.metadata_table.name}"
    }
  }
}

