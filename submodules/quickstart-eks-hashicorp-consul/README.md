# HashiCorp Consul on Amazon EKS

> This Quick Start was created by [HashiCorp](https://hashicorp.com) in collaboration with 
> Amazon Web Services (AWS). [AWS Quick Starts](https://aws.amazon.com) are automated 
> reference deployments that use AWS CloudFormation templates to deploy key technologies on AWS, following AWS best 
> practices. 

## Overview
This Quick Start helps you to deploy HashiCorp Consul servers and clients via Consul Helm chart on Amazon Elastic
 Kubernetes Service (Amazon EKS). HashiCorp Consul is a tool that provides the foundation of cloud networking automation
 using a central registry for service-based networking. Consul's core use cases include:
* Service registry & health monitoring, to provide a real-time directory of all services with their health status;
* Network middleware automation, with service discovery for dynamic reconfiguration as services scale up, down or move;
* Zero trust network with service mesh, to secure service-to-service traffic with identity-based security policies and
 encrypted traffic with Mutual-TLS.

HashiCorp Consul is designed for service networking professionals and application developers who want to securely connect
services, monitor, and automate them. It's deployed via [Consul Helm chart](https://github.com/hashicorp/consul-helm), 
which contains all of the resource definitions to install and configure Consul inside of a Kubernetes cluster.
Each stack in this deployment takes approximately 20 minutes to create.
For more information and step-by-step deployment instructions, see the [deployment guide](<https link to deployment guide>).

This Quick Start reference deployment guide provides step-by-step instructions for deploying HashiCorp Consul on Amazon EKS. 

> Please know that we may share who uses AWS Quick Starts with the AWS Partner Network (APN) Partner that collaborated 
> with AWS on the content of the Quick Start.

## Target Audience 

Service networking professionals and application developers who want to securely connect
services, monitor, and automate them on Amazon EKS.

## Architecture

Deploying this Quick Start with default parameters into an existing Amazon EKS cluster builds the following environment. 
For a diagram of the new VPC and new EKS cluster deployment options, see the 
[Amazon EKS Quick Start documentation](https://docs.aws.amazon.com/quickstart/latest/amazon-eks-architecture/architecture.html).
 
![Consul architecture diagram](docs/images/architecture_eks_consul.png)
*Figure 1: Quick Start architecture for HashiCorp Consul on Amazon EKS*

As shown in Figure 1, the Quick Start sets up the following:
* In AWS:
  * Application Load Balancer.
  * Amazon Certificate Manager(ACM) certificate.
* In Kubernetes:
  * namespace for Consul.
  * Kubernetes secret containing gossip Consul integration ID and docker config json.
  * Consul services:
    * mesh-gateway
    * consul-server
    * consul-dns
    * consul-ui
  * Dedicated Consul server nodes.
  * ALB ingress controller.
  * Consul connect-injector.

## Cost and licenses

You are responsible for the cost of the AWS services used while running this Quick Start reference deployment. 
There is no additional cost for using the Quick Start.

The AWS CloudFormation template for this Quick Start includes configuration parameters that you can customize. 
Some of these settings may affect the cost of deployment. For cost estimates, see the pricing pages for each AWS 
service you will use. Prices are subject to change.

> Tip: We recommend that you enable the AWS Cost and Usage Report. This report delivers billing metrics to an Amazon 
> Simple Storage Service (Amazon S3) bucket in your account. It provides cost estimates based on usage throughout each 
> month and finalizes the data at the end of the month. For more information about the report, see the AWS 
> documentation.

## Planning the deployment

### Specialized knowledge

This Quick Start assumes familiarity with Amazon EKS, AWS CloudFormation and Kubernetes.

### AWS account

If you don’t already have an AWS account, create one at https://aws.amazon.com by following the on-screen instructions. 

### EKS cluster

If you are deploying onto an existing EKS cluster that was **not** created by the Amazon EKS Quick Start, you will need 
to configure the cluster to allow this Quick Start to manage your EKS cluster. The requirements are detailed in Step 2
of the *Deployment steps* section of this document.

	
## Deployment options

This Quick Start provides three deployment options:
* Deploy Consul into a new VPC (end-to-end deployment). This option builds a new AWS environment consisting of 
the VPC, subnets, NAT gateways, security groups, bastion hosts, EKS cluster, a node group, and other infrastructure 
components. It then deploys Consul into this new EKS cluster.
* Deploy Consul into a new EKS cluster in an existing VPC. This option builds a new AWS EKS cluster, a node 
group, and other infrastructure components into an existing VPC. It then deploys Consul into this new EKS cluster.
* Deploy Consul into an existing EKS cluster. This option provisions Consul in your existing AWS infrastructure.


## Deployment steps

### Step 1. Sign in to your AWS account

1. Sign in to your AWS account at https://aws.amazon.com with an IAM user role that has the necessary permissions. 
For details, see Planning the deployment earlier in this guide. 
2. Make sure that your AWS account is configured correctly, as discussed in the *Technical requirements* section.

### Step 2. Prepare existing EKS cluster

> Note: This step is only required if you are launching this Quick Start into an existing EKS cluster that was **not** 
> created using the Amazon EKS Quick Start. If you would like to create a new EKS cluster with your deployment, skip to 
> step 3.

1. Sign in to your AWS account, and launch the 
[cluster preparation template](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/template?stackName=Amazon-EKS&templateURL=https://s3.amazonaws.com/aws-quickstart/quickstart-amazon-eks/templates/amazon-eks-entrypoint-existing-cluster.template.yaml).
2.	The template is launched in the N. Virginia (us-east-1) AWS Region by default. To change the Region choose another Region 
from list in the upper-right corner of the navigation bar.
3. On the Create stack page, keep the default setting for the template URL, and then choose Next.
4. On the Specify stack details page, change the stack name if needed. Enter the name of the EKS cluster you would like 
to deploy to, as well as the Subnet ID's and security group ID associated with the cluster. These can be obtained from 
the EKS Cluster console.
5. On the options page, you can specify tags (key-value pairs) for resources in your stack and set advanced options. When you’re done, choose Next.
6. On the Review page, review and confirm the template settings. Under Capabilities, select the two check boxes to acknowledge that the template creates IAM resources and might require the ability to automatically expand macros.
7. Choose Create stack to deploy the stack.
8. Monitor the status of the stack until the status reaches CREATE_COMPLETE.
9. From the *Outputs* section of the stack, note the KubernetesRoleArn and the HelmRoleArn.
10. Add the roles to the aws-auth config map in your cluster, specifying *system:masters* for the groups, by following 
the steps in the [EKS documentation](). This allows the Quick Start to manage your cluster via AWS CloudFormation.

### Step 3. Launch the Quick Start

> Note: You are responsible for the cost of the AWS services used while running this Quick Start reference deployment. 
> There is no additional cost for using this Quick Start. For full details, see the pricing pages for each AWS service 
> used by this Quick Start. Prices are subject to change.

1. Sign in to your AWS account, and choose one of the following options to launch the AWS CloudFormation template. 
For help with choosing an option, see deployment options earlier in this guide.

| [![New VPC](docs/images/deploy1.png)](https://fwd.aws/V7d9d) | [![Existing VPC](docs/images/deploy2.png) ](https://fwd.aws/98zVN) | [![Existingcluster](docs/images/deploy3.png)](https://fwd.aws/geqmr) |
| :---: | :---: | :---: |
| [Deploy into a new VPC and new EKS cluster](https://fwd.aws/V7d9d) | [Deploy into a new EKS cluster in an existing VPC](https://fwd.aws/98zVN) | [Deploy into an existing EKS cluster](https://fwd.aws/geqmr) |

Each new cluster deployments takes about 2 hours to complete. Existing cluster deployments take around 10 minutes.

2.	The template is launched in the N. Virginia (us-east-1) AWS Region by default. To change the Region choose another Region 
from list in the upper-right corner of the navigation bar.
3. On the Create stack page, keep the default setting for the template URL, and then choose Next.
4. On the Specify stack details page, change the stack name if needed. Review the parameters for the template, a 
reference is provided in the *Parameters* section of this document. Provide values for the parameters that require 
input. For all other parameters, review the default settings and customize them as necessary. When you finish reviewing 
and customizing the parameters, choose Next.
5. On the options page, you can specify tags (key-value pairs) for resources in your stack and set advanced options. 
When you’re done, choose Next.
6. On the Review page, review and confirm the template settings. Under Capabilities, select the two check boxes to 
acknowledge that the template creates IAM resources and might require the ability to automatically expand macros.
7. Choose Create stack to deploy the stack.
8. Monitor the status of the stack. When the status is CREATE_COMPLETE, the Consul cluster is ready.

### Step 4. Test the deployment

These are the items to test after the quickstart is deployed.
* Kubernetes Consul deployment namespace and dedicated node selection:
  The deployment creates a namespace named `consul-server` by default. To verify the namespace in kuberkenes, please 
  run the following:
  ```
  $ kubectl get ns
  NAME              STATUS   AGE
  default           Active   3h24m
  kube-node-lease   Active   3h24m
  kube-public       Active   3h24m
  kube-system       Active   3h24m
  consul-server      Active   3h9m
  ```
  The deployment builds kuberntes server pods of the `consul-server` namespace on dedicated nodes. To verify the dedicated nodes,
  please run the following:
  ```
  $ kubectl get pods -o wide -n consul-server
  NAME                                                              READY   STATUS      RESTARTS   AGE     IP            NODE                                        NOMINATED NODE   READINESS GATES
  consul-1602814488-consul-6znks                                    1/1     Running     0          3h23m   10.0.31.27    ip-10-0-14-63.us-west-2.compute.internal    <none>           <none>
  consul-1602814488-consul-7dwxk                                    1/1     Running     0          3h23m   10.0.33.58    ip-10-0-55-7.us-west-2.compute.internal     <none>           <none>
  consul-1602814488-consul-962dw                                    1/1     Running     0          3h23m   10.0.95.110   ip-10-0-78-177.us-west-2.compute.internal   <none>           <none>
  consul-1602814488-consul-connect-injector-webhook-deploymekjtd9   1/1     Running     0          3h23m   10.0.45.224   ip-10-0-55-7.us-west-2.compute.internal     <none>           <none>
  consul-1602814488-consul-hgmt8                                    1/1     Running     0          3h23m   10.0.80.164   ip-10-0-83-89.us-west-2.compute.internal    <none>           <none>
  consul-1602814488-consul-mesh-gateway-b66ffc55b-mvtv2             2/2     Running     0          3h23m   10.0.49.86    ip-10-0-55-7.us-west-2.compute.internal     <none>           <none>
  consul-1602814488-consul-mesh-gateway-b66ffc55b-qg4ns             2/2     Running     0          3h23m   10.0.26.238   ip-10-0-14-3.us-west-2.compute.internal     <none>           <none>
  consul-1602814488-consul-mesh-gateway-b66ffc55b-vvtq7             2/2     Running     0          3h23m   10.0.80.70    ip-10-0-83-89.us-west-2.compute.internal    <none>           <none>
  consul-1602814488-consul-mxkrr                                    1/1     Running     0          3h23m   10.0.34.78    ip-10-0-34-50.us-west-2.compute.internal    <none>           <none>
  consul-1602814488-consul-server-0                                 1/1     Running     0          3h23m   10.0.13.78    ip-10-0-14-3.us-west-2.compute.internal     <none>           <none>
  consul-1602814488-consul-server-1                                 1/1     Running     0          3h23m   10.0.95.234   ip-10-0-83-89.us-west-2.compute.internal    <none>           <none>
  consul-1602814488-consul-server-2                                 1/1     Running     0          3h23m   10.0.56.52    ip-10-0-55-7.us-west-2.compute.internal     <none>           <none>
  consul-1602814488-consul-sync-catalog-5bc656b68d-hvfv8            1/1     Running     0          3h23m   10.0.68.153   ip-10-0-83-89.us-west-2.compute.internal    <none>           <none>
  consul-1602814488-consul-zxj8m                                    1/1     Running     0          3h23m   10.0.9.167    ip-10-0-14-3.us-west-2.compute.internal     <none>           <none>
  generate-gossip-secret-sg-087bc91b3b3c5dc0d-vqg6j                 0/1     Completed   0          3h25m   10.0.49.86    ip-10-0-55-7.us-west-2.compute.internal     <none>           <none>
  ```

* Kubernetes services:
  The deployment creates a minimum of 7 services as follows:
  ```
  $ kubectl get svc -n consul-server
  NAME                                            TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S) 
  consul-1602814488-consul-connect-injector-svc   ClusterIP      172.20.81.243    <none>                                                                   443/TCP 
  consul-1602814488-consul-dns                    ClusterIP      172.20.180.148   <none>                                                                   53/TCP,53/UDP
  consul-1602814488-consul-mesh-gateway           LoadBalancer   172.20.121.116   a5372b3698926442585aa5eb6b5d6cee-315665803.us-west-2.elb.amazonaws.com   443:30551/TCP
  consul-1602814488-consul-server                 ClusterIP      None             <none>                                                                   8501/TCP,8301/TCP,8301/UDP,8302/TCP,8302/UDP,8300/TCP,8600/TCP,8600/UDP
  consul-1602814488-consul-ui                     NodePort       172.20.249.130   <none>                                                                   443:32732/TCP
  k8sconsul                                       ExternalName   <none>           consul.service.consul                                                    <none>
  k8smesh-gateway                                 ExternalName   <none>           mesh-gateway.service.consul                                              <none>
  ```

* Consul agent TLS encryption:
  Verify the deployment configuration by running:
  ```
  $ kubectl get deploy -n consul-server -o yaml
  ```
  Then observe the volume mounts for each pod:
  ```
  volumeMounts:
  - mountPath: /consul/tls/ca
    name: consul-ca-cert
  - mountPath: /consul/tls/client/ca
    name: consul-auto-encrypt-ca-cert
  ```

* Consul UI SSL certificate:
  This is done by verifying the DNS endpoint of the deployment and checking for the SSL cert installation
  ```
  $ openssl s_client -connect  lonconsul.gargana.myinstance.com:443
  CONNECTED(00000007)
  depth=2 C = US, O = Amazon, CN = Amazon Root CA 1
  verify return:1
  depth=1 C = US, O = Amazon, OU = Server CA 1B, CN = Amazon
  verify return:1
  depth=0 CN = lonconsul.gargana.myinstance.com
  verify return:1
  ---
  Certificate chain
  0 s:CN = lonconsul.gargana.myinstance.com
    i:C = US, O = Amazon, OU = Server CA 1B, CN = Amazon
  1 s:C = US, O = Amazon, OU = Server CA 1B, CN = Amazon
    i:C = US, O = Amazon, CN = Amazon Root CA 1
  2 s:C = US, O = Amazon, CN = Amazon Root CA 1
    i:C = US, ST = Arizona, L = Scottsdale, O = "Starfield Technologies, Inc.", CN = Starfield Services Root Certificate Authority - G2
  3 s:C = US, ST = Arizona, L = Scottsdale, O = "Starfield Technologies, Inc.", CN = Starfield Services Root Certificate Authority - G2
    i:C = US, O = "Starfield Technologies, Inc.", OU = Starfield Class 2 Certification Authority
  ---
  Server certificate
  -----BEGIN CERTIFICATE-----
  MIIFrDCCBJSgAwIBAgIQA+/KZ0HG5aT6xAZLv0NjlDANBgkqhkiG9w0BAQsFADBG
  MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRUwEwYDVQQLEwxTZXJ2ZXIg
  Q0EgMUIxDzANBgNVBAMTBkFtYXpvbjAeFw0yMDEwMTUwMDAwMDBaFw0yMTExMTMy
  MzU5NTlaMCsxKTAnBgNVBAMTIGxvbmNvbnN1bC5nYXJnYW5hLm15aW5zdGFuY2Uu
  Y29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7ZwqhfY7fU/ui+i6
  WCGffE/Dl+upf6W9aoiLU+8T7PxI0Pgr30uNPmXHfrYGlqUVAfwAWrfAKKGShuGZ
  hhmg18YpRIo0aMdYaIDv8RBj8dwDMF0ACpYfPZvFtKkO3RN/2sn6ApWDeD8cN9lq
  bOCTZHDH6QMMxgK3FrmtG9OyjeOQUe2k39KjAjwP3KKFxW88QP51Q0lHXyd45zzG
  jcQOZFlOdF+y9QNTRr1FBbCUm5mGpZseWs2/wU1fO7mOuuvzxmmYZ1d4kfwk8dXQ
  Zm242e0weXgiLuj0Q4rbkxsoYhJ1XAvFSxXV/SItvpsR7hGslKrdrRKSS1AvsrVU
  DGoSzwIDAQABo4ICrzCCAqswHwYDVR0jBBgwFoAUWaRmBlKge5WSPKOUByeWdFv5
  PdAwHQYDVR0OBBYEFNMAPyPH6TYMka68RiDI+ON5cWLNME8GA1UdEQRIMEaCIGxv
  bmNvbnN1bC5nYXJnYW5hLm15aW5zdGFuY2UuY29tgiIqLmxvbmNvbnN1bC5nYXJn
  YW5hLm15aW5zdGFuY2UuY29tMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggr
  BgEFBQcDAQYIKwYBBQUHAwIwOwYDVR0fBDQwMjAwoC6gLIYqaHR0cDovL2NybC5z
  Y2ExYi5hbWF6b250cnVzdC5jb20vc2NhMWIuY3JsMCAGA1UdIAQZMBcwCwYJYIZI
  AYb9bAECMAgGBmeBDAECATB1BggrBgEFBQcBAQRpMGcwLQYIKwYBBQUHMAGGIWh0
  dHA6Ly9vY3NwLnNjYTFiLmFtYXpvbnRydXN0LmNvbTA2BggrBgEFBQcwAoYqaHR0
  cDovL2NydC5zY2ExYi5hbWF6b250cnVzdC5jb20vc2NhMWIuY3J0MAwGA1UdEwEB
  /wQCMAAwggEDBgorBgEEAdZ5AgQCBIH0BIHxAO8AdQD2XJQv0XcwIhRUGAgwlFaO
  400TGTO/3wwvIAvMTvFk4wAAAXUtvpNMAAAEAwBGMEQCIBQqjFHMQDxoeaxhwJlD
  dmELOU0v1+2jPvKbxgnS9Sr2AiArQ+SOeM3bTpnY7BBX9ue2+z16KZaHuan+PB/L
  FmqhBgB2AFzcQ5L+5qtFRLFemtRW5hA3+9X6R9yhc5SyXub2xw7KAAABdS2+k5sA
  AAQDAEcwRQIhAOUW8k67YCzwqxx/pVYIzR5heOqYsqCW/6nRFkyECj6YAiA3007S
  pf7GzxULAaTAwQjpnvb/d/tu2O9VxqTxLoSTPjANBgkqhkiG9w0BAQsFAAOCAQEA
  nwKKUxQ+VDDKbh93XJ8mdhXYGHk8R9MH/HUprH9i2JSVovTYabo+kk8HC5Vo0Pwu
  NOEMjRe008xraTpAzfSjr2fupjltJB6lXehPe5sJaWPJ0mX3OBt4VyfrO6MYdmpy
  iGLhMXM357+CN75aMv1BD4pVA+a75dhvcUOfZCni4guQ+7wbbwONrKdwtg9FudWf
  XzvTdg1Q8VPfuQWUJb8tmITseg+8KDTyUn1u2SiNWHj17hBTSBTjkVt97id0BtZ/
  UYrBWVldmJw0pJ6XYgQc6pBg6A86390sGkRzOfhYkT8AIbKNKSwtCRV0aBY2Nb4+
  i81nP0KKeSvWcRf4/Gj+WA==
  -----END CERTIFICATE-----
  subject=CN = lonconsul.gargana.myinstance.com

  issuer=C = US, O = Amazon, OU = Server CA 1B, CN = Amazon

  ---
  ```

* Envoy proxy client leaf certificate exchange:
  In order to check the leaf certificate generation a the proxy endpoints, you will need to deploy at least one dummy service and its `envoy`
  proxy. To learn more, please read  [Secure Applications with Service Sidecar Proxies](https://learn.hashicorp.com/tutorials/consul/service-mesh-application-secure-networking).
  For instance, to  check on the `web` envoy proxy, run the following:
  ```
  $ kubectl -n consul-server  exec  -it consul-1602814488-consul-server-0 -- /bin/sh
  / # consul catalog services
  api
  api-sidecar-proxy
  consul
  consulconsul-1602814488-consul-connect-injector-svc-vault-server
  consulconsul-1602814488-consul-dns-vault-server
  consulconsul-1602814488-consul-mesh-gateway-vault-server
  consulconsul-1602814488-consul-server-vault-server
  consulconsul-1602814488-consul-ui-vault-server
  consulkube-dns-kube-system
  consulkubernetes-default
  consulweb-vault-server
  mesh-gateway
  web
  web-sidecar-proxy
  / # curl -ks https://127.0.0.1:8501/v1/agent/connect/ca/leaf/web-sidecar-proxy | jq
  {
    "SerialNumber": "1a",
    "CertPEM": "-----BEGIN CERTIFICATE-----\nMIICYDCCAgagAwIBAgIBGjAKBggqhkjOPQQDAjAxMS8wLQYDVQQDEyZwcmktMTVv\nYXZxMHIuY29uc3VsLmNhLjNjN2YzM2U3LmNvbnN1bDAeFw0yMDEwMTkyMTQ3NDZa\nFw0yMDEwMjIyMTQ3NDZaMDYxNDAyBgNVBAMTK3dlYnNpZGVjYXJwcm94eS5zdmMu\nZGVmYXVsdC4zYzdmMzNlNy5jb25zdWwwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNC\nAATZ2PTll8KrJxSmOvOf3eVvXbuUlCNvrAatL+v+/i+B4doGWY+r8a0zGMYVgYJj\nglOPRYzPxEnAnqR9OYP9ao52o4IBCDCCAQQwDgYDVR0PAQH/BAQDAgO4MB0GA1Ud\nJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMCkGA1UdDgQi\nBCCpMMDV6WJdbaLk+giLOOZ9qEgXffbs1DtvFHvqK34PpDArBgNVHSMEJDAigCBg\nM4sn0idMnqzXCFldTIhkymtM/YjX+Su2T6p+BfQe8jBtBgNVHREEZjBkhmJzcGlm\nZmU6Ly8zYzdmMzNlNy04NDcyLTk4M2YtNzJlMi02ZjE2OTlkNTE1NjQuY29uc3Vs\nL25zL2RlZmF1bHQvZGMvdXMtd2VzdC0yL3N2Yy93ZWItc2lkZWNhci1wcm94eTAK\nBggqhkjOPQQDAgNIADBFAiEAkE4G+I42DtHX26+DrXCfzjXmvIKA1qDXYHdGYN3/\nSmACIGJwwxfltaME49SW99rnrhSoDVeTy5tnyX1gc6R2JtWU\n-----END CERTIFICATE-----\n",
    "PrivateKeyPEM": "-----BEGIN EC PRIVATE KEY-----\nMHcCAQEEIJKcR1omVjHnfKkV/UFVw3vOFkqzhYKxFkDrRgiWWZRGoAoGCCqGSM49\nAwEHoUQDQgAE2dj05ZfCqycUpjrzn93lb127lJQjb6wGrS/r/v4vgeHaBlmPq/Gt\nMxjGFYGCY4JTj0WMz8RJwJ6kfTmD/WqOdg==\n-----END EC PRIVATE KEY-----\n",
    "Service": "web-sidecar-proxy",
    "ServiceURI": "spiffe://3c7f33e7-8472-983f-72e2-6f1699d51564.consul/ns/default/dc/us-west-2/svc/web-sidecar-proxy",
    "ValidAfter": "2020-10-19T21:47:46Z",
    "ValidBefore": "2020-10-22T21:47:46Z",
    "CreateIndex": 428260,
    "ModifyIndex": 428260
  }
  ```

* Consul raft peer election:
  To check on the  raft peer election status, run the following:
  ```
  $ kubectl -n consul-server  exec  -it consul-1602814488-consul-server-0 -- /bin/sh
  / # consul operator raft list-peers
  Node                               ID                                    Address           State     Voter  RaftProtocol
  consul-1602814488-consul-server-1  bfd1069d-4780-be4f-6229-4b7a7309e88c  10.0.95.234:8300  leader    true   3
  consul-1602814488-consul-server-2  fc329572-3f74-7488-6885-f50769a5c5a1  10.0.56.52:8300   follower  true   3
  consul-1602814488-consul-server-0  9162e175-e79f-9a0b-3ae1-ad7a08ee8fe7  10.0.13.78:8300   follower  true   3
  ```

* Consul auto-pilot:
  To check on the Consul auto-pilot configuration, run the following:
  ```
  $ kubectl -n consul-server  exec  -it consul-1602814488-consul-server-0 -- /bin/sh
  / # curl -ks https://127.0.0.1:8501/v1/operator/autopilot/configuration | jq
  {
    "CleanupDeadServers": true,
    "LastContactThreshold": "200ms",
    "MaxTrailingLogs": 250,
    "MinQuorum": 0,
    "ServerStabilizationTime": "10s",
    "RedundancyZoneTag": "",
    "DisableUpgradeMigration": false,
    "UpgradeVersionTag": "",
    "CreateIndex": 5,
    "ModifyIndex": 5
  }
  ```

### Best practices for using Consul on AWS

These are the best best practices for using Consul on AWS. Please note that these best practices are enabled by default in this
quickstart:

* Enable Consul ACL's for token-based authentication. This will enable users to provide a token to autheticate and access Consul
control plane and API's. To learn more, please  visit [Secure Consul with Access Control Lists (ACLs)](https://learn.hashicorp.com/tutorials/consul/access-control-setup-production)

* Enable Gossip encryption. Gossip encryption will make sure the ACL authentication between server and client agents (RPC)
are protected from sniffing. To learn  more, please  visit [Secure Gossip Communication with Encryption](https://learn.hashicorp.com/tutorials/consul/gossip-encryption-secure?in=consul/security-networking#gossip-encryption)

* Enable Agent TLS encryption. Consul supports using TLS to verify the authenticity of servers and clients. To learn more,
please visit [Secure Consul Agent Communication with TLS Encryption](https://learn.hashicorp.com/tutorials/consul/tls-encryption-secure?in=consul/security-networking)

* Enabled SSL certificate on Consul agents. This will protect the Consul agent communication from attacks. To learn more, please visit [Secure Consul Agent Communication with TLS Encryption and OpenSSL Certificates](https://learn.hashicorp.com/tutorials/consul/tls-encryption-openssl-secure?in=consul/day-2-agent-authentication)

* Enable Connect Inject and gRPC protocol. This enables Envoy proxy at the client pods and gRPC is necessary. To learn more, please visit [Secure Service Communication with Consul Service Mesh and Envoy](https://learn.hashicorp.com/tutorials/consul/service-mesh-with-envoy-proxy#enable-connect-and-grpc)

## FAQ
**Q**. I encountered a CREATE_FAILED error when I launched the Quick Start. 

**A**. If AWS CloudFormation fails to create the stack, we recommend that you relaunch the template with Rollback on 
failure set to No. (This setting is under Advanced in the AWS CloudFormation console, Options page.) With this setting, 
the stack’s state is retained and the instance is left running, so you can troubleshoot the issue. 

> Important: When you set Rollback on failure to No, you continue to incur AWS charges for this stack. Please make sure 
> to delete the stack when you finish troubleshooting.

For general EKS troubleshooting steps see the 
[EKS Quick Start documentation](https://docs.aws.amazon.com/quickstart/latest/amazon-eks-architecture/). 

For Consul specific troubleshooting see 
[Consul troubleshooting documentation](https://learn.hashicorp.com/tutorials/consul/troubleshooting).

For additional information, see Troubleshooting AWS CloudFormation on the AWS website. 

## Send us feedback

To post feedback, submit feature ideas, or report bugs, use the 
[Issues](https://github.com/aws-quickstart/quickstart-eks-hashicorp-consul/issues) section of the GitHub repository for this Quick 
Start. If you’d like to submit code, please review the Quick Start Contributor’s Guide.

## Additional resources

### AWS resources

* [Getting Started Resource Center](https://aws.amazon.com/getting-started/)
* [AWS General Reference](https://docs.aws.amazon.com/general/latest/gr/)
* [AWS Glossary](https://docs.aws.amazon.com/general/latest/gr/glos-chap.html)

### AWS services

* [AWS CloudFormation](https://docs.aws.amazon.com/cloudformation/)
* [Amazon EKS](https://aws.amazon.com/eks/)
* [IAM](https://docs.aws.amazon.com/iam/)
* [Amazon VPC](https://docs.aws.amazon.com/vpc/)

### Consul documentation

* [Consul Kubernetes integration](https://www.consul.io/docs/k8s)

### Other Quick Start reference deployments

* [AWS Container Quick Start home page](https://aws.amazon.com/quickstart/?quickstart-all.sort-by=item.additionalFields.updateDate&quickstart-all.sort-order=desc&awsf.quickstart-homepage-filter=categories%23containers)
* [AWS Quick Start home page](https://aws.amazon.com/quickstart/)
