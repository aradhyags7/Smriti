import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import DeclarativeBase, sessionmaker

# Load environment variables from .env relative to backend root
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)
load_dotenv()

# Always point sqlite to the backend/smriti.db file regardless of CWD
default_db_file = (Path(__file__).resolve().parent.parent.parent / "smriti.db").as_posix()
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL or DATABASE_URL.startswith("sqlite:///./"):
    DATABASE_URL = f"sqlite:///{default_db_file}"

# Render provides postgres://, SQLAlchemy 2.0 requires postgresql://
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    DATABASE_URL,
    echo=False,
    connect_args=connect_args,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy declarative models."""
    pass


def ensure_database_schema(db_engine):
    """Safely detect and apply schema updates to existing databases without data loss."""
    try:
        inspector = inspect(db_engine)
        tables = inspector.get_table_names()
        if "users" not in tables:
            return

        columns = {col["name"] for col in inspector.get_columns("users")}
        indexes = {idx["name"] for idx in inspector.get_indexes("users")}

        with db_engine.begin() as conn:
            # 1. Check auth_provider column
            if "auth_provider" not in columns:
                if db_engine.dialect.name == "postgresql":
                    conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR DEFAULT 'LOCAL';"))
                else:
                    conn.execute(text("ALTER TABLE users ADD COLUMN auth_provider VARCHAR DEFAULT 'LOCAL';"))

            # 2. Check google_subject column
            if "google_subject" not in columns:
                if db_engine.dialect.name == "postgresql":
                    conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS google_subject VARCHAR;"))
                else:
                    conn.execute(text("ALTER TABLE users ADD COLUMN google_subject VARCHAR;"))

            # 3. Check unique index on google_subject
            if "ix_users_google_subject" not in indexes:
                conn.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_google_subject ON users (google_subject);"))

        # 4. Check patients table columns for patient onboarding
        if "patients" in tables:
            pat_columns = {col["name"] for col in inspector.get_columns("patients")}
            with db_engine.begin() as conn:
                if "age" not in pat_columns:
                    if db_engine.dialect.name == "postgresql":
                        conn.execute(text("ALTER TABLE patients ADD COLUMN IF NOT EXISTS age INTEGER;"))
                    else:
                        conn.execute(text("ALTER TABLE patients ADD COLUMN age INTEGER;"))

                if "dementia_type" not in pat_columns:
                    if db_engine.dialect.name == "postgresql":
                        conn.execute(text("ALTER TABLE patients ADD COLUMN IF NOT EXISTS dementia_type VARCHAR;"))
                    else:
                        conn.execute(text("ALTER TABLE patients ADD COLUMN dementia_type VARCHAR;"))

                if "is_onboarded" not in pat_columns:
                    if db_engine.dialect.name == "postgresql":
                        conn.execute(text("ALTER TABLE patients ADD COLUMN IF NOT EXISTS is_onboarded BOOLEAN DEFAULT FALSE;"))
                    else:
                        conn.execute(text("ALTER TABLE patients ADD COLUMN is_onboarded BOOLEAN DEFAULT 0;"))
    except Exception as e:
        # Schema verification warning without crashing app
        print(f"[DB Schema Notice] {e}")


def get_db():
    """FastAPI dependency for obtaining a database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
