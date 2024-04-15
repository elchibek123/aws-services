resource "aws_instance" "myec2vm" {
  ami = data.aws_ami.ubuntu22.04.id
  instance_type = "t2.micro"
  user_data = file("${path.module}/app1-install.sh")
  key_name = "my-key"
  vpc_security_group_ids = [ aws_security_group.vpc_sg.id ]
  for_each = toset(keys({for az, details in data.aws_ec2_instance_type_offerings.my_ins_type: 
    az => details.instance_types if length(details.instance_types) != 0 }))
  availability_zone = each.key
  tags = {
    "Name" = "my-instance-${each.key}"
  }
}