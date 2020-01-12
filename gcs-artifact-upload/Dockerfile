FROM gcr.io/google.com/cloudsdktool/cloud-sdk:275.0.0

RUN apt-get update && apt install zip -y

# Determines timestamp for artifact name
ENV TZ="America/Chicago"

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
