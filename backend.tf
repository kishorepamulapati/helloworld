terraform {
  backend "s3" {
    bucket = "ebiz-helloworld-kishore"
    key    = "backend"
    region = "us-east-1"
  }
}
