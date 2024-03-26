param ([string]$scriptDirectory)

Write-Host -Prompt "始まり"

# スクリプトが配置されたディレクトリを取得
if ($scriptDirectory -eq "") {
	$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# 関数読込
. "$scriptDirectory\functions.ps1" -scriptDirectory $scriptDirectory

$convertRolePath = "./convertRule.json"
$convertRole = Get-Content -Path $convertRolePath -Raw | ConvertFrom-Json

# Tsvファイルを読み込む
$fileListPath = "./filelist.tsv" 
$fileList = Get-Content -Path $fileListPath | ConvertFrom-Csv -Delimiter "`t" -Header ("ImportPath")
foreach ($row in $fileList) {
    $targetFilePath = $row.ImportPath
    $target = Get-Content -Path $targetFilePath -Raw | ConvertFrom-Json
    
    # 変換開始
    $convertedTarget = ConvertJsonToJson $target $convertRole
    
    # ファイル出力
    $fileName = Split-Path -Path $targetFilePath -Leaf
    $outputPath = "./results/" + $fileName
    $convertedTarget | ConvertTo-Json -Compress | Set-Content -Path $outputPath -Encoding UTF8
    Write-Host $fileName
}

Read-Host -Prompt "終わり"

