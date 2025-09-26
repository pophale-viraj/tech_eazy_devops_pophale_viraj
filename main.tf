provider "aws" {
  region = var.region
}
/*---------------------------------------------------------------------*/
data "aws_caller_identity" "current" {}
/*---------------------------------------------------------------------*/

resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "up-server-0412-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

resource "terraform_data" "private_key" {
  input            = tls_private_key.my_key
  triggers_replace = [timestamp()]
}

#command = "echo '${tls_private_key.my_key}' > private_key.pem"

resource "aws_instance" "up-server-0412" {
  ami           = var.ami_id
  instance_type = var.instancetypes
  #count         = var.instance_count
  key_name = aws_key_pair.my_key_pair.key_name
  # (You’ll need a connection block so Terraform can SSH into the instance)
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.my_key.private_key_pem
    host        = self.public_ip
  }
  depends_on = [aws_s3_bucket.this]

}

resource "null_resource" "upload_logs" {
  depends_on = [aws_instance.up-server-0412]

  triggers = {
    instance_id = aws_instance.up-server-0412.id
    bucket_name = aws_s3_bucket.this.bucket
    public_ip   = aws_instance.up-server-0412.public_ip
    private_key = tls_private_key.my_key.private_key_pem
  }
  provisioner "local-exec" {
  command = <<EOT
    scp -i private_key.pem ubuntu@${self.triggers.public_ip}:/tmp/logs_*.tgz ./logs/
    aws s3 cp ./logs/ s3://${self.triggers.bucket_name}/ec2_logs/ --recursive
  EOT
  }

  # Run while the instance is still alive
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.triggers.public_ip
      private_key = self.triggers.private_key
      timeout     = "5m"
    }


    inline = [
      "echo 'Collecting logs before termination...'",
      "sudo tar -czf /tmp/logs_$(hostname)_$(date +%Y%m%d%H%M%S).tgz /var/log/*",
      "aws s3 cp /tmp/logs_*.tgz s3://${self.triggers.bucket_name}/ec2_logs/"
    ]
  }
}

resource "aws_security_group" "ssh" {
  #vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["65.1.84.12/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* resource "null_resource" "upload_logs_on_destroy" {
  depends_on = [terraform_data.private_key]
  triggers = {
    instance_id = aws_instance.up-server-0412.id
    bucket_name = aws_s3_bucket.this.id
    # maybe also the SSH endpoint, key, etc
    public_ip   = aws_instance.up-server-0412.public_ip
    private_key = tls_private_key.my_key.private_key_pem
  }

  provisioner "remote-exec" {
    when = destroy

    connection {
      type        = "ssh"
      host        = self.triggers.public_ip
      user        = "ubuntu"
      private_key = self.triggers.private_key
    }

    inline = [
      "sudo tar -czf /tmp/logs_$(hostname).tgz /var/log/*",
      "aws s3 cp /tmp/logs_*.tgz s3://${self.triggers.bucket_name}/ec2_logs/ || true"
    ]
  }
} */

/*---------------------------------------------------------------------*/
resource "aws_s3_bucket" "this" {
  # If bucket_name is provided, use it; else let Terraform pick a random name with prefix
  bucket = length(trimspace(var.bucket_name)) > 0 ? var.bucket_name : null

  # You might want to allow force_destroy if you plan to delete with contents
  force_destroy = true

  # (Optional) versioning, encryption, etc.
  /*   aws_s3_bucket_versioning {
    enabled = true
  } */

  tags = {
    #Name        = coalesce(var.bucket_name, aws_s3_bucket.this.id)
    Environment = "prod"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "log_retention" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-logs-after-7-days"
    status = "Enabled"

    # Apply to all objects (or set prefix if you store logs under a prefix)
    filter {
      # empty filter means all objects
    }

    expiration {
      days = 7
    }
  }
}
/*---------------------------------------------------------------------*/
resource "aws_iam_role" "s3_read_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          # Who can assume this role? e.g. EC2, or another AWS account, or service
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "s3_read_policy_doc" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_read_policy" {
  name   = "s3_read_policy"
  policy = data.aws_iam_policy_document.s3_read_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_read" {
  role       = aws_iam_role.s3_read_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}
/*---------------------------------------------------------------------*/
resource "aws_iam_role" "s3_admin_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "s3_admin_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }

  # Optionally, allow creating new buckets in the account:
  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket"
    ]
    resources = [
      "*" # to allow create on any bucket name. Be careful with broad wildcard.
    ]
  }
}

resource "aws_iam_policy" "s3_admin_policy" {
  name   = "s3_admin_policy"
  policy = data.aws_iam_policy_document.s3_admin_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_admin" {
  role       = aws_iam_role.s3_admin_role.name
  policy_arn = aws_iam_policy.s3_admin_policy.arn
}
