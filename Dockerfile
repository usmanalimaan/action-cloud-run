FROM google/cloud-sdk:279.0.0

COPY entrypoint.sh /entrypoint.sh
COPY gitdiff.sh /gitdiff.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
