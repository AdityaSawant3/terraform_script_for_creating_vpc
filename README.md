This repo contains VPC creation with the help of terraform scripts and launching instances. Both in public and private subnets.

Key take aways from this IaC for VPC.

whenever the inbound or ingrees rule is defined you must explicitly define outbound or egress rule, in normal AWS console you don't need to define the outbound rule.
