# **Final Stack**

This stack, built in Terraform illustrates an initial infrastructure stack that could be adapted for production level use. It deploys Redmine in a highly available cluster and makes use of RDS for it database.

**Components**

1. VPC
    - Public and Private Subnets
    - IGW
    - Security Groups and Network ACLs
    - Flow logs   
2. EC2 Instances
    - Bastion Host for SSH access
    - Application Instances in an Auto Scale Group 
3. RDS - using Aurora/MySQL
4. EFS
5. ALB

**Choices and Comments**

VPC

Network 198.18.0.0/16 (Non-Routable per RFC 2544)

For subnets, I split this supernet in half logically; all public subnets fall in 198.18.0.0/17 and all private subnets are in 198.18.128.0/17

- left application instances in public subnets with public ips, and limit access with security groups and nacls. Alternatively, a NAT Gateway could be used without a IGW along with adding a new routing table. NATGW and LB would still need a route to an IGW.


EC2 Instances
- Latest Amazon AMI used
- see ASG launch config for bash script values to install docker mount efs and start application

    Bastion - I deployed this out of simplicity to follow the good practice of not having web servers directly accessible if not needed. VPNing into a management VPC would be better.


RDS

I deployed Aurora/MySQL engine in a two node configuration.  Redmine documentation indicated that version 5.6 and 5.7 are not fully supported with some open bugs currently.  Based on the open bugs I rolled with version 5.6.34. My initial thought was to use IAM policies for access and this was the oldest version one could use and still get that feature. Unfortunately I look longer on some other aspects of the setup and did not make use of this.

EFS

I figured a cluster application isn't very useful without a shared filesystem. After reading the Docs, Redmine has several directories that would need to be centralized on shared storage; I chose to focus on the ./files directory where any user uploaded data is stored. for the scope of this project I was not going to be concerned with logs and extending functionality with plugins.

ALB

I chose the ALB instead of the classic LB or Network LB because I had grand visions of setting up sub-domain in Route-53 and assigning certs via ACM and writing rules to redirect traffic from HTTP->HTTPS 


Things That I Didn't Get To

- Credential store  I don't like using fixed key pairs.  In CF I use Credstash to store and retrieve keys for EC2 and other such artifacts
- Redmine connects to the DB using master admin credentials currently. This is not ideal and should be a seprate, lower privledge user
- file encryption, using KMS keys EFS and RDS should be encrypted at minimum.
