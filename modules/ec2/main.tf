resource "aws_instance" "instance" {
  ami                    = data.aws_ami.latest.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip
  user_data              = var.user_data

  tags = {
    Name = var.name
  }
  provisioner "remote-exec" {
    inline = var.role == "backend" ? [
      "sudo yum update -y",
      "sudo yum install -y python3 git",
      "pip3 install -r /home/ec2-user/app/requirements.txt",
      "nohup python3 /home/ec2-user/app/app.py &"
    ] : [
      "sudo amazon-linux-extras install -y nginx1",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = var.associate_public_ip ? self.public_ip : self.private_ip

      bastion_host        = var.associate_public_ip ? null : var.bastion_host
      bastion_user        = var.associate_public_ip ? null : "ec2-user"
      bastion_private_key = var.associate_public_ip ? null : file(var.private_key_path)
    }

  }
}

resource "null_resource" "copy_backend_app" {
  count = var.role == "backend" ? 1 : 0

  provisioner "file" {
    source      = var.app_dir
    destination = "/home/ec2-user/app"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = var.associate_public_ip ? aws_instance.instance.public_ip : aws_instance.instance.private_ip

      bastion_host        = var.associate_public_ip ? null : var.bastion_host
      bastion_user        = var.associate_public_ip ? null : "ec2-user"
      bastion_private_key = var.associate_public_ip ? null : file(var.private_key_path)
    }
  }

  depends_on = [aws_instance.instance]
}

# Data source for latest AMI

data "aws_ami" "latest" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["137112412989"] # Amazon
}