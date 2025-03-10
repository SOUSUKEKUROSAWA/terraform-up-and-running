variable "user_names" {
    description = "Create IAM users with these names"
    type = list(string)
    default = ["neo", "trinity", "morpheus"]
    # WARN: 
    # trinityをリストから削除して再度Planすると，
    # trinityがmorpeusにリネームされて，morpeusが削除されてしまう
    # -- countで作成されたリソースは配列として扱われ，そのインデックスで区別されるため
}

variable "give_neo_cloudwatch_full_access" {
    description = "If true, neo gets ful access to CloudWatch"
    type = bool
}