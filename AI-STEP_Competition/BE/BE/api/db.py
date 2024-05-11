# 標準ライブラリ

# 外部ライブラリ
from sqlalchemy import *
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import *

# プロジェクト内ファイル
from .settings import DATABASE

# 設定
ENGINE = create_engine(DATABASE, echo=False)

# session の作成
session = scoped_session(sessionmaker(autocommit=False, autoflush=False, bind=ENGINE))

# Base の作成
Base = declarative_base()
Base.query = session.query_property()

# AI-STEP Competition のテーブル
class db(Base):
	__tablename__ = "ai_step_competition2"
	id = Column("id", BigInteger, primary_key=True, nullable=False, unique=True)
	nickname = Column("nickname", Text, nullable=False, unique=True)
	mail = Column("mail", Text, nullable=False, unique=True)
	ans = Column("ans", Text )
	csv = Column("csv", Text,  unique=True)
	code = Column("code", Text,  unique=True)
	bin_csv = Column("bin_csv", Text)
	bin_code = Column("bin_code", Text)
	is_error = Column("is_error", Boolean, default=False)
	error_msg = Column("error_msg", Text, default="")
	upload_date = Column("upload_date", DateTime)
	upload_unix = Column("upload_unix", BigInteger, default=0)
	upload_num = Column("upload_num", Integer, default=0)

	
	
	
	
	
	
	
	
	
	
	
	
	
	