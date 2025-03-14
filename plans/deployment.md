# Deployment Plan

### Deployment Build Environment
- See [setup.md](setup.md)
- See [configuration.tf](../terraform/configuration.tf) for other version constraints.

#### Deploy
1. Pull the tag for the version to be deployed
1. Navigate to the scripts directory `scripts`
1. Run `1-tfinit.cmd {env}`
1. Run `2-tfplan.cmd`
   1. Review the plan
   1. Ensure there are no changes to out of scope resources and that all changes are as expected
   1. Continue if it is correct
1. Run `3-tfapply.cmd`
   1. Attach tfplan files to the PR (`terraform\tfplans\{version}_{env}_{iteration}`)
   1. Execute the [Test Plan](/plans/test.md) to ensure the deployment was successful
