FROM node:23-slim
# install dependencies and change user & group id to 1001 for GitHub Actions compatibility
RUN apt-get update && apt-get install -y curl

WORKDIR /app
COPY --chown=node:node e2e/package.json package.json
COPY --chown=node:node e2e/playwright.config.ts playwright.config.ts

RUN npm install && \
    npx playwright install && \
    npx playwright install-deps && \
    # Move the cache to the node user that will run the tests
    mv /root/.cache /home/node/.cache

RUN chown -R node:node /app
COPY --chown=node:node e2e/BaseTest.ts BaseTest.ts
COPY --chown=node:node e2e/tests tests
USER node
