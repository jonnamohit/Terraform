resource "aws_s3_bucket" "lb_logs" {
bucket = var.bucket_name
}