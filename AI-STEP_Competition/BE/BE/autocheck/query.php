<?php

//config ファイル読み込み
require_once "./config.php";
try {
    //MoodleDBとコネクト
    $pdo_moodle = new PDO($dsn_moodle, $DB_user, $DB_password);
    $pdo_moodle->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo "cannot connect DB\n";
    echo "Error {$e->getMessage()}"; // getMessage() メソッドを使用
    die();
}
$nickname_sql = "SELECT InfoData.userid, InfoData.data AS nickname
                FROM mdl_user_info_data AS InfoData
                LEFT  JOIN mdl_user_info_field AS InfoField ON InfoField.id = InfoData.fieldid
                WHERE InfoField.shortname = :nickname_field_name;";

$file_path_sql = "WITH submit_files AS  (
SELECT  DISTINCT u.id AS UserID,  u.email,  f.timemodified AS uploadTime, f.filename,
    --  a.id,u.username, f.contenthash, a.course, a.name AS SubmissionCourse, FROM_UNIXTIME(f.timemodified, '%Y/%m/%d %H:%i:%s') AS DateUploaded,
    CONCAT('filedir/', SUBSTRING(f.contenthash, 1, 2), '/', SUBSTRING(f.contenthash, 3, 2), '/', f.contenthash) AS filepath
FROM mdl_user AS u 
JOIN mdl_files AS f ON u.id = f.userid
JOIN mdl_context AS cx ON f.contextid = cx.id
JOIN mdl_course_modules AS cm ON cx.instanceid = cm.id
JOIN mdl_course AS c ON cm.course = c.id
JOIN mdl_assign_submission AS asu ON asu.userid = u.id AND f.timemodified >= asu.timemodified - 60
JOIN mdl_assign AS a ON a.id = asu.assignment
WHERE f.filename <> \".\" AND f.component = \"assignsubmission_file\" AND a.id = :submissionID
)
SELECT  DISTINCT submit_files.* FROM submit_files
JOIN ( SELECT UserID, MAX(uploadTime) as latestUpload FROM submit_files GROUP BY UserID ) as latest 
ON latest.UserID = submit_files.UserID 
and latest.latestUpload = submit_files.uploadTime;";

//nickname取得 keyはuserID
$nickname_stmt = $pdo_moodle->prepare($nickname_sql);
//変数をバインド
$nickname_stmt->bindParam(':nickname_field_name', $nickname_field_name, PDO::PARAM_STR);
$nickname_stmt->execute();
//userid, nickname
$nickname_data = $nickname_stmt->fetchAll(PDO::FETCH_ASSOC|PDO::FETCH_UNIQUE);

//csv取得
$csv_file_stmt = $pdo_moodle->prepare($file_path_sql);
//変数をバインド
$csv_file_stmt->bindParam(':submissionID', $csv_submissionID, PDO::PARAM_INT);
$csv_file_stmt->execute();
$csv_file_data = $csv_file_stmt->fetchAll(PDO::FETCH_ASSOC);

//source code取得 keyはuserID
$code_file_stmt = $pdo_moodle->prepare($file_path_sql);
//変数をバインド
$code_file_stmt->bindParam(':submissionID', $code_submissionID, PDO::PARAM_INT);
$code_file_stmt->execute();
$code_file_data = $code_file_stmt->fetchAll(PDO::FETCH_ASSOC|PDO::FETCH_UNIQUE);

print_r($nickname_data);
print_r($csv_file_data);
print_r($code_file_data);


/*
以下のようなレコードがsqlから得られる
    [UserID] => 2
    [email] => ou4@docomo.ne.jp
    [uploadTime] => 1695703617
    [filename] => category_list.xlsx
    [FilePath] => /filedir/a8/75/a87511e842b451c8dede3841544d835b7ee3c75e
*/

//pythonに渡す引数をレコードから取り出す
$correct_num_args = 8;

foreach($csv_file_data as $file_data_row){
    $uid = $file_data_row["UserID"];

    $file_data_row["nickname"] = $nickname_data[$uid]["nickname"];

    //codeが提出されているか
    if(isset($code_file_data[$uid])){
        $file_data_row["code_filename"]  = $code_file_data[$uid]["filename"];
        $file_data_row["code_filepath"]  = $code_file_data[$uid]["filepath"];
    }
    else{
        echo("ソースコードが提出されていません\n");
    }

    //pythonに渡す引数が妥当か判定
    //文字列の中から空白区切りでcuurect_numあるか判定
    if(count($file_data_row) ==  $correct_num_args){

        //okだったら実行
        echo(escapeshellarg(json_encode($file_data_row)));
        #<userID> <nickname> <email> <uploadTime> <DateUploaded> <filePath(csv)> <code_filename> <code_FilePath>
        exec("python3 " . $upload_python_script . " " . escapeshellarg(json_encode($file_data_row)), $output);
        //elseif($argc > 1)exec("python3 " . $upload_python_script . " " . escapeshellarg(json_encode($file_data_row)). " " . $argv[1] , $output);
        print_r($output);

    }
    else{
        echo("sqlで抽出したデータの個数が違うのでアップロードプログラムを起動できません\n");
    }

}

?>