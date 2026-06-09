provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "minecraft" {
  key_name   = "minecraft-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "minecraft" {
  name        = "minecraft-sg"
  description = "Allow SSH and Minecraft traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "minecraft" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.minecraft.key_name
  vpc_security_group_ids = [aws_security_group.minecraft.id]

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "minecraft-server"
  }
}

resource "aws_eip" "minecraft" {
  instance = aws_instance.minecraft.id
}