terraform {
  backend "s3" {
    bucket = "tf-helloworld-kishore"
    key    = "tf-backend"
    region = "us-east-1"
  }
}