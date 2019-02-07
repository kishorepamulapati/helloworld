output "instance-ami" {
  value = "${aws_instance.EC2.id}"
}
output "sg-ec2" {
  value = "${aws_security_group.SG-INSTANCE.id}"
}
output "sg-elb" {
 value = "${aws_security_group.SG-ELB.id}"
}
output "elb-dns" {
  value = "${aws_elb.ELB.dns_name}"
}
