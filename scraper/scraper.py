import praw
import asyncpg
import asyncio
from datetime import datetime

# ---------- Reddit API Credentials ----------
reddit = praw.Reddit(
    client_id="IUbK1kUWNhoU4sXlKjy7_g",
    client_secret="SmABznSzUFtBMu-VaCFhGPpOIh_xhQ",
    user_agent="disaster-alerts-app by mohit"
)

# ---------- Hazard Keywords ----------
hazard_keywords = ["earthquake", "flood", "cyclone", "tsunami", "landslide", "disaster"]

def is_hazard_post(text: str) -> bool:
    """Check if post contains any hazard keyword (case-insensitive)."""
    text_lower = text.lower()
    if any(word in text_lower for word in hazard_keywords):
        print("✅ Keyword matched ->", text[:100])
        return True
    else:
        print("⚪ Skipped (no keywords):", text[:100])
        return False

def compute_score(likes, comments, date_obj: datetime):
    """Compute engagement score with time decay."""
    base_score = 0.6 * likes + 0.4 * comments
    now = datetime.utcnow()
    age_hours = (now - date_obj).total_seconds() / 3600.0
    decay = pow(2.718, -0.05 * age_hours)
    return base_score * decay

# ---------- Save to Supabase ----------
async def save_to_db(conn, report):
    await conn.execute("""
        INSERT INTO scraped_reports (text, author, date, likes, retweets, replies, url, score)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    """,
        report["text"],
        report["author"],
        report["date"].replace(tzinfo=None),
        report["likes"],
        report["retweets"],
        report["replies"],
        report["url"],
        report["score"]
    )
    print("🟢 Inserted into DB:", report["text"][:100])

# ---------- Main Scraper ----------
async def scrape_reddit():
    conn = await asyncpg.connect(
        "postgresql://postgres.viuasxnhzbzitdlgjkqm:Mohit%402004@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres",
        statement_cache_size=0
    )

    subreddit = reddit.subreddit("all")
    query = " OR ".join(hazard_keywords) + ' "Indian Ocean"'
    print(f"🔎 Running query: {query}")

    inserted = 0
    for submission in subreddit.search(query, sort="new", limit=20):
        text = submission.title + " " + (submission.selftext or "")
        if is_hazard_post(text):
            created = datetime.utcfromtimestamp(submission.created_utc).replace(tzinfo=None)
            report = {
                "text": submission.title,
                "author": str(submission.author),
                "date": created,
                "likes": submission.score,
                "retweets": 0,
                "replies": submission.num_comments,
                "url": submission.url,
                "score": compute_score(
                    submission.score,
                    submission.num_comments,
                    created,
                ),
            }
            print(f"📊 Prepared report with score={report['score']:.2f}")
            await save_to_db(conn, report)
            inserted += 1

    await conn.close()

    if inserted == 0:
        print("⚠️ No posts inserted. Either no hazard posts matched, or no recent posts contained keywords.")
    else:
        print(f"✅ Done. Inserted {inserted} posts into DB.")

# ---------- Entry Point ----------
if __name__ == "__main__":
    asyncio.run(scrape_reddit())
