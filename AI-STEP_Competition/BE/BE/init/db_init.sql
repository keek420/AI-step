/* AI-STEP Competition 用テーブル */
CREATE TABLE IF NOT EXISTS ai_step_competition (
    id int PRIMARY KEY UNIQUE NOT NULL, -- ID
    nickname TEXT  NOT NULL, -- ニックネーム
    mail TEXT UNIQUE NOT NULL, -- メールアドレス
    ans TEXT NOT NULL, -- 正答率
    csv TEXT  NOT NULL, -- csvファイルパス
    code TEXT  NOT NULL, -- ソースコードファイルパス
    bin_csv TEXT, -- バイナリのcsv
    bin_code TEXT, -- バイナリのソースコード
    is_error  BOOLEAN DEFAULT NULL, -- エラーが発生したか
    error_msg TEXT DEFAULT NULL, -- エラーメッセージ (NULLをデフォルト値とする)
    upload_date TEXT DEFAULT NULL, -- 提出日時 
    upload_unix BIGINT NOT NULL DEFAULT 0, -- 提出日時(UNIX)
    upload_num int DEFAULT 0 --提出回数
);

