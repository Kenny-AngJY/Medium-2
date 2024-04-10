### Check out my article on "How to enforce Termination Protection on your CloudFormation Stacks"
https://medium.com/@kennyangjy/how-to-enforce-termination-protection-on-your-cloudformation-stacks-1831f5229d86

![Automate Enforcing Termination Protection](../CFN-TP.jpg?raw=true "Automate Enforcing Termination Protection")

---
### To provision the resources in this repository:
1. `git clone https://github.com/Kenny-AngJY/Medium-2.git`
2. Change directory to the **Terraform** folder <br> `cd Terraform`
3. `terraform init`
4. `terraform plan` OR `terraform plan -var 'LambdaFunctionName=custom_name'` if you want to overwrite the default value of *LambdaFunctionName*. 
<br> There will be 7 resources to be created.
5. `terraform apply` OR `terraform apply -var 'LambdaFunctionName=custom_name'` <br>
As no backend is defined, the default backend will be local.

### Clean-up
1. `terraform destroy` OR `terraform destroy -var 'LambdaFunctionName=custom_name'`