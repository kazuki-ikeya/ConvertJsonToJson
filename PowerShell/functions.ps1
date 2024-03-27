# json変換
function ConvertJsonToJson($target, $convertRole){
    $convertedTarget = [ref]$target
    foreach ($convertRoleItem in $convertRole.Items) {
        # Keyの情報を取得する
        $keys = $convertRoleItem.Key -split "\."
    
        # 対象を加工する
        ConvertJsonToJsonSub $convertedTarget $keys $convertRoleItem    
    }
    return $convertedTarget.Value
}

# json変換実行部
function ConvertJsonToJsonSub([ref]$convertedTarget, $keys, $convertRoleItem){
    $key = $keys[0]
    $value = $convertedTarget.Value.$key
    if ($keys.Count -eq 1) {
        # 項目の変換実行
        ConvertJsonToJsonSubItem $convertedTarget $key $value $convertRoleItem
        return 
    }

    # 後続のキーに移行する 
    $nextKeys = $keys[1..($keys.Count - 1)]
    if ($value.GetType().IsArray) {
        $i = -1
        foreach ($valueItem in $value) {
            $i += 1
            $nextValue = [ref]$valueItem
            ConvertJsonToJsonSub $nextValue $nextKeys $convertRoleItem
            $value[$i] = $nextValue.Value
        }
    } else {
        $nextValue = [ref]$value
        ConvertJsonToJsonSub $nextValue $nextKeys $convertRoleItem
        $value = $nextValue.Value
    }
    $convertedTarget.Value.$key = $value
}

# json変換（項目部分）
function ConvertJsonToJsonSubItem([ref]$convertedTarget, $key, $value, $convertRoleItem){
    # 文字変換
    if ($null -ne $convertRoleItem.ConvertPairs){
        if ($null -ne $convertRoleItem.ConvertPairs.$value){
            $value = $convertRoleItem.ConvertPairs.$value
        } elseif ($null -ne $convertRoleItem.ConvertPairsElse){
            $value = $convertRoleItem.ConvertPairsElse
        }
    }
    # 文字置換
    if ($null -ne $convertRoleItem.ReplacePairs){
        foreach ($property in $convertRoleItem.ReplacePairs.PSObject.Properties) {
            $replaceKey = $property.Name
            $replaceValue = $property.Value
            $value = $value -replace $replaceKey, $replaceValue
        }
    }
    # 文字列形式
    if ($null -ne $convertRoleItem.StringCase){
        $value = ConvertToCase $value $convertRoleItem.StringCase
    }
    # 文字列Upper形式
    if ($null -ne $convertRoleItem.ToUpper -and $convertRoleItem.ToUpper){
        $value = $value.ToUpper()
    }
    # 文字列Lower形式
    if ($null -ne $convertRoleItem.ToLower -and $convertRoleItem.ToLower){
        $value = $value.ToLower()
    }
    # 空判定
    if ($null -ne $convertRoleItem.NullValue -and ($value -eq "" -or $value -eq $null)){
        $value = $convertRoleItem.NullValue
    }
    # 結果格納
    $newKey = $key
    if ($null -ne $convertRoleItem.NewKey){
        $newKey = $convertRoleItem.NewKey
    }
    if ($null -eq $convertedTarget.Value.$newKey){
        $convertedTarget.Value | Add-Member -MemberType NoteProperty -Name $newKey -Value $value
    }
    $convertedTarget.Value.$newKey = $value
}

# 文字列形式変換
function ConvertToCase([string]$text, [string]$case){
    if ($case.ToLower() -eq "snakecase"){
        return ConvertToSnakeCase $text
    } elseif ($case.ToLower() -eq "pascalcase"){
        return ConvertToPascalCase $text
    } elseif ($case.ToLower() -eq "camelcase"){
        return ConvertToCamelCase $text
    } elseif ($case.ToLower() -eq "kebabcase" -or $case.ToLower() -eq "dashcase" ){
        return ConvertToKebabCase $text
    } else {
        return $text
    }
}

# kebab-case形式に変換する関数
function ConvertToKebabCase([string]$text) {
    if ($text -eq ""){
        return ""
    }
    if ($text -match "[_-]") {
        return $text -replace "[_-]", "-"
    }
    $dashCase = [System.Text.RegularExpressions.Regex]::Replace($text, "(?<!^)(?=[A-Z])", "-$&").ToLower()
    return $dashCase.ToLower()
}

# snake_case形式に変換する関数
function ConvertToSnakeCase([string]$text) {
    if ($text -eq ""){
        return ""
    }
    if ($text -match "[_-]") {
        return $text -replace "[_-]", "_"
    }
    $snakeCase = [System.Text.RegularExpressions.Regex]::Replace($text, "(?<!^)(?=[A-Z])", "_$&").ToLower()
    return $snakeCase.ToLower()
}

# PascalCase形式に変換する関数
function ConvertToPascalCase([string]$text) {
    if ($text -eq ""){
        return ""
    }
    if (-not $text -match "[_-]") {
        return $text.ToLower().Substring(0, 1).ToUpper() + $text.Substring(1).ToLower() 
    }
    $words = $text -split "[_-]"
    $pascalCase = $words | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() }
    return $pascalCase -join ""
}

# camelCase形式に変換する関数
function ConvertToCamelCase([string]$text)  {
    if ($text -eq ""){
        return ""
    }
    $pascalCase = ConvertToPascalCase $text
    return $pascalCase.Substring(0, 1).ToLower() + $pascalCase.Substring(1)
}