<?php
header("Access-Control-Allow-Origin: *");
$url_str = "http://localhost:8001/";
if($_SERVER["REQUEST_METHOD"] == "GET"){
	if($_GET["route"] == "get"){
		$url_str .= "get";
		if(isset($_GET["id"])){
			$url_str .= "?id=" . $_GET["id"];
		}
	}
	elseif($_GET["route"] == "login"){
		$url_str .= "login";
		if(isset($_GET["name"])){
			$url_str .= "?name=" . rawurlencode($_GET["name"]);
		}
		elseif(isset($_GET["mail"])){
			$url_str .= "?mail=" . $_GET["mail"];
		}
		$url_str .= "&pw=" . $_GET["pw"];
	}
	else{
		echo("アクセスが不正です。");
		http_response_code(400);
		exit;
	}
	$command="curl '$url_str' --include";
}
elseif($_SERVER["REQUEST_METHOD"] == "POST"){
	$command = "curl --include -X POST ";
	foreach ($_POST as $key => $value) {
		if($key == "route"){
			continue;
		}
		$command .= "-F '" . $key . "=" . $value . "' ";
	}
	foreach ($_FILES as $key => $value){
		$command .= "-F '$key=@" . $value["tmp_name"] . "' ";
		if($value["error"] != 0){
			echo("ファイルサイズが大きすぎます。");
			http_response_code(400);
			exit;
		}
	}
	if($_POST["route"] == "upload"){
		$command .= $url_str . "upload";
	}
	elseif($_POST["route"] == "register"){
		$command .= $url_str . "register";
	}
	else{
		echo("アクセスが不正です。");
		http_response_code(400);
		exit;
	}
}
else{
	echo("アクセスが不正です。");
	http_response_code(400);
	exit;
}
exec($command, $output);
//var_dump($output);
$result = explode(" ", $output[0], 3)[1];

//echo $result;


$is_json = false;
for ($i = 0; $i < count($output); $i++){
	if($output[$i] != "{" && !$is_json){
		continue;
	}
	else{
		$is_json = true;
	}
	if($is_json){
		$json[] = trim($output[$i]);
//flaskのdebugがfalse,trueで帰り値が変わる
//falseならjsonがoutputの一つのndexにひとまとまりで格納。trueなら各要素が一つずつ格納。
//どちらにも対応するためのif文, 
//というかコメントなさ過ぎて意味わからん
if(empty($json)){
		}
		//do nothing
}
else{
	foreach ($output as $index => $item) {
		// 各要素がJSONであるかどうかを確認
		$jsonObject = json_decode($item);
		if (json_last_error() === JSON_ERROR_NONE) {
			$str = $item;
			break;
		}

	}
}
}
$str = implode(" ", $json);
echo $str;
if($_POST["route"] == "upload" && intval($result) < 200){
	http_response_code(intval($result) + 100);
}
else{
	http_response_code(intval($result));
}
?>
