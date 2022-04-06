# make sure you have AWS CLI v2 installed and authenticated: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install

# create role for lambda service
aws iam create-role --role-name lambda-ex --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"}]
}'

# build the image
docker buildx build --platform linux/amd64 . -t anthonynguyen334/lambda-docker-newrelic --progress=plain

# login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic

# tag
docker tag anthonynguyen334/lambda-docker-newrelic 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:latest

# push
docker push 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:latest

# create the lambda function
aws lambda create-function \
--package-type Image \
--function-name lambda-docker-newrelic \
--role arn:aws:iam::651340243866:role/lambda-ex \
--code ImageUri=651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:latest

# login to AWS Console and select the newly deployed lambda function, click on add Trigger and select API Gateway
# click on Create new and REST Endpoint and click on create
# go to Configuration/Triggers and click onthe API endpoint, it should say Hello World