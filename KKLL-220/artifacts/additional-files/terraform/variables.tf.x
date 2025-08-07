# Need to set the variable as follows
# export TF_VAR_kpat=<your kpat>
# export TF_VAR_kpat=$(cat ~/.pat-jaf-kkll-220-1)

variable "kpat" {
  description = "Personal Access Token"
  type        = string
}