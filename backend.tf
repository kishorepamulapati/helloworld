terraform {
  backend "s3" {
    bucket = "ebiz-helloworld-kishore"
    key    = "task1/backend"
    region = "us-east-1"
  }
}
