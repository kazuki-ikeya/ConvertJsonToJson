# json�ϊ�
function ConvertJsonToJson($target, $convertRole){
    $convertedTarget = [ref]$target
    foreach ($convertRoleItem in $convertRole.Items) {
        # Key�̏����擾����
        $keys = $convertRoleItem.Key -split "\."
    
        # �Ώۂ����H����
        ConvertJsonToJsonSub $convertedTarget $keys $convertRoleItem    
    }
    return $convertedTarget.Value
}

# json�ϊ����s��
function ConvertJsonToJsonSub([ref]$convertedTarget, $keys, $convertRoleItem){
    $key = $keys[0]
    $value = $convertedTarget.Value.$key
    if ($keys.Count -eq 1) {
        # ���ڂ̕ϊ����s
        ConvertJsonToJsonSubItem $convertedTarget $key $value $convertRoleItem
        return 
    }

    # �㑱�̃L�[�Ɉڍs���� 
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

# json�ϊ��i���ڕ����j
function ConvertJsonToJsonSubItem([ref]$convertedTarget, $key, $value, $convertRoleItem){
    # �����ϊ�
    if ($null -ne $convertRoleItem.ConvertPairs){
        if ($null -ne $convertRoleItem.ConvertPairs.$value){
            $value = $convertRoleItem.ConvertPairs.$value
        }
    }
    # �����u��
    if ($null -ne $convertRoleItem.ReplacePairs){
        foreach ($property in $convertRoleItem.ReplacePairs.PSObject.Properties) {
            $replaceKey = $property.Name
            $replaceValue = $property.Value
            $value = $value -replace $replaceKey, $replaceValue
        }
    }
    # �󔻒�
    if ($null -ne $convertRoleItem.NullValue -and ($value -eq "" -or $value -eq $null)){
        $value = $convertRoleItem.NullValue
    }
    # ������`��
    if ($null -ne $convertRoleItem.StringCase){
        $value = ConvertToCase $value $convertRoleItem.StringCase
    }
    # ���ʊi�[
    $newKey = $key
    if ($null -ne $convertRoleItem.NewKey){
        $newKey = $convertRoleItem.NewKey
    }
    if ($null -eq $convertedTarget.Value.$newKey){
        $convertedTarget.Value | Add-Member -MemberType NoteProperty -Name $newKey -Value $value
    }
    $convertedTarget.Value.$newKey = $value
}

function ConvertToCase([string]$text, [string]$case){
    if ($case.ToLower() -eq "snakecase"){
        return ConvertToSnakeCase $text
    } elseif ($case.ToLower() -eq "pascalcase"){
        return ConvertToPascalCase $text
    } elseif ($case.ToLower() -eq "camelcase"){
        return ConvertToCamelCase $text
    } else {
        return $text
    }
}


# snake_case�`���ɕϊ�����֐�
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

# PascalCase�`���ɕϊ�����֐�
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

# camelCase�`���ɕϊ�����֐�
function ConvertToCamelCase([string]$text)  {
    if ($text -eq ""){
        return ""
    }
    $pascalCase = ConvertToPascalCase $text
    return $pascalCase.Substring(0, 1).ToLower() + $pascalCase.Substring(1)
}