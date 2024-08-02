# asg-enable-router

A Terraform module to deploy a lambda that disables the `source-dest-check` attribute for EC2 instances in an autoscaling group. When this attribute is `true`, as is the default, EC2 will drop packets whose source or destination is not the instance. Instances that act as routers must be able to send and receive such traffic, so when this function is deployed, it will automatically disable the attribute for any instances launched in the autoscaling group.

The function should be deployed before the autoscaling group so it can trigger when instances are launched. See the example below using `depends_on` to ensure this.

# Example

```
locals {
  asg_name = "acme"
}

module "enable_router" {
  source  = "cloudboss/asg-enable-router/aws"
  version = "x.x.x"

  autoscaling_group_name = local.asg_name
  name                   = "${local.asg_name}-enable-router"
}


module "asg" {
  source  = "cloudboss/asg/aws"
  version = "0.1.0"

  name = local.asg_name
  ...

  depends_on = [module.enable_router]
}
```

# Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| autoscaling\_group\_name | Name of the autoscaling group. | string | N/A | yes |
| iam\_permissions\_boundary | The ARN of an IAM policy to use as a permissions boundary for the IAM role. | string | `null` | no |
| memory\_size | The amount of memory assigned to the lambda. | number | `256` | no |
| name | The name of the lambda and other cloud resources. | string | N/A | yes |
| runtime | The lambda runtime. | string | `python3.12` | no |
| tags | Tags to assign to cloud resources. | map(string) | `{}` | no |
| vpc\_config | Configuration for a VPC. If not defined, the lambda will not have VPC access. | [object](#vpc_config-object) | `null` | no |

## vpc_config object

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| id | ID of the VPC. | string | N/A | yes |
| subnet\_ids | IDs of subnets in which to deploy the lambda network interface. | list(string) | N/A | yes |

# Outputs

| Name | Description |
|------|-------------|
| event\_rule | EventBridge rule object. |
| iam\_policy | IAM policy object. |
| iam\_role | IAM role object. |
| lambda | Lambda function object. |
