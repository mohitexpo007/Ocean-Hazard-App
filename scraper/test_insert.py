# test_insert.py
import asyncio
import asyncpg
from datetime import datetime, timezone

async def test_insert():
    conn = await asyncpg.connect(
        "postgresql://postgres.viuasxnhzbzitdlgjkqm:Mohit%402004@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres",
        statement_cache_size=0
    )

    # Use naive UTC datetime because your column is "timestamp without time zone"
    now_naive = datetime.now(timezone.utc).replace(tzinfo=None)

    await conn.execute("""
        INSERT INTO scraped_reports (text, author, date, likes, retweets, replies, url, score)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    """,
        "Test hazard post 🚨",
        "mohit_tester",
        now_naive,  # ✅ now naive
        10,   # likes
        0,    # retweets
        5,    # replies
        "http://example.com/test",
        0.95  # score
    )

    await conn.close()
    print("✅ Dummy row inserted successfully")

if __name__ == "__main__":
    asyncio.run(test_insert())
