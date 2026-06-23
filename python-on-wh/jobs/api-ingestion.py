import json
import os
import urllib.request
from datetime import datetime, timezone

from snowflake.snowpark import secrets as sf_secrets
from snowflake.snowpark.context import get_active_session


def main():
    # api_url = os.environ["API_URL"]
    api_url = 'https://pokeapi.co/'
    url = f"{api_url.rstrip('/')}/pokemon/ditto"

    # api_key = sf_secrets.get_generic_secret_string("api_key")

    req = urllib.request.Request(url) #headers={"Authorization": f"Bearer {api_key}"}
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    filename = f"/tmp/ditto_{timestamp}.json"

    with open(filename, "w") as f:
        json.dump(data, f)

    session = get_active_session()
    session.sql(f"PUT file://{filename} @RESULTS_STAGE AUTO_COMPRESS=FALSE").collect()
    print(f"Uploaded {filename} to @RESULTS_STAGE")


if __name__ == "__main__":
    main()
