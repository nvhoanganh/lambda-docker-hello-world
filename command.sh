# make sure you have AWS CLI v2 installed and authenticated: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install

# create role for lambda service
aws iam create-role --role-name lambda-ex --assume-role-policy-document '{
    "Version": "2012-10-17",
  j  "Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"}]
}'

# build the version without the layer first
docker buildx build --platform linux/amd64 . -t anthonynguyen334/lambda-docker-newrelic --progress=plain

# login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic

# tag
docker tag anthonynguyen334/lambda-docker-newrelic 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:latest

# push
docker push 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:latest

# create the lambda function using the docker image
aws lambda create-function \
--package-type Image \
--function-name lambda-docker-newrelic \
--role arn:aws:iam::651340243866:role/lambda-ex \
--code ImageUri=651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:latest

# login to AWS Console and select the newly deployed lambda function, click on add Trigger and select API Gateway
# click on Create new and REST Endpoint and click on create
# go to Configuration/Triggers and click onthe API endpoint, it should say Hello World


# install jq cli tool
brew install jq

# go to https://layers.newrelic-external.com and get the name of the layer for node 12 (note, at the time of this wrirting, the version for nodeJS is 74)
# run this command which will download the newlrelic-layer.zip file
aws --region us-west-2 lambda get-layer-version --layer-name arn:aws:lambda:us-west-2:451483290750:layer:NewRelicNodeJS12X --version-number 74 | jq -r .Content.Location | xargs curl -o newrelic-layer.zip

#unzip
unzip newrelic-layer.zip -d  newrelic-layer/

# build again with the layer using Dockerfile2
docker buildx build -f Dockerfile2 --platform linux/amd64 . -t anthonynguyen334/lambda-docker-newrelic:withnrlayer --progress=plain

# tag image again
docker tag anthonynguyen334/lambda-docker-newrelic:withnrlayer 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:withnrlayer

# login again
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic

# push again
docker push 651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:withnrlayer

# create new function, this time with the nr monitoring
aws lambda create-function \
--package-type Image \
--function-name lambda-docker-newrelic-withnrlayer \
--role arn:aws:iam::651340243866:role/lambda-ex \
--code ImageUri=651340243866.dkr.ecr.us-east-1.amazonaws.com/lambda-docker-newrelic:withnrlayer