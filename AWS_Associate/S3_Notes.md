# S3 Overview

Advertised as infinite scaling storage. 

# Buckets
Stores file into **Buckets** (that are seen as **Directories** but are not).  
Even if buckes are `defined at the region level`, Buckets `must have a globally unique name` (across all regions all accounts)
Naming Convention:  
 - No Uppercase, No underscore
 - 3-63 characters long
 - Not an IP
 - Must start with lowercase letter or number
 - Must NOT start with prefix `xn`
 - Must NOT end with suffix `-s3alias`

Use cases:
 - Backup and storage
 - Disaster recovery
 - Archive
 - Hybrid Cloud Storage
 - Application Hosting
 - Media Hosting
 - Data Lakes and Big Data analytics
 - Software delivery
 - Static Websites 

Once you create a Bucket it's going to be empty; you can see your buckets from all regions in the dashboard and if you select one you can start yo upload files into the bucket and you will see under the **Bucket Objects**

## Objects
Files have a Key that is **the full path**: `prefix + object name`; Note: **there are no folders** even if they have `/` and look like path, these are keys and not folders  
E.G.  
s3://my-buket/my_folder/another_folder/my_file.txt 

The url (above) for the objects is visible in the object property page.
If you open the S2 url from the S3 page you will open the pre-signed url (including credentials) so you will be able to actually get the file.
If you copy the object (public) url and try to open it in a browser you will get instead an **Access Denied** by default (until you change the access policies) 

The object value are the content of the body; 
Max size is **5TB** (i.e. 5000GB) and if uploading more than **5GB**, you must use "**multi-part upload**"

The object also has:
-  **metadata** can be used/set by the system or by users.  Metadata is a list of text key / value pairs
-  Tags (unicode key /value pair - up to 10) useful for security / lifecycle
-  Version ID (if versioning is enabled)

## S3 Security
**User-Based**: you can use IAM policies to control which API calls should be allowed for a specific user/role from IAM  

**Resource-Based**: 
 - **Bucket Policies**: these are bucket wide rules created/associated from S3 console and allow access to specific objects fro specific accounts (e.g. used to make buckets pubblic)
 - Object Access Control List (ACL): finer grain control (can be disabled)
 - Bucket Access Control List (ACL): less common, finer grain control at bucket level (can be disabled) 

Note: an IAM principal can access an S3 object if the user IAM permissions ALLOW it **or** the resource policy ALLOWS it AND there is no explicit DENY

Encryption: you can and should enable Encryption for data saved in S3

#### S3 Bucket Policies
These are JSON based policies, e.g.
```
{
    "Version": "2012-10-17",
    "Id": "ExamplePolicy01",
    "Statement": [
        {
            "Sid": "ExampleStatement01",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:user/Akua"
            },
            "Action": [
                "s3:GetObject",    # <- applies to object in the bucket so need the /* in the resource list
                "s3:GetBucketLocation",
                "s3:ListBucket"   # <- applies to the "folder" so does not needd the /* in the resource list
            ],
            "Resource": [
                "arn:aws:s3:::awsexamplebucket1/*",
                "arn:aws:s3:::awsexamplebucket1"
            ]
        }
    ]
}
```
Blocks:
**Resources**:  what buckets and objet does the policy apply to; the '*' represents all objects at that level (and nested?)  
**Effect**: ALLOW or DENY, related to the **Action** section  
**Action**: Set of actions regulated by this policy  
**Principal**: Entity (account or user) to apply the policy to; if this is  `*` it means everyone, i.e. this is a public policy 

Note: There are bucket settings for `Block Public Access`; if they are enabled, even if you have a policy to allow public access, the S3 bucket will not be publicly available; (they can also be set at the account level to be sure they are applied every time)  

Example:
- You can use a policy to force files to be encrypted at upload
- Create a policy for a specific user to access S3 (IAM policy) or a role for an EC2 instance
- Bucket policy to allow cross account access (e.g. for an IAM user from other accounts)

## S3 to create static websites
S3 can be used to host static websites and have them accessible on the Internet; the url will be something like:
```http://bucket-name.s3-website.aws-region.amazonaws.com ```
It will point directly to the html file directly (other internallinks to further S3 objets can be done inside the HTML code).  
Of course it needs to set: **Allow Public Reads** with an S3 bucket policyor you will get **403 Forbidden Error**

A specific setting for Static Website Hosting is available in the **Properties** section of the **bucket**; you need to specify the name and upload an `index.html` file.
You will see at the end of the section, the url to access the static website, recorded as 
**Bucket website endpoint**


## File Versioning
You can enable **Versioning** at the bucket level (**Properties** Tab); when enabled and a file is uploaded for an existing key (i.e. the path):
- the new content will override the old content
- the version will change; the version ID is a HASH
- a copy of the previous content will be saved

Notes:
- Protects from accidental deletion; files are not actually deleted but only be flagged with `Delete Marker`; you can restore it by **deleting** the `Delete Marker` 
  - You can however delete a specific version ID of an object; this will be a pemanent deletion
- Easy to roll back to previous versions
- All files present before versioning is enabled will get version: `null`
- Suspending versioning does not delete the previous versions

## S3 Replication (CRR: Cross Region REplication and SRR: Single Region Replication)
This is used to setup asynchronous replication between buckets; you need to enable: **versioning** in both Buckets and you can use buckets fro different AWS accounts (as long as the perms allows for this).  
Replication is enabled in the management section/tab of the bucket and uses replication rules
where you specify:
- what to replicate
- the detination bucket  
- the IAM role to use
- other replication options (time/deletion/metrics/etc..)

Notes:
-  Once you enable replication, only new objects will be replicated; if you want to replicate objects that we present before enabling replication, you need to use **S3 Batch Replication**.  
-  **delete markers** can be replicated but it's optional; deletion with Version ID are **NOT** replicated!
- There is no chaining of replication; if bucket1 replicates to bucket2 and bucket2 to bucket3,
the objects in bucket1 are not replicated to bucket3


Use cases:  
CRR - compliance, lower latency access, replication accross accounts  
SRR - log aggregation, live replication between production and test accounts  

## S3 Storage Classes

**Durability** is how probable is to lose an object stored in S3. currently it's 99.999999999% (11 9s) which means if you have 10 milion objects you can expect to lose an object every 10.000 years. **Durability is the same for all storage classes**

**Availability** measures how available the service is; it depends on the storage class, e.g Standard S3 has 00.99% availability (i.e. it's not available upto 53 minues per year)

There are several types of storage, called storage classes:
- **Amazon S3 Standard**: General Purpose: 99.99% avialbility. Used for Frequently accessed data with low latency and high troughput.  
  It sustains up to 2 concurrent facility failures and te sue cases are: Big Data Analytics, mobile and gaming applications, content distribution..  
  No retrieval fee
- **Amazon S3 Standard-Infrequent Aceess (IA)**: 99.9% availability. Used for data less frequently accesses but requires rapid access when needed.  
  Use cases are: Disaster recovery, backups  
  No retrieval fee
- **Amazon S3 One Zone Infrequent Acces**s: High durability but only in single AZ. Availability is 99.5%. Use cases are: storing secondary backup copies of on-premise data  
  or dta that you can recreate.  
  Per GB retrieval fee  
- **Amazon S3 Glacier**: Low cost object storage class meant for achiving and backup (  Per GB retrieval fee  )
  - *Instant Retrieval*: millisecond retrieval, minimum storage duration: 90days
  - *Flexible Retrieval*: expedited retrieval (1 to 5 minutes), standard retrieval (3 to 5 hours), bulk retrieval (5 to 12 hours)  
    Minimum storage duration: 90days
  - *Deep Archive*: Standard (12 hours), Bulk (48 hours). Minimum storage 180 days
- **Intelligent Tiering**: it costs a monthly monitoring fee and auto-tiering fee but it ca move objects automatically between Acess Tiers based on usage.  
  No retrieval fee  
  It moves data between different tiers:
    - Frequent Access (default)
    - Infrequent Access: object not accessed in 30 days
    - Archive Frequent Access: object not accessed in 90 days
    - Archive Access Tier: requires to be enabled and it's configurable; for objects from 90 to 700+ days
    - Deep Archive Access Tier: requires to be enabled and it's configurable; for objects from 180 to 700+ days
    

You can choose a class when you create an s3 object, you can also change the calss manually and finally you can use Lifecycle to automatically set the class based on the life cycle rules configured on the object.
Below a diagram where you can see how objects can change from one class to another.

<img src="pictures/S3_Storage_Classes_transitions.png" alt="Beanstalk tiers" style="height: 700px; width:800px;"/>

Lifecycle rules can be created for a certain prefixes/paths or for certain object tags (e.g. `Department: Finance`) and are based on:
-  Transition Actions: e.g. move object to Standard IA after 60 days from creation; move to Glacier after 6 months
-  Expiration Action: e.g. delete files (or old versions) after 365 days (for log files for instance); delete incomplete Multi-Part uploads if they are 2 weeks old, etc..

**Note:** **AMAZON S3 ANALYTICS** can give you good recommendations for storage classes (Standard, Standard IA); it creates a csv report (updated daily) with data about objec access and recommendations (however it does not run on Glacier or One-Zone IA and remember it might take 24H to 48 before you can see some data)


## S3 Requester Pays
In general, bucket owners will pay for all S3 storage and data transfer (networking) costs associated with their bucket  
With **Requester Pays** the owner still pays for the storage of the object but the requester pays for the networking costs.  
**The requester must be authenticated with AWS**


## S3 Event Notifications
Events are things like:
 - S3:ObjecteCreated
 - S3:ObjectRemoved
 - S3:ObjectRestore
 - S3:replication
 - etc..

You can filter events based on their names (e.g. *.jpg) and you can react automatically to them; E.g. one use case would be to automatically
create a tuhmbnail when a picture is uploaded.

You can create as many events as you want (remember that S3 notifications typically deliver events in seconds but it can sometimes take a minute or longer)

<img align="left" src="pictures/S3_events_notifications.png" alt="S3 Events notifications" style="height: 500px; width:400px;"/> 

&nbsp;  Notifications are delivered to either <b>SNS**, SQS or Lambdas</b>.   

&nbsp;  In order for notifications to work, you need to setup IAM Permissions in the receiver so that the principal:  
&nbsp;  "Service": "s3.amazonaws.com"   
&nbsp;  has the correct action (e.g. <b>"Action": "SNS:Publish", "Effect": "Allow"</b> ) setup  in the receiver (SNS Service in this case).

&nbsp;  Note that you can/should make the policy specific by also matching the source resource name; you can do that adding in the policy  
&nbsp;  a <b>condition</b>, e.g.

```
[...]  
  "Condition": {
      "ArnLike": {
         "aws:SourceArn": "arn:aws:s3:::MyBucket"
      }
  }
[...]  
```
&nbsp;  For SQS that <b>Action</b> would be <b>SQS:SendMessage</b>  
&nbsp;  For Lambda that <b>Action</b> would be <b>Lambda:InvokeFunction</b>

&nbsp;  So remember that you need to setup these policies in the services, not in S3
<br clear="left"/>


Finally you can also send event nortification to **Amazon Event Bridge** that offers Advanced Filtering options with JSON Rules.  
you can for example filter for metadata, object size, names, etcc.. and setup multiple destinations (e.g. Step Functions, Kinesis Streams, etc..)  
and also supports capabilities like Archive, Replay eVents, Reliable Delivery etc..

Event Notification and EventBridge integration are setup from the S3 Properties Tab.

## Baseline Performance
S3 Automatically scales to high requests, latency is 100-200ms  
Your application can achieve at least 3500 PUT/COPY/POST/DELETE or 5500 GET/HEAD requests per second per **prefix** in a bucket.  
There are no limits to the number of prefixes in a bucket. 

From the **Object path** you can can get the **prefix** as everything between the roo, bucket name and the actual file name:   
Let's say we jave as path: `bucket/folder1/sub1/file` -> the prefix will be: `folder1/sub1`  
So if you have files with the same **prefix**: folder1/sub1, the numbers will be shared but if you have different prefixes like for:
- bucket/folder1/sub1/file
- bucket/folder2/sub1/file
- bucket/folder1/file
- bucket/folder2/file

You will have the max performance possible.

To improve the upload instead you can use: **Multi-Part upload** which is recommended for files above **100MB** and **requried** for files above **5GB**  
Better performances are given by the fact that you can make these uploads in parallel.  

**S3 Transfer Acceleration**: increase both uploads and downloads by transferring the file to an AWS Edge Location which will forward the data to the S3 bucket in the trget region.  
(This is also compatible with **Multi-Part Uploads**). The use case is for instance if you are in one location and want to upload the file in an S3 bucket of a different location away from you;   
You would upload it to a local Edge location and from there Amazon would take care of the fast transfer.

**S3 Byte Range Fetches**: parallelize GETs by requesting specific **byte ranges** (it also provides better resilience in case you have failures with specific byte ranges).   
This can be used to speed up downloads because all the requests can be made in parallel and in case you know where the information you are interested  
 into is in a specific byte range, you can specify directly that one.


**S3 Select and Glacier Select**: basically this lets you run **SQL SELECT** and perform serve side filtering so that you can filter the amount of data  
to retrieve and:
-  save on networking costs 
- get data faster (as it's much less
- save on compute costs on the customer side as data is pre-processed


## S3 Batch Operations
This allows you to perform bulk operations on existing S3 objects with a single request.
You can use batch operations for many different use cases:
- Modify objects metadata and proprties
- copy objects between S3 buckets
- Encrypt/un-encrypt S3 buckets
- Modify ACLs and tags
- Rstore objects from Glacier
- Invoke Lambda functions to perform custom actions on each object
- Etc..

A job consists of a list og objects, the action to perform and optional parameter; S3 Batch Operations can automatically manage retriesm track progress,   
send completion notifications and generate reports (so it's probably handier to use rather than writing your own script).  
Finally in roder to get the list of objects for your batch operation you can use **S3 inventory** to get the list of objectrs and **S3 Select** to filter  
the ones you don't want in the job.


## S3 Storage Lens
This service helps you to understand, analyze and optimize storage across your entire AWS organization (Multi-Region and Multi-Account). You can use it to discover anomalies,  
identify cost efficiencies and apply data protection best practices; it can aggreage data and it does let you personalize the dashboards. It can also be configured to export  
metrics daily to an S3 bucket

<img src="pictures/S3_Storage_Lens.png" alt="S3 Storage_Lens" style="height: 400px; width:1100px;"/> 

--

Some Summary metrics:
- General Insights
- StorageBytes, Object count
- Use case: identify the fastest-growing (or not used) buckets and prefixes

Cost Optimization Metrics:
- Provide insights to manage and optimiza Storage Costs
- `NonCurrentVErsion STorageBytes, IncompleteMultipartUploadStorageBytes`
 

Data Protection Metrics:
- VersioningEnabledBucketCount, MFA* (MFA related metrics), SSEKMS* (entryption metrics)

Access Maanagement Metrics, Event Metrics, Performance Metrics, Activity Metrics and Detailed Status Code Metrics(Keep track of API called and actual HTTP status codes returned)


**Some metrics are paid and some are Free**
Free metrics contains around 28 usage metrics and data is available for queries for 14 days.  
Advanced Metric and Recommendations are paid and give all the advanced options/metrics (e.g. advanced data protection, cost optimization, status codes etc..)  
You can also have these metrics published into Cloudwatch (free if you pay for the advanced metrics) and data is available for 15 months.


## S3 Security - Encryption

Object encryption supports:

- Server side encrpytion: 
   - with SSE-S3 encrpytion (default); the key is managed by AWS, you don't have access to the key; encryption is **AES-256**.  
     You must set the header: `"x-amz-server-side-encryption": "AES256"` in the file upload.

   - with AWS KMS: the key is managed by you using AWS service KMS (Which has audit on **CloudTrail**).  
     The header is set to `"x-amz-server-side-encryption": "aws:kms"` in the file upload (you need to specify also the aws kms key you want to use).  
     Note: each operation on the object will call KMS APIs and this will cost (potentially) a lot of money; you can however setup a **bucket** key   
     that will save you money (it's a short lived key stored in S3 that will be used to generate per S3 object keys). This reduces traffic to KMS and the related cost.

   - with Customer provided Keys (SSE-C): you send the Key to AWS which will use to encrypt the file and **then it will discard the key!!**  
     The user is responsible for key managerment and they wilneed the key to read the file.  
     Note that this can only be enabled from the CLI and not from the Web interface



- Client Side encrpytion: The client will encrypt the file before sending it to Amazon S3; of course the client is responsible for key management.

Encryption in transit/flight, be sure you use https endpoints with SSL/TLS which is manadatory for SSE-C (key managed by client); in order to force  encryption in transit you can use a **bucket policy** that denies any bucket operations with the condition `aws:SecureTrransit: False` (i.e. when this condition is true)

Note: 
- you can change the encryption settings for an S3 bucket; it will just create a new version of the file with the new settings
- there is a new type of encryption DKMS (double encryption via KMS)





































