include {
  path = find_in_parent_folders()
}

terraform {
  source = "git@github.com:dlpco/terraform-services.git//stonks-postgresql-suite?ref=stonks-postgresql-suite-0.0.15"
}

dependencies {
  paths = [
    "${get_parent_terragrunt_dir()}/${local.environment}/aws-us-east-1/network/security-groups//rds-postgres",
    "${get_parent_terragrunt_dir()}/${local.environment}/aws-us-east-1/network/security-groups//ec2-newrelic-agent",
    "${get_parent_terragrunt_dir()}/${local.environment}/aws-us-east-1/network/security-groups//rds-postgres-replica"
  ]
}

dependency "develop_db_postgres_sg" {
  config_path = "${get_parent_terragrunt_dir()}/${local.environment}/aws-us-east-1/network/security-groups//rds-postgres"
}

dependency "ec2_postgres_sg" {
  config_path = "${get_parent_terragrunt_dir()}/${local.environment}/aws-us-east-1/network/security-groups//ec2-newrelic-agent"
}

dependency "develop_db_postgres_replica_sg" {
  config_path = "${get_parent_terragrunt_dir()}/${local.environment}/aws-us-east-1/network/security-groups//rds-postgres-replica"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  subnet_group_id = local.account_vars.locals.subnet_group_id
  environment     = local.account_vars.locals.environment
  aws_region      = local.region_vars.locals.aws_region

  //If necessary, index of subnet_pv_useast1 can be changed
  subnet_pv_useast1 = local.account_vars.locals.subnet_pv_ids[3]
  key_name          = local.account_vars.locals.key_name

}

inputs = {

  //common Inputs
  environment   = local.environment
  instance_name = INSTANCE_NAME

  //RDS Inputs
  instance_type = INSTANCE_TYPE

  family_version             = FAMILY_VERSION
  engine_version             = ENGINE_VERSION
  auto_minor_version_upgrade = true

  storage_size          = STORAGE_SIZE
  max_allocated_storage = MAX_ALLOCATED_STORAGE

  performance_insights_enabled = true
  enable_multi_az              = true

  vpc_security_group_ids = [dependency.develop_db_postgres_sg.outputs.this_security_group_id]
  db_subnet_group_name   = local.subnet_group_id

  apply_immediately = true

  replica_instances = {
    replica = {
      suffix              = "replica",
      instance_class      = INSTANCE_TYPE
      security_group_ids  = [dependency.develop_db_postgres_replica_sg.outputs.this_security_group_id]
      skip_final_snapshot = true
    }
  }

  //Database Inputs

  additional_extensions = ["pgaudit"]

  aggregator_user = [
    {
      username = "aggregator"
    }
  ]

  #  aggregator_object_privs = [
  #    {
  #      username    = "aggregator"
  #      object_type = "table"
  #      privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
  #      schema      = "public"
  #      objects     = ["flash_delivery_reports"]
  #    }
  #  ]

  //NewRelic Inputs

  #ec2_vpc_security_group_ids = dependency.ec2_postgres_sg.outputs.security_group_id

  #subnet_id = local.subnet_pv_useast1
  #key_name  = local.key_name

  #monitoring_replica = true

}