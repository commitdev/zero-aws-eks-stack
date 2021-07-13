---
title: Cloudfront signed URLs
sidebar_label: Cloudfront signed URLs
sidebar_position: 5
---

Cloudfront Signed URL allows you to control the access to your content through policies . So you can securely distribute content with the access control you set. Letting you set things like expiry date on the URL without having to modify the origin content. 

To use Signed URLs on cloudfront you will have to follow the [AWS documentation to creating a key-pair][creating-key-pairs] which requires having root permission to your AWS account.

If you've answered "yes" to:

> Enable file uploads using S3 and Cloudfront signed URLs? (Will require manual creation of a Cloudfront keypair in AWS)

Then you will need the root AWS account holder to run:

    scripts/import-cf-keypair.sh

This needs to be executed once for the project to setup an AWS secret.
After it has successfully run once, it never needs to run again for this project.


[creating-key-pairs]: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html#private-content-creating-cloudfront-key-pairs