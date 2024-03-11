resource "aws_ami_from_instance" "utc_dev_inst_ami" {
  name               = "utc-dev-inst"
  source_instance_id = aws_instance.utc_dev_inst.id
  tags = {
    Name = "utc-dev-inst-ami"
  }
}
