resource "aws_instance" "api" {
  ami                    = "${data.aws_ami.app_ami.id}"
  instance_type          = "${var.api_instance_type}"
  count                  = "${var.api_instance_count}"
  key_name               = "${aws_key_pair.terraform.key_name}"
  subnet_id              = "${element(module.vpc.public_subnets, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.app_websg.id}"]

  iam_instance_profile = "${aws_iam_instance_profile.cloudwatch_profile.name}"

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
    Name        = "api-${count.index}"
  }
}

resource "aws_lb_target_group_attachment" "externallb" {
  count            = "${var.api_instance_count}"
  target_group_arn = "${aws_lb_target_group.apiexternal.arn}"
  target_id        = "${element(aws_instance.api.*.private_ip, count.index)}"
  port             = 80

  lifecycle {
    ignore_changes = true
  }
}

resource "aws_instance" "jump1" {
  ami                    = "${data.aws_ami.jump_ami.id}"
  instance_type          = "${var.jump_instance_type}"
  key_name               = "${aws_key_pair.terraform.key_name}"
  subnet_id              = "${element(module.vpc.public_subnets, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.jump_sg.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.scout2_profile.name}"

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
    Name        = "jumpserver"
  }
}

data "template_file" "init_rapid7" {
  template = "${file("init_rapid7.tpl")}"

  vars {
    rapid7_console_address = "${var.rapid7_console_address}"
    rapid7_console_port    = "${var.rapid7_console_port}"
    rapid7_console_secret  = "${var.rapid7_console_secret}"
  }
}

resource "aws_instance" "rapid7" {
  ami                    = "${data.aws_ami.rapid7_ami.id}"
  instance_type          = "${var.rapid7_instance_type}"
  subnet_id              = "${element(module.vpc.private_subnets, 0)}"
  vpc_security_group_ids = ["${aws_security_group.rapid7_sg.id}"]
  user_data              = "${data.template_file.init_rapid7.rendered}"

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
    Name        = "rapid7"
  }
}
