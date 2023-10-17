resource "aws_instance" "test" {
  count                  = 3
  ami                    = var.ec2_instance_ami
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.publics[count.index].id
  vpc_security_group_ids = [aws_security_group.sg.id]
  tags = {
    Name = "my_instance-${count.index + 1}",
  }
}

