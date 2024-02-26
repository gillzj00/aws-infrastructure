resource "aws_ssm_parameter" "foo" {
  name  = "foo"
  type  = "String"
  value = "fart"
}

resource "aws_s3_bucket" "zachs_new_bucket" {
  bucket = "bucket_o_chum"
}
