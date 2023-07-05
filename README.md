# Example Custom ServiceNow CNO MID Image

This repo provides an example recipe for a ServiceNow Cloud Native Operations (CNO) MID server container image.  It demonstrates how you can run a modified Linux distribution and JRE within your CNO MID.  It includes an example buildspec.yml file for use with AWS CodeBuild.

To build this image in AWS using CodeBuild, populate the following Secrets Manager secrets:

"dockerhub/pass1":*dockerhub password*
"dockerhub/username1":*dockerhub user name*
"dockerhub/awsacctid":*AWS account ID*

Make sure your codebuild IAM policy has permissions to read and decrypt the "dockerhub/\*" secrets.
