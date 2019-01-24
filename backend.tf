terraform {
  backend "s3" {
    bucket = "ebiz-helloworld-kishore"
    key    = "s3-backend"
    region = "us-east-1"
  }
}
