provider "aws" {
  profile    = "terraform"
  region     = var.region
}

resource "aws_key_pair" "ssh-login-key" {
  key_name   = "ssh-login-key"
  public_key = "${file("/Users/evgeniyscherbina/.ssh/id_rsa_test.pub")}"
}

resource "aws_security_group" "allow-ssh-login" {
  name        = "allow-ssh-login"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami             = var.amis[var.region]
  instance_type   = "t2.micro"
  key_name        = "ssh-login-key"
  security_groups = ["allow-ssh-login"]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = aws_instance.example.public_ip
      agent       = "false"
      private_key = "${file("/Users/evgeniyscherbina/.ssh/id_rsa")}"
    }

    inline = [
      # Install Golang
      "wget https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz",
      "tar -xzf go1.12.7.linux-amd64.tar.gz",
      "sudo mv go /usr/local",
      "echo 'export GOROOT=/usr/local/go' >> ~/.bash_profile",
      "echo 'export GOPATH=$HOME/go' >> ~/.bash_profile",
      "echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> ~/.bash_profile",
      "source ~/.bash_profile",

      # Clone and compile project
      "sudo yum install -y git",
      "git clone https://github.com/evgeniy-scherbina/vault-sandbox.git /home/ec2-user/go/src/github.com/evgeniy-scherbina/vault-sandbox",
      "go get -u github.com/golang/dep/cmd/dep",
      // "cd /home/ec2-user/go/src/github.com/evgeniy-scherbina/calc && dep ensure",

      # Install docker
      "sudo yum install -y docker",

      "curl -L https://releases.hashicorp.com/nomad/0.9.3/nomad_0.9.3_linux_amd64.zip > nomad.zip",
      "sudo unzip nomad.zip -d /usr/bin",

      "sudo nomad agent -dev &",
      "sleep 5",
      "cd deploy/nomad && sudo nomad job run calc.nomad",
    ]
  }
}