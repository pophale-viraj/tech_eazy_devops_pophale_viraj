# tech_eazy_devops_pophale_viraj
Lift and Shift


Steps to be taken
Infrastructure provisioning -- terraform(main.tf, variables.tf, outputs.tf, terraform.tfvars)
main.tf -- ec2 provision, provider information
variables.tf -- datatypes alongwith all variables used in main.tf
output.tf -- print ec2 ip_address
terraform.tfvars -- variable values

Steps to take in Terraform(VS Code):
terraform fmt -- aligns your code
terraform init -- installs terraform locally
terraform validate -- ensure code is validated
terraform plan -- provide infrastructure blueprint
terraform apply -- creates ec2 on aws
terraform destroy -- destroys ec2 from aws
terraform state list -- enlists online aws entities

Raw code movement from java.class --java.jar -- artefact creation:
New repo creation for storing raw code of the application https://github.com/pophale-viraj/tech_eazy_devops_pophale_viraj/
Create a local copy of ready code -- git clone https://github.com/Trainings-TechEazy/test-repo-for-devops

Steps to take in IntelliJ Idea:
Open the downloaded raw code for code packaging in IntelliJ and further compile/test/package/push to jenkins/deploy to ubuntu target server
Set the origin of code to self remote repo. Doing this enables your code to be pushed to the remote repository https://github.com/pophale-viraj/tech_eazy_devops_pophale_viraj/
Run:
mvn clean compile
mvn clean package
run spring-boot:run
On the local browser open the application http://localhost:8080
git pull origin master
git add --all
git commit -m 'Code push'
git push origin master

On Jenkins, ensure the IP is updated, plugins are installed, system configured, credentials setup correctly; github webhook will trigger the Jenkins pipeline once all parameters are met
