BUCKET_NAME="test-tf-bucket-cc"
BUCKET_REGION="eu-central-1"

# Create S3 Bucket to be used as Terraform Backend for state files
aws s3api create-bucket --bucket $BUCKET_NAME --create-bucket-configuration LocationConstraint=$BUCKET_REGION
aws s3api wait bucket-exists --bucket $BUCKET_NAME
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration MFADelete=Disabled,Status=Enabled


DB_TABLE_NAME="StateLocking"
READ_CAPACITY=5
WRITE_CAPACITY=5

# Create DynamoDB table for Terraform State Locking
aws dynamodb create-table \
    --table-name $DB_TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=$READ_CAPACITY,WriteCapacityUnits=$WRITE_CAPACITY