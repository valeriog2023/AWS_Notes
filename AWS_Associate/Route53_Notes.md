# Route 53 Overview

**Domain Registrar**:  You can use Route53 as your registrar; this is where you can record your own domain. 
You can however use other registrar and still use route53 to manage your DNS records. In this case you need:
- a public DNS zone in route 53
- specify **Amazon DNS servers** in your registrar configuration as the **name servers** instead of using the default ones

### Refresher on DNS names:

**Root DNS Servers** domains are managed by **ICANN**: they will give you the **NS** record of a top server domain.  
**Top DNS servers** are managed by **IANA**: they manage the top level domain (e.g .com, .net, etc..) and will return the **NS** record of a **Domain Registrar** for the specific second level domain (e.g. amazon.com)  
**Domain Registrar** will have an entry for the full URL hostname (hopefully) and return the actual IP matchd to the name (A Record)

**Route53** is the only service that provides 100% availability.  
Each record will contain:
 - DNS Domain/subdomain Name, e.g. example.com
 - Record Type, e.g. A, CNAME, AAAA, NS, etc..  
   Note: you can't create a CNAME record for a top node of a DNS namespace (Zone Apex)  
         E.g. you can't create a CNAME for example.com but you can for www.example.com
 - Value: this is the actual Ip value
 - Routing Policy: how does Route53 responds to queries
 - TTL: amount of time the record is cached at DNS resolvers  
   - you get charged for # of requests to Route53 so be sure to adjust the TTL accordingly
   

## Hosted Zones
These are containers for records that define how to route traffic to a domain or subdomain. 
Route53 hosted zones are not free and they will cost (currently 0.5$ per month per zone)
You can have:
- Public: contains records that specify how to route traffic on the internet (public domain names).     
- Private: used for domain names that are not publicly available but can only be resolved in your VPCs
So if you want to have both private and public names you will need to create at least 2 zones


## Route53 steps to create Zone and Records
- start by selecting: **Register a domain** 
- you'll need to check for the domain availability
- The minimum amount of time to keep the domain is one year (currently this costs **13$**)  
  You can select auto-renew when you buy it
- Admin information is requried and you should enable **Privacy Protection** so that your details are not publicly available  
- when the domain is created you will have a **new Public Hosted Zone** with already some base records: **A, NS, SOA** and **CNAME**  
  The records created are for the route of the domain and the www version
- Inside the hosted zone you can create specific records  

## CNAMEs vs Alias
- CNAME records point a hostname to another hostname, it does not work however for root domains  
  (i.e. mydomain.com can't be a CNAME but something.mydomain.com can ) 
- ALIAS records are specific to **route53** let you point a hostname to an AWS Resource and **work for both root and non root domains**  
  (e.g. app.mydomain.com -> blabla.amazonaws.com )
   - are free of charge
   - have native health check (need to ticket the option if not enabled by default)
   - automatically recongnizes changes in the resource IP
   - always of type A/AAAA
   - you create it in the same section as normal records but need to **tick the option "Alias"**
   - TTL can't be set
   - Targets for alias are: 
       - Elastic Load Balancer
       - CloudFront Distributions
       - API Gateway
       - S3 websites
       - VPC interface endpoints
       - Global Accelerator accelerator
       - Route53 records in the same hosted zone
       - NOT FOR EC2 DNS NAMES

## Health Checks
There are 15 global Health Checkers around the world spread in different regions and ou can tie a  
Route53 DNS record to automate DNS failover.  
The default settings are:  
  - Healthy/Uhealthy: **3** (default)
  - Interval: **30sec** ( can set to 10sec (fast) with higher cost)
  - supports: HTTP, HTTPS/TCP
  - You can choose which location you want route53 to use
  - You **must allow** the traffic for incoming requests from the AWS Checkers  
    (IPs are shown when the health check is created)

A Passing state is returned when the endpoints responds with **2XX or 3XX** or they can be setup to pass/fail
based on the content of the first 5120 bytes of the response.  
**Private resources** are monitored using **cludwatch metrics and Cloudwatch alarms** because the route53 checkers 
can't access them directly

Properties:  
- **HTTP health checks are only for public resources**
- Health checks can monitor:
  - an endpoint (application, server, other AWS resource)
  - another **Health Check**; this is called **Calculated Health Check**
  - **CloudWatch Alarms**: this gives a lot of control on what triggers it,  
    e.g. throttles of DynamoDB, alarms on RDS, custom metrics, etc..

**Calculated Health Check** combine the result of multiple Health checks (up to 256) with normal logic operators: OR,AND,NOT
You canspecify how many of the health checks need to pass to make the overall check pass.



## DNS Routing Policies
The routing policy is specified when creating a new DNS record. You can have the following policies:
  - **Simple**:  it will point to a single resource. Note that you can specify multiple IP values for your A record;  
    in this case the client will select one randomly. If using Alias, only one resource can be associated.  
    Can't be associated with an health check
 - **Weighted**: controls the % of the requests that go to each specific resource; note that weights don't need to sum up to 100.  
   DNS records must be of the same name and type to be used in a weighted way. You can use **health checks** and also take out  
   resources by assigning a weight of zero (unless they are all zero in that case it's equally distributed).  
   Records can be identified inside a weighted record set by a record id (which is a string)
- **Latency**: will redirect to the resource that has the least latency close to the client.  
   Note that you actually need to specify the AWS region where the IP lives and that IP served is not necessarily the one from the   
   closest geographic region. These records can be associated to health checks.
- **Failover**: the primary record must be associated with an **health check**. If the resource is healthy,  
  route53 will return the IP from the primary record; if it is not it will return the IP from the secondary record  
  `Primary` vs `Secondary` are attributes that you can set on the records when use a failover routing policy.  
  Of course you also need to specify one health checks created in advance.
- **Geolocation**: this is based on where the user is actually located (not the latency); you can specify the location based on (most specific wins):
  - Continent
  - Country
  - US State  

   You should also define a **default** location in case there's no match or in case of a failover (i.e. if you use an **health check** and the resource is down; Geolocation does support health checks).  
   Use cases are pretty obvious: e.g. content localization and compliance
- **Geoproximity**: geolocation will localize the result of DNS query based on the source IP but it does not necessarily return the answer of the closest location, you can set the record IP to be whatever you want.  
  Geoproximity tries to route traffic to your resources based on their geographical location.  
  You can specify a **Bias** to route more (1 to 99) or less (-1 to -99) traffic to the resource. This works basically by expanding/shrinking the area of the region based on the Bias.
  Resources can be:
  - AWS resources (AWS region is used to locate them)
  - non AWS resources (you need to specify Latitude and Longitude) 
- **Ip routing**: DNS request routing is based on client's IP address; yuo need to provide a list of CIDRs and the corresponding endpoints/locations (user-IP-to-endpoint mapping)
- **Multi Value**: use when routing traffic to multiple resources and the records can be associated with **Health Checks**. You can have up to 8 healthy records returned for each Multi-Value query.  
  Notes: 
  - this is not a substitute for having an ELB. The **client** will choose which record to use!
  - you can return mutli records with the default policy too but here you can use health checks together too.
