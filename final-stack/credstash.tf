module "credstash" {
  source               = "github.com/fpco/terraform-aws-foundation/modules/credstash-setup"
  create_reader_policy = true
  create_writer_policy = true
}
// KMS Key ARN. It can later be used to store and retrieve secrets.
output "kms_key_arn" {
  value = "${module.credstash.kms_key_arn}"
}
// KMS Master key id.
output "kms_key_id" {
  value = "${module.credstash.kms_key_id}"
}
// KMS Key alias. It can later be used to store and retrieve secrets.
output "kms_key_alias" {
  value = "${module.credstash.kms_key_alias}"
}
// KMS Master key alias ARN.
output "kms_key_alias_arn" {
  value = "${module.credstash.kms_key_alias_arn}"
}
// DynamoDB table ARN
output "db_table_arn" {
  value = "${module.credstash.db_table_arn}"
}
// DynamoDB table name that can be used by credstash to store/retrieve secrets.
output "db_table_name" {
  value = "${module.credstash.db_table_name}"
}
// Ubuntu bash script snippet for installing credstash and its dependencies
output "install_snippet" {
  value = "${module.credstash.install_snippet}"
}
// Credstash get command with region and table values set.
output "get_cmd" {
  value = "${module.credstash.get_cmd}"
}
// Credstash put command with region, table and kms key values set.
output "put_cmd" {
  value = "${module.credstash.put_cmd}"
}
// Secret Reader policy
output "reader_policy_arn" {
  value = "${module.credstash.reader_policy_arn}"
}
// Secret Writer policy
output "writer_policy_arn" {
  value = "${module.credstash.writer_policy_arn}"
}