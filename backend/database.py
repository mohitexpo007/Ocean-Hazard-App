from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# PostgreSQL connection URL
# ⚠️ Make sure your username, password, host, and database are correct
DATABASE_URL = "postgresql://postgres.viuasxnhzbzitdlgjkqm:Mohit%402004@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres"

# Create engine
engine = create_engine(DATABASE_URL)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()

# Dependency for DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
