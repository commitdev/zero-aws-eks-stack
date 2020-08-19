
module "rds_security_group" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "3.2.0"

  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for RDS DB"
  vpc_id      = "${var.vpc_id}"

  number_of_computed_ingress_with_source_security_group_id = 1
  computed_ingress_with_source_security_group_id = [
    var.database_engine == "postgres" ? {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL from EKS"
      source_security_group_id = "${var.allowed_security_group_id}"
    }:{
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MYSQL from EKS"
      source_security_group_id = "${var.allowed_security_group_id}"
    }
  ]

  egress_rules        = ["all-all"]

  tags = {
    Env  = "${var.environment}"
  }
}

data "aws_caller_identity" "current" {
}

# secret declared so secret version waits for rds-secret to be ready
# or else we often see a AWSDEFAULT VERSION secret not found error
data "aws_secretsmanager_secret" "rds_master_secret" {
  name = "${var.project}-${var.environment}-rds-<% index .Params `randomSeed` %>"
}

# RDS does not support secret-manager, have to provide the actual string
data "aws_secretsmanager_secret_version" "rds_master_secret" {
  secret_id = data.aws_secretsmanager_secret.rds_master_secret.name
}

module "rds_postgres" {
  count = var.database_engine == "postgres" ? 1 : 0
  source  = "terraform-aws-modules/rds/aws"
  version = "2.17.0"

  identifier = "${var.project}-${var.environment}"

  engine            = "postgres"
  engine_version    = "11"
  instance_class    = var.instance_class
  allocated_storage = var.storage_gb
  storage_encrypted = true

  name     = "${replace(var.project, "-", "")}"
  username = "master_user"
  password = "${data.aws_secretsmanager_secret_version.rds_master_secret.secret_string}"
  port     = "5432"

  vpc_security_group_ids = ["${module.rds_security_group.this_security_group_id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster in non-production environments
  backup_retention_period = var.environment == "production" ? 30 : 0

  # Subnet is created by the vpc module
  create_db_subnet_group = false
  db_subnet_group_name = "${var.project}-${var.environment}-vpc"

  # DB parameter and option group
  family = "postgres11"
  major_engine_version = "11"

  final_snapshot_identifier = "final-snapshot"
  deletion_protection = true

  # Enhanced monitoring
  performance_insights_enabled = true
  create_monitoring_role = true
  monitoring_role_name = "${var.project}-${var.environment}-rds-postgres-monitoring-role"
  monitoring_interval = "30"

  tags = {
    Name = "${var.project}-${var.environment}-rds-postgres"
    Env  = "${var.environment}"
  }
  depends_on = [module.rds_security_group]
}

module "rds_mysql" {
  count = var.database_engine == "mysql" ? 1 : 0
  source  = "terraform-aws-modules/rds/aws"
  version = "2.17.0"

  identifier = "${var.project}-${var.environment}"

  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = var.instance_class
  allocated_storage = var.storage_gb
  storage_encrypted = true

  name     = "${replace(var.project, "-", "")}"
  username = "master_user"
  password = "${data.aws_secretsmanager_secret_version.rds_master_secret.secret_string}"
  port     = "3306"

  vpc_security_group_ids = ["${module.rds_security_group.this_security_group_id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster in non-production environments
  backup_retention_period = var.environment == "production" ? 30 : 0

  # Subnet is created by the vpc module
  create_db_subnet_group = false
  db_subnet_group_name = "${var.project}-${var.environment}-vpc"

  # DB parameter and option group
  family = "mysql5.7"
  major_engine_version = "5.7"

  final_snapshot_identifier = "final-snapshot"
  deletion_protection = true

  # Enhanced monitoring
  # Seems like mysql doesnt have performance insight on this instance size 
  # Amazon RDS for MySQL
  # 8.0.17 and higher 8.0 versions, version 5.7.22 and higher 5.7 versions,
  # and version 5.6.41 and higher 5.6 versions. Not supported for version 5.5. 
  # Not supported on the following DB instance classes: 
  # db.t2.micro, db.t2.small, db.t3.micro, db.t3.small, 
  # all db.m6g instance classes, and all db.r6g instance classes.
  performance_insights_enabled = false
  create_monitoring_role = true
  monitoring_role_name = "${var.project}-${var.environment}-rds-mysql-monitoring-role"
  monitoring_interval = "30"

  tags = {
    Name = "${var.project}-${var.environment}-rds-postgres"
    Env  = "${var.environment}"
  }
  depends_on = [module.rds_security_group]
}
