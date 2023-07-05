# Example Custom ServiceNow CNO MID Image

This repo provides an example recipe for a ServiceNow Cloud Native Operations (CNO) MID server container image.  It demonstrates how you can run a modified Linux distribution and JRE within your CNO MID.  It includes an example buildspec.yml file for use with AWS CodeBuild.

To build this image in AWS using CodeBuild, populate a Secrets Manager secret named "dockerhub" with the following JSON payload:

{
"pass1":*dockerhub password*,
"awsacctid":*AWS account ID*,
"username1":*dockerhub user name*
}

Make sure your codebuild IAM policy has permissions to read and decrypt the "dockerhub" secret.
