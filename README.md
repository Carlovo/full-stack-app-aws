# AWS serverless full-stack CRUD web application with Terraform

With such a title, who still needs a project description ;)

## Project purpose

This is a continuation of one of my other projects: [Minimal AWS serverless full-stack CRUD web application](https://github.com/Carlovo/minimal-full-stack-app-aws) (mind the word minimal).
This project aims to deploy a more complete serverless app in AWS.
I chose for Terraform, because I find HCL easier to read than CFN YAML/JSON.
Also, I think Terraform gives you a clearer picture of what is going on beneath the blankets than Amplify.

## Deployment

You need programmatic access to an AWS account and have Terraform on your machine to deploy this application.
This app can be deployed using Terraform v1.1.9 with providers aws v4.11.0, archive v2.2.0 and random v3.1.3, but later versions usually work in Terraform as well.

If you don't know Terraform or how to use it, please see [their documentation](https://learn.hashicorp.com/terraform).

### Vanilla

Run the regular `terraform init` and `terraform apply` command and everything should deploy fine.

### Features

You can deploy the app with the following features by using Terraform vars.
It should be possible to deploy any combination of them.

#### Enabling API Gateway logging

Run `terraform apply -var='log_api=true'` and Terraform will enable logging on the API Gateway requests and responses in CloudWatch.
To actually do this, API Gateway needs a role.
There can only be one such role linked to API Gateway per AWS region, so you can skip the next bit if you already have one configured.
Otherwise, add `-var='api_gateway_log_role=true'` and Terraform will configure such a role.
There is no API to remove this coupling in API Gateway, so this stays after a `terraform destroy`, but this should be harmless.
Lambda is configured to log by default.
Terraform will destroy all logs produced upon `destroy`.

#### API throttling / usage quota setting

Run `terraform apply` with `-var='apis_rate_limit=42'` to throttle all API Gateway V1 (CRUD) methods and V2 (Textract) routes if more calls are made per second than the number given.
Note that API Gateway seems to allow slightly more calls than the number given, probably because of eventual consistency in its internal workings.

You may want to further limit the usage of your API over a longer period of time.
Run `terraform apply` with `-var='crud_api_daily_usage_quota=9001'` to throttle all API Gateway V1 (CRUD) methods if more calls are made per day than the number given.
Note that the `OPTIONS` methods are exempt from this behavior, because a browser preflight request cannot use an API key.

#### Textract API

Do you have the things you would like to list in this app in an image format (or on a paper you can make a picture of)?
No problem!
Run `terraform apply` with `-var='textract_api=true'` and all the necessary resources will be deployed that enable the app to upload an image to Amazon Textract and parse the results.

#### Custom domain name

Using this code, you can put a custom domain name from Route53 in front of your website/app as well.
Terraform can not register a domain name in Route53, so that is an extra manual prerequisite.
See [the AWS documentation](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar.html) on how to register a domain name with Route53.
You can create all the required connections between CloudFront and Route53 by then following the steps below.

Run the regular `terraform init` as normal.
Run `terraform apply -var='alternate_domain_name=example.com'` and Terraform will try to connect `example.com` and `www.example.com` to your CloudFront distribution.
Terraform will also try to connect `https://crud-api.cvoad.nl/` and `https://textract-api.cvoad.nl/` to the respective APIs.
The `alternate_domain_name` has to be an apex domain name.

> Note: most AWS resources deployed with this code typically cost no money under bare usage, but this is not the case for custom domain names and other resources in Route53.

#### Connect to multiple tables

Need to keep a shopping list next to your to-do list?
Well that and any other more tables can be deployed at the same time with this code.

Run the regular `terraform init` as normal.
Run `terraform apply -var='tables=["to-do","shopping-list"]'` and Terraform will deploy an extra DynamoDB table to provide you with multiple databases with which the rest of the app can work.
The names in the list are used to generate names of AWS resources, so names must be unique in the list and cannot contain too eccentric characters.

#### Custom page name for the app front end

By default, the app front end is deployed with the URL resource name `index.html`.
If you want something else, you can apply for example with `-var='app_landing_page_name=something-else.html'`.

#### Redirect missing file extensions in resource name to .html

Most websites allow you to navigate to a page without explicitly typing `.html` at the end of the URL.
You can activate such behavior for the domain that is deployed via these templates as well.
Run `terraform apply` with the variable `-var='redirect_missing_file_extension_to_html=true'` and from then on everything ending with a `.`, `/` or no file extension at all will be redirected to the `.html` resource with the same name.
These redirects are performed by CloudFront Functions, so this feature may introduce a little extra latency (and costs if you exceed free tier).

#### Input variable simplification

If you have to often apply a Terraform configuration with a lot of variables (like this one), then getting all the variables correct on the cli can become cumbersome.
This is even more true if you apply over multiple workspaces.
That's why this Terraform code has 'one variable to rule them all': `workspace_variables`.
This variable can contain sets of all sub-variables and can select a set based on the current workspace.
Sets of those variables can then be put in vars file which Terraform reads upon apply.
This greatly simplifies applying a Terraform configuration with a complicated set of variables.
For more explanation and examples see this [blog post](https://dev.to/carlovo/input-variables-file-for-multiple-terraform-workspaces-19f7) and/or [this gist](https://gist.github.com/Carlovo/42dcf2b2f62972891e374699552c14c2).

### Terraform output

Terraform will output the endpoints of the website and API(s) of your app if deployment was successful.
(When using a custom domain name, the CloudFront website endpoint is still available and will be outputted as normal.)
The key to the CRUD API (API usage quota only) is masked by Terraform, because it is sensitive.
It is still added to the output to remind you it is available and to make it more easy to find it in the state file.

The (insecure) S3 endpoint of your website bucket will also be outputted, but this is only useful/available when you set the insecure variable to `true` for faster testing.

## Developing further

You may want to consider the following things if you want to further develop this app.

### Faster testing during development

If you want to test new code, you would have to wait until CloudFront updates.
To temporarily overcome this problem, you can set the Terraform variable `-var='insecure=true'` during `apply`.
This strips all read protection from S3.
(When redeploying the app with this option Terraform might fail during apply because of some racing condition in S3, but rerunning Terraform apply solves this.)
Then you can access your website content via the S3 endpoint immediately after updating.

### Redeploying APIs

Terraform has difficulties detecting when changes in one API Gateway resource should trigger changes in another.
Therefore, this part of the code has a lot of `depends_on` statements.
Also, the `aws_api_gateway_deployment` resource has so many difficulties that only a snippet like below solves it:

``` terraform
triggers = {
    redeployment = filesha1("./resources_stateless_back_end.tf")
  }
```

The Terraform documentation explains these shortcomings as well, so you can read more about it for example [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment).

## Contributing

Please raise an issue or a pull request if you encounter bugs or old/deprecated standards.
Other suggestions are also welcome.
