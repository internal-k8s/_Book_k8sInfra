# aws CLI로 구성한 ~/.aws 디렉터리의 정보를 이용하도록 aws 프로바이더를 구성합니다.
provider "aws" {
  profile = "default"
}

# 기본 VPC를 사용합니다. AWS 리전에는 기본 VPC가 설정되어 있기 때문에 사용하지 않은 리전을 선택했을 경우 기본 VPC를 사용할 수 있습니다.
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
  enable_dns_hostnames = true
}

# 기본 서브넷을 사용합니다. 서브넷은 가용 영역과 연관되어 있습니다. 리전의 가용 영역 중 첫 번째 가용 영역을 사용하기 위해 a를 붙여줍니다(예: us-east1a)
resource "aws_default_subnet" "default_az1" {
  availability_zone = format("%s%s", data.aws_region.current.name, "a")

  tags = {
    Name = "Default subnet"
  }
}

# Route53 에 프라이빗 존을 생성합니다. k8s.local 로 끝나는 FQDN을 설정할 경우 kops는 이를 자동으로 프라이빗 영역으로 인식합니다.
resource "aws_route53_zone" "private_zone" {
  name = "kops.k8s.local"

  vpc {
    vpc_id = aws_default_vpc.default.id
  }
}

# aws iam create-group --group-name kops
# kops 가 사용할 IAM 그룹을 생성합니다.
resource "aws_iam_group" "kops_group" {
  name = "kops"
}

# aws iam create-user --user-name kops
# kops 가 사용할 IAM 사용자를 생성합니다.
resource "aws_iam_user" "kops_user" {
  name = "kops"
}

# aws iam add-user-to-group --user-name kops --group-name kops
# kops IAM 그룹과 IAM 사용자를 연결 해 줍니다.
resource "aws_iam_user_group_membership" "kops_group_membership" {
  groups = [aws_iam_group.kops_group.name]
  user   = aws_iam_user.kops_user.name
}

# aws iam attach-group-policy --policy-arn <Policy ARN> --group-name kops
# kops IAM 그룹에 IAM 정책을 연결 해 줍니다. 해당 정책은 variables.tf 에 정의되어 있으며, kops 구성 및 구동에 필요한 ec2, route53, s3, IAM, VPC, sqs, eventbridge 에 대한 접근 권한을 포함합니다.
resource "aws_iam_policy_attachment" "kops_group_policy_attachment" {
  for_each = var.policy_arns
  name       = "kops-${each.key}-policy"
  policy_arn = each.value
  groups = [aws_iam_group.kops_group.name]
}

# aws iam create-access-key --user-name kops
# kops 가 사용할 access key를 생성합니다.
resource "aws_iam_access_key" "kops_access_key" {
  user = aws_iam_user.kops_user.name
}

# aws s3api create-bucket --bucket <bucket-name> --region <region-name> --create-bucket-configuration LocationConstraint=<Region name>
# kops가 사용할 상태 저장소를 생성합니다. kops는 kops가 관리하는 클러스터의 상태 및 작업에 따른 변경 내역을 S3 버킷에 기록합니다.
resource "aws_s3_bucket" "k8s_state_store" {
  bucket = var.state_store
  force_destroy = true
  tags = {
    Name = "k8s-state-store"
  }
}

# aws s3api put-bucket-versioning --bucket book-k8s-state-store  --versioning-configuration Status=Enabled
# 상태 저장소로 사용하는 S3 버킷의 버전 관리 기능을 활성화합니다.
resource "aws_s3_bucket_versioning" "k8s_state_store_versioning" {
  bucket = aws_s3_bucket.k8s_state_store.id
  versioning_configuration {
    status = "Enabled"
  }
}
