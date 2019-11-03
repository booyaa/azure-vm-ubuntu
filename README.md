# azure-vm-ubuntu

A vm for doing general dev work. Works well with VS Code's Remote Development mode.

Derived from Azure Virtual Machine documentation: [Use automation Tools > Complete a complete VM][az_vm].

## Usage

Caveat: this will cost you money to run.

- clone this repo
- `cp azure.tfvars.example azure.tfvars` # fill in values
- `az login`
- `make plan`
- `make apply` # to deploy
- `make ssh` # to connect via ssh
- `make destroy` # to tear down

## License

See [LICENSE](LICENSE).

## Copyright

Mark Sta Ana &copy; 2019

<!-- linkies -->

[az_vm]: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-create-complete-vm
