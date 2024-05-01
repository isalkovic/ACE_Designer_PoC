# ACE_Designer_PoC
Playing with ACE Designer automation

# Changes in local-bar branch:
using a locally uploaded BAR file instead of pointing to a git repo.

Instead of creating an integration server with a barURL that points to a remote repository, we upload a BAR file to the ACE dashboard first, and then create the integration server with the ACE dashboard URL location.

This means that a barauth configuration is no longer needed (and creating a server which points to a local BAR file *and* has a barauth configuration will fail), but that the barURL in the spec must be changed to the ACE dashboard url.

To do this; we use ' jq', which must be available on the local workstation.
