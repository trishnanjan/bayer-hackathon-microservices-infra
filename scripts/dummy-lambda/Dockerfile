FROM public.ecr.aws/lambda/nodejs:18

# Copy package.json and install
COPY package.json package-lock.json* ./
RUN npm ci --production || npm install --production

# Copy function code
COPY app.js .

# Command to run the Lambda handler
CMD ["app.handler"]
