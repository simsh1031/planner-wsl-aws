# Planner - AWS Terraform Infrastructure

## 1. 프로젝트 개요

**Planner-aws**는 Planner 서비스를 AWS 클라우드에 배포하기 위한 Infrastructure as Code(IaC) 프로젝트입니다.

Terraform을 이용하여 다음 AWS 리소스를 자동으로 프로비저닝합니다:
- 🌐 **네트워크**: VPC, 공개/개인 서브넷, NAT 게이트웨이
- 🐳 **컨테이너**: ECR(레지스트리), ECS Fargate(오케스트레이션)
- 🗄️ **데이터베이스**: RDS MySQL 8.0 (Multi-AZ 고가용성)
- ⚖️ **로드밸런싱**: Application Load Balancer (ALB)
- 🛡️ **보안**: Security Groups, WAF, Secrets Manager
- 📊 **모니터링**: CloudWatch (로그, 메트릭)
- 🌍 **DNS**: Route53 (도메인 관리)

이 인프라는 **프로덕션 레벨의 고가용성 및 보안**을 갖춘 완전 관리형 환경을 제공합니다.

---

## 2. 기술 스택

| 구분 | 기술 |
|------|------|
| **Infrastructure as Code** | Terraform >= 1.5.0 |
| **클라우드 플랫폼** | AWS (ap-northeast-2 리전) |
| **Provider** | hashicorp/aws ~> 5.0, hashicorp/random ~> 3.5 |
| **컨테이너 레지스트리** | Amazon ECR |
| **오케스트레이션** | Amazon ECS Fargate |
| **데이터베이스** | Amazon RDS (MySQL 8.0) |
| **로드밸런싱** | Application Load Balancer (ALB) |
| **보안** | AWS WAF, Security Groups, Secrets Manager |
| **DNS** | Amazon Route53 |
| **모니터링** | Amazon CloudWatch |

---

## 3. 아키텍처 개요

### 네트워크 구성

```
┌────────────────────────────────────────────────────────────┐
│                          VPC (192.168.0.0/16)              │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          Public Subnets (NAT Gateway, ALB)          │   │
│  │  ┌──────────────────┐     ┌──────────────────┐      │   │
│  │  │  public-a        │     │  public-b        │      │   │
│  │  │ 192.168.1.0/24   │     │ 192.168.2.0/24   │      │   │ 
│  │  │ AZ: ap-northeast │     │ AZ: ap-northeast │      │   │
│  │  │       -2a        │     │       -2c        │      │   │
│  │  └──────────────────┘     └──────────────────┘      │   │
│  │         (NAT GW)                (NAT GW)            │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ▼ (ALB)                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │    Private Subnets – ECS Fargate (Backend/Frontend) │   │
│  │  ┌──────────────────┐     ┌──────────────────┐      │   │
│  │  │  private-ecs-a   │     │  private-ecs-b   │      │   │
│  │  │ 192.168.3.0/24   │     │ 192.168.4.0/24   │      │   │
│  │  │ AZ: ap-northeast │     │ AZ: ap-northeast │      │   │
│  │  │       -2a        │     │       -2c        │      │   │
│  │  └──────────────────┘     └──────────────────┘      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │        Private Subnets – RDS (Multi-AZ)             │   │
│  │  ┌──────────────────┐     ┌──────────────────┐      │   │
│  │  │  private-rds-a   │     │  private-rds-b   │      │   │
│  │  │ 192.168.5.0/24   │     │ 192.168.6.0/24   │      │   │
│  │  │ AZ: ap-northeast │     │ AZ: ap-northeast │      │   │
│  │  │       -2a        │     │       -2c        │      │   │
│  │  │   RDS Primary    │     │   RDS Standby    │      │   │
│  │  └──────────────────┘     └──────────────────┘      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 주요 리소스

| 리소스 | 설명 | 구성 |
|--------|------|------|
| **VPC** | Virtual Private Cloud | 192.168.0.0/16 |
| **Public Subnets** | NAT Gateway, ALB 배치 | 2개 (AZ-a, AZ-c) |
| **Private ECS Subnets** | ECS Fargate (Backend/Frontend) | 2개 (AZ-a, AZ-c) |
| **Private RDS Subnets** | RDS Multi-AZ | 2개 (AZ-a, AZ-c) |
| **IGW** | Internet Gateway | VPC 외부 통신용 |
| **NAT Gateway** | 개인 서브넷 → 인터넷 통신 | 각 공개 서브넷에 1개 |
| **Route Table** | 트래픽 라우팅 규칙 | 공개/개인 구분 |

---

## 4. 컴퓨팅 및 데이터베이스 구성

### 4.1 컨테이너 레지스트리 (ECR)

| 리포지토리 | 용도 |
|----------|------|
| `myapp-backend` | Planner 백엔드 (Spring Boot) 이미지 |
| `myapp-frontend` | Planner 프론트엔드 (React/Nginx) 이미지 |

**특징**:
- 이미지 스캔 자동화 (보안 취약점 검사)
- Docker 이미지 저장소

### 4.2 ECS Fargate 클러스터

**클러스터 이름**: `myapp-cluster`

**기능**:
- Container Insights 활성화 (모니터링 및 로깅)
- 서버리스 컨테이너 오케스트레이션
- 자동 스케일링 지원

**배포 구성**:
- **Backend 태스크**: Spring Boot 애플리케이션
  - 포트: 8080
  - CPU: (설정 가능)
  - 메모리: (설정 가능)
  
- **Frontend 태스크**: React + Nginx
  - 포트: 80/443
  - CPU: (설정 가능)
  - 메모리: (설정 가능)

### 4.3 RDS MySQL (Multi-AZ)

| 속성 | 값 |
|------|-----|
| **엔진** | MySQL 8.0 |
| **인스턴스 클래스** | (설정 가능, 기본: db.t3.micro) |
| **스토리지** | 20 GB (gp3 - 범용) |
| **암호화** | 활성화 |
| **Multi-AZ** | 활성화 (자동 페일오버) |
| **백업** | 1일 보관 |
| **모니터링** | CloudWatch 로그 (error, general, slowquery) |
| **성능 인사이트** | 비활성화 (옵션) |

**백업 일정**:
- 백업 시간대: 03:00-04:00 (KST)
- 유지보수 시간대: 월 04:30-05:30 (KST)

**보안**:
- RDS 전용 Security Group
- 개인 서브넷에만 배치 (인터넷 노출 없음)
- Secrets Manager에서 비밀번호 관리

---

## 5. 로드밸런싱 및 라우팅

### 5.1 Application Load Balancer (ALB)

| 속성 | 값 |
|------|-----|
| **이름** | `myapp-alb` |
| **타입** | Application Load Balancer |
| **배치** | 공개 서브넷 (2개 AZ) |
| **Security Group** | ALB 전용 |

### 5.2 Target Group

| 타겟 그룹 | 설명 | 포트 | 경로 | 프로토콜 |
|----------|------|------|------|---------|
| **Backend** | Spring Boot API | 8080 | / | HTTP |
| **Frontend** | React 애플리케이션 | 80 | / | HTTP |

**헬스 체크**:
- 인터벌: 30초
- 타임아웃: 5초
- 정상 임계값: 3회 연속 성공
- 비정상 임계값: 3회 연속 실패
- 성공 코드: 200, 302, 404

### 5.3 리스너

- **포트 80**: HTTP 트래픽 → ALB로 수신
- **포트 443**: HTTPS 트래픽 (선택적, SSL 인증서 필요)

---

## 6. 보안 구성

### 6.1 Security Groups

| Security Group | 인바운드 규칙 | 아웃바운드 규칙 |
|--------|------|------|
| **ALB** | 80/443 (전체 CIDR) | 모든 트래픽 |
| **ECS** | 8080 (ALB에서), 443 (ALB에서) | 모든 트래픽 |
| **RDS** | 3306 (ECS SG에서) | 모든 트래픽 |

### 6.2 Secrets Manager

| 시크릿 | 용도 |
|--------|------|
| **DB Password** | RDS 마스터 사용자 비밀번호 |
| **JWT Secret** | JWT 토큰 서명/검증용 비밀키 |

### 6.3 IAM 역할

| 역할 | 권한 | 용도 |
|------|------|------|
| **ECS Execution Role** | ECR 액세스, CloudWatch 로그 저장 | ECS 태스크 실행 권한 |
| **ECS Task Role** | RDS, Secrets Manager 액세스 | 애플리케이션 런타임 권한 |
| **RDS Monitoring Role** | CloudWatch 로그 작성 | RDS 성능 모니터링 |

### 6.4 AWS WAF (선택적)

- DDoS 방어
- SQL Injection, XSS 등 일반적인 공격 방어
- Rate limiting
- 지리적 차단

---

## 7. 모니터링 및 로깅

### 7.1 CloudWatch

**로그 그룹**:
- `/ecs/myapp-backend`: 백엔드 컨테이너 로그
- `/ecs/myapp-frontend`: 프론트엔드 컨테이너 로그
- `/rds/mysql/myapp-mysql`: RDS 로그 (error, general, slowquery)

**메트릭**:
- CPU 사용률
- 메모리 사용률
- 네트워크 I/O
- 디스크 I/O
- 데이터베이스 쿼리 성능

### 7.2 Container Insights

- ECS Cluster 성능 모니터링
- 컨테이너별 리소스 사용량
- 서비스 레벨 메트릭

---

## 8. 배포 및 프로비저닝

### 8.1 변수 설정

`variables.tf`에서 커스터마이징 가능한 변수들:

```hcl
variable "aws_region" {
  default = "ap-northeast-2"
}

variable "project_name" {
  default = "myapp"
}

variable "vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "db_instance_class" {
  default = "db.t3.micro"
}

variable "db_name" {
  default = "planner_db"
}

variable "db_username" {
  default = "admin"
}
```

### 8.2 프로비저닝 단계

#### 1단계: Terraform 초기화
```bash
cd Planner-aws
terraform init
```

#### 2단계: 실행 계획 검토
```bash
terraform plan -out=tfplan
```

#### 3단계: 인프라 생성
```bash
terraform apply tfplan
```

#### 4단계: 출력값 확인
```bash
terraform output
```

### 8.3 삭제 (정리)

```bash
terraform destroy
```

---

## 9. 출력값 (Outputs)

인프라 생성 후 다음 값들이 출력됩니다:

| 출력값 | 설명 |
|--------|------|
| `vpc_id` | VPC ID |
| `alb_dns_name` | ALB DNS 이름 (애플리케이션 접근 주소) |
| `ecs_cluster_name` | ECS 클러스터 이름 |
| `rds_endpoint` | RDS 엔드포인트 (DB 연결 주소) |
| `db_secret_arn` | DB 비밀번호 시크릿 ARN |
| `jwt_secret_arn` | JWT 비밀키 시크릿 ARN |
| `backend_ecr_repository_url` | 백엔드 ECR 레포지토리 URL |
| `frontend_ecr_repository_url` | 프론트엔드 ECR 레포지토리 URL |

---

## 10. Docker 이미지 구축 및 배포

### 10.1 백엔드 이미지 푸시

```bash
# 로컬 빌드
cd ../Planner
./gradlew build

# Docker 이미지 빌드
docker build -t planner-backend:latest .

# ECR 태그 지정
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com

docker tag planner-backend:latest <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/myapp-backend:latest

# ECR 푸시
docker push <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/myapp-backend:latest
```

### 10.2 프론트엔드 이미지 푸시

```bash
# 프로덕션 빌드
cd ../Planner-front
npm run build

# Docker 이미지 빌드
docker build -t planner-frontend:latest .

# ECR 태그 지정
docker tag planner-frontend:latest <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/myapp-frontend:latest

# ECR 푸시
docker push <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/myapp-frontend:latest
```

---

## 11. 환경 변수 및 설정

### 11.1 백엔드 환경 변수 (ECS 태스크 정의)

```env
SPRING_DATASOURCE_URL=jdbc:mysql://<RDS_ENDPOINT>:3306/planner_db
SPRING_DATASOURCE_USERNAME=admin
SPRING_DATASOURCE_PASSWORD=<FROM_SECRETS_MANAGER>
JWT_SECRET=<FROM_SECRETS_MANAGER>
SPRING_JPA_HIBERNATE_DDL_AUTO=update
```

### 11.2 프론트엔드 환경 변수 (Nginx)

```env
VITE_API_BASE_URL=http://<ALB_DNS>/api
```

---

## 12. 비용 최적화 팁

1. **RDS 인스턴스 타입**: 프로덕션 환경에 맞게 선택 (t3.micro → t3.small/medium)
2. **ECS 태스크 CPU/메모리**: 애플리케이션 요구사항에 맞게 설정
3. **Auto Scaling**: ECS 및 RDS 자동 스케일링 정책 구성
4. **Reserved Instance**: 장기 운영시 비용 절감 (RI 구입)
5. **CloudWatch 로그 보존**: 불필요한 로그는 자동 삭제 정책 설정

---

## 13. 트러블슈팅

### ECS 태스크가 시작되지 않음
- CloudWatch 로그 확인: `/ecs/myapp-backend` 또는 `/ecs/myapp-frontend`
- ECR 이미지 존재 여부 확인
- Security Group 규칙 확인

### RDS 연결 오류
- RDS Security Group 규칙 확인 (ECS SG에서 3306 허용)
- RDS 서브넷 그룹 확인
- 마스터 비밀번호 확인 (Secrets Manager)

### ALB 헬스 체크 실패
- 대상 그룹 헬스 체크 경로 확인
- 보안 그룹 인바운드 규칙 확인
- 애플리케이션 포트 확인

---

## 14. 프로젝트 구조

```
Planner-aws/
├── main.tf                  # Provider 및 버전 정의
├── variables.tf             # 입력 변수
├── outputs.tf               # 출력값
├── vpc.tf                   # VPC, Subnets, IGW, NAT Gateway, Route Table
├── ecs.tf                   # ECR, ECS Cluster, IAM Role, Task Definition
├── rds.tf                   # RDS 인스턴스, Subnet Group
├── alb.tf                   # Application Load Balancer, Target Groups, Listeners
├── security_groups.tf       # Security Group 정의
├── route53.tf               # Route53 DNS (선택)
├── cloudwatch.tf            # CloudWatch 로그 그룹 및 알람
├── waf.tf                   # AWS WAF 규칙 (선택)
├── secrets.tf               # Secrets Manager
├── terraform.tfstate        # Terraform 상태 파일 (git에서 제외)
└── README.md                # 이 파일
```

---

## 15. 참고 자료

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html#launch-type-fargate)
- [AWS RDS Multi-AZ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)

---

## 16. 참고

- **Notion**: [프로젝트 문서](https://www.notion.so/wsl-31ae46a3dc7d800eafb6f9b2b94a3130?source=copy_link)
