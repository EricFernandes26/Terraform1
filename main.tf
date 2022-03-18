provider "aws" {
  region = "us-east-1"
}

// Criar VPC
resource "aws_vpc" "lab-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}
// Criar Subnet's public e private
resource "aws_subnet" "public_subnet_1" {
vpc_id = aws_vpc.lab-vpc
cidr_block = "10.0.1.0/24" 
}

resource "aws_subnet" "public_subnet_2" {
vpc_id = aws_vpc.lab-vpc
cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "private_subnet_1" {
vpc_id = aws_vpc.lab-vpc
cidr_block = "10.0.3.0/24" 
}

resource "aws_subnet" "private_subnet_2" {
vpc_id = aws_vpc.lab-vpc
cidr_block = "10.0.4.0/24" 
}

//Criar instancia EC2 na public_subnet_1
resource "aws_instance" "webserver" {
  ami = "ami-047a51fa27710816e"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet_1
}

//Criar instancia de Banco de dados mysql
resource "aws_db_instance" "banco_teste" {
  allocated_storage = 10
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  name = "teste-aula"
  username = "admin"
  password = "lab-admin"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet.id
}

// Db-subnet
resource "aws_db_subnet_group" "db_subnet" {
  name = "db-subnet"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

// ip elastico
resource "aws_eip" "nat" {
    vpc = true
  depends_on = [ aws_internet_gateway.igw ]
}

// IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab-vpc
}

// NAT-gw
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.private_subnet_1.id

  depends_on = [ aws_internet_gateway.igw ]
  
}

// route-table
resource "aws_route_table" "router" {
  vpc_id = aws_vpc.lab-vpc

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "aws_nat_gateway.nat_gw.id"

  } 
}

// route-table associado com a private_subnet_1
resource "aws_route_table_association" "assoc" {
   subnet_id = aws_subnet.private_subnet_1.id
   router_table_id = aws_route_table.router.id
}