resource "aws_ecr_repository" "patient" {
  name                 = "patient-service"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Service = "patient-service" }
}
