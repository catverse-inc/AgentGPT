#!/bin/bash
tag='v1'

cd "$(dirname "$0")"  exit

is_valid_sk_key() {
  local api_key=$1
  local pattern="^sk-[a-zA-Z0-9]{48}$"
  [[ $api_key =~ $pattern ]] && return 0  return 1
}

echo -n "Enter your OpenAI Key (eg: sk...) or press enter to continue with no key: "
read OPENAI_API_KEY

if is_valid_sk_key $OPENAI_API_KEY || [ -z "$OPENAI_API_KEY" ]; then
  echo "Valid API key"
else
  echo "Invalid API key. Please ensure that you have billing set up on your OpenAI account"
  exit
fi

NEXTAUTH_SECRET=$(openssl rand -base64 32)

ENV="NODE_ENV=development\n\
NEXTAUTH_SECRET=$NEXTAUTH_SECRET\n\
NEXTAUTH_URL=http://localhost:3000\n\
NEXT_PUBLIC_BACKEND_URL=http://localhost:3000\n\
OPENAI_API_KEY=$OPENAI_API_KEY\n\
DATABASE_URL=file:../db/db.sqlite\n"

cd next
printf $ENV > .env
printf $ENV > .env.docker

source .env.docker
docker build --platform linux/amd64 --build-arg NODE_ENV=$NODE_ENV -t gcr.io/catverse-development/agentgpt:$tag .&&\
docker push gcr.io/catverse-development/agentgpt:$tag && \
gcloud run deploy agentgpt-$tag \
  --image gcr.io/catverse-development/agentgpt:$tag \
  --region us-east1 \
  --platform managed \
  --min-instances 1 \
  --max-instances 1 \
  --cpu 1 \
  --memory 1.5Gi \
  --port 3000 \

