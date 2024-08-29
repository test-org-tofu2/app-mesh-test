# app-mesh-test

Steps to reproduce the issue:
1. Run `tofu init` (or `terraform init`)
2. Uncomment the `v6` section (lines 19-21) in main.tf
3. Run `tofu apply` (or `terraform apply`)
4. Comment out the `v6` section (lines 19-21) in main.tf
5. Run `tofu apply` (or `terraform apply`)

You will see the following error:


aws_appmesh_virtual_node.canary["v6"]: Destroying... [id=16a2bc64-edaa-4039-a329-4c2fb9d7f89d]
╷
│ Error: deleting App Mesh Virtual Node (16a2bc64-edaa-4039-a329-4c2fb9d7f89d): operation error App Mesh: DeleteVirtualNode, https response error StatusCode: 409, RequestID: a1c2eeff-0f75-467f-afb3-fc26577488da, ResourceInUseException: VirtualNode with name VirtualNodev6-9d25709fbcea cannot be deleted because it is the target of one or more routes.
│
