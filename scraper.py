import sqlite3
import urllib.error
import urllib.request


BILL_ID = "3218"

URL = (
    "https://www.parliament.nsw.gov.au/"
    "parliamentary-business/bills/"
    f"bill-details?billId={BILL_ID}"
)

KNOWN_TITLE = (
    "Gaming Machines Amendment "
    "(Centralised Monitoring System) Bill 2015"
)


request = urllib.request.Request(
    URL,
    headers={
        "User-Agent": (
            "Mozilla/5.0 "
            "NSW-Parliament-Bill-Catalogue/1.0"
        )
    },
)


try:
    with urllib.request.urlopen(
        request,
        timeout=120,
    ) as response:
        body = response.read().decode(
            "utf-8",
            errors="replace",
        )

        status = response.status

except urllib.error.HTTPError as error:
    status = error.code

    body = error.read().decode(
        "utf-8",
        errors="replace",
    )

except Exception as error:
    status = 0
    body = str(error)


challenge = (
    "Just a moment"
    in body
    or "cf-mitigated"
    in body
)

title_found = (
    KNOWN_TITLE.casefold()
    in body.casefold()
)


db = sqlite3.connect(
    "data.sqlite"
)

db.execute(
    """
    CREATE TABLE IF NOT EXISTS data (
        bill_id TEXT PRIMARY KEY,
        url TEXT,
        http_status INTEGER,
        response_size INTEGER,
        cloudflare_challenge INTEGER,
        title_found INTEGER,
        sample TEXT
    )
    """
)

db.execute(
    """
    INSERT OR REPLACE INTO data (
        bill_id,
        url,
        http_status,
        response_size,
        cloudflare_challenge,
        title_found,
        sample
    )
    VALUES (?, ?, ?, ?, ?, ?, ?)
    """,
    (
        BILL_ID,
        URL,
        status,
        len(body),
        int(challenge),
        int(title_found),
        body[:2000],
    ),
)

db.commit()
db.close()


print("Bill ID:", BILL_ID)
print("HTTP:", status)
print("Size:", len(body))
print("Cloudflare challenge:", challenge)
print("Known title found:", title_found)
