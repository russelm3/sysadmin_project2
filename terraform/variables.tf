variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "public_key_path" {
  description = "Absolute path to your local SSH public key"
}

variable "minecraft_jar_url" {
  description = "Direct URL to the Minecraft server.jar"
}