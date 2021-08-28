#!/bin/bash

# byte値を読みやすくする
function byteStr(){
  #$1で渡された数値をキリがいい単位の〇byte表示に置き換える
  value=$1
  conversion_count=0

  while [ $value -gt 1000 ]
  do
    value=$(echo "scale=0; $value/1000" | bc)
    conversion_count=$((conversion_count + 1))
  done

  case $conversion_count in
    1)
       unit="KB"
       ;;
    2)
       unit="MB"
       ;;
    3)
       unit="GB"
       ;;
    4)
       unit="TB"
       ;;
    *)
       echo "conversion_count err" 1>&2
       exit 1
       ;;
    esac
        echo "${value}${unit}"
        return 0
}

fileEx=".mp4"

dirPath=""
fileName=""
filePath=""
compressDirPath=""
compressFileName=""
compressFilePath=""
isMute="no"

# 圧縮メッセージ
compressMessage=""
compressType=""

echo "==================================="
echo ""
echo "中断したい場合は、[ CTRL + C ]"
echo ""
read -p "ファイルパスを入力する:" filePath

echo "FilePath: ${filePath}"
echo ""

# フォルダの存在確認を行う
if [ -d "${filePath}" ]; then
    echo "フォルダの入力を確認しました."
    compressDirPath="${filePath}/CompressMovie"

# ファイルの存在確認を行う
elif [ ! -f "${filePath}" ]; then
    echo "ファイルの存在を確認できませんでした."
    exit 1
fi

dirPath=`dirname ${filePath}`
fileName=`basename ${filePath}`

# 展開先が指定されていない場合は、同じ場所にする
if [ "${compressDirPath}" = "" ]; then
    compressDirPath="${dirPath}"
fi

if [ -f "${filePath}" ]; then

    read -p "新しいファイル名を入力 (空白で自動設定):" compressFileName

    # 空白を入力したので自動設定
    if [ "${compressFileName}" = "" ]; then
        compressFileName="${fileName%.*}_Compress"
        echo "自動設定: ${compressFileName}"
    fi
    
    # 拡張子をつける
    compressFileName="${compressFileName}${fileEx}"
    
    # 圧縮後のファイルパス
    compressFilePath="${compressDirPath}/${compressFileName}"
    if [ -f "${compressFilePath}" ]; then
        echo "既に同名のファイルが存在しているため別のファイル名を入力してください"
        echo "FilePath: ${compressFilePath}"
        echo "FileName: ${compressFileName}"
        exit 1
    fi
else
    compressFileName="<自動設定>"
fi

# 1: 通常圧縮
# 2: 適正圧縮
echo ""
echo "--------------"
echo "圧縮の設定を数字で入力をしてください"
echo " 1: 通常圧縮"
echo " 2: 適正圧縮"
echo ""
read -p "数字を入力する (空白なら1):" compressType

# 空白なら1
if [ "${compressType}" = "" ]; then
    compressType="1"
fi

# 通常圧縮
if [ "${compressType}" = "1" ]; then
    compressMessage="圧縮設定: 通常"
elif [ "${compressType}" = "2" ]; then
    compressMessage="圧縮設定: 適正"
else
    echo "不正な圧縮設定を入力を検知しました"
    exit 1
fi

# ミュートにするかどうか
echo ""
echo "--------------"
read -p "動画ファイルから音声を削除しますか? (y/N): " yn
echo ""

# 入力NG
if [ "${yn}" = "y" ] || [ "${yn}" = "Y" ]; then
    isMute="yes";
    echo " 動画からサウンドを削除します"
fi

echo ""
echo "フォルダパス: ${dirPath}"
echo " 元ファイル: ${fileName}"
echo " 圧縮ファイル: ${compressFileName}"
echo "圧縮設定: ${compressMessage}"
echo "音を削除するか: ${isMute}"
read -p "処理を開始しますか? (y/N): " yn
echo ""

# 入力NG
if [ ! "${yn}" = "y" ] && [ ! "${yn}" = "Y" ]; then
    echo "処理をキャンセルしました : ${yn}"
    exit 1
fi

echo "処理を開始します"

# ファイルサイズ
totalSize=0
compressSize=0


muteCmd=""
if [ "${isMute}" = "yes" ]; then
    muteCmd="-an "
fi


# ディレクトリの場合の処理
if [ -d "${filePath}" ]; then

    # 既に圧縮フォルダが存在している
    if [ -d ${compressDirPath} ]; then
        # ディレクトリにファイルが存在している
        if [ -n "$(ls $compressDirPath)" ]; then
            date=`date +%Y%m%d_%H-%M-%S`
            mvPath="${compressDirPath}_${date}"
            # バックアップを行う
            mv ${compressDirPath} ${mvPath}
            echo "古いフォルダをバックアップしました :: ${mvPath}"
        fi
    fi
    
    # フォルダが存在していない場合は作成をする
    result=`mkdir -p ${compressDirPath}`

    for file in `\find ${filePath} -maxdepth 1 -type f | grep -v "\/\."`; do

        newfileName=`basename ${file}`
        newfileName="${newfileName%.*}"
        # mp4形式
        newFilePath="${compressDirPath}/${newfileName}${fileEx}"
        echo "Original: ${file}"
        echo "CompressPath: ${newFilePath}"

        if [ "${compressType}" = "1" ]; then
            result=`ffmpeg -i ${file} ${muteCmd}${newFilePath}`
        elif [ "${compressType}" = "2" ]; then
            result=`ffmpeg -i ${file} ${muteCmd}-b:v 1200k ${newFilePath}`
        else
            echo "Error."
            exit 1
        fi    

        fileSize=`wc -c ${file} | awk '{print $1}'`
        compressFileSize=`wc -c ${newFilePath} | awk '{print $1}'`

        totalSize=$((${totalSize}+${fileSize}))
        compressSize=$((${compressSize}+${compressFileSize}))

        echo "Result: File Size ${fileSize} --> ${compressFileSize}"
    done

# ファイルの場合の処理
else

    if [ "${compressType}" = "1" ]; then
        result=`ffmpeg -i ${filePath} ${muteCmd}${compressFilePath}`
    elif [ "${compressType}" = "2" ]; then
        result=`ffmpeg -i ${filePath} ${muteCmd}-b:v 1200k ${compressFilePath}`
    else
        echo "Error."
        exit 1
    fi

    totalSize=`wc -c ${filePath} | awk '{print $1}'`
    compressSize=`wc -c ${compressFilePath} | awk '{print $1}'`
fi

echo "==================================="
echo "圧縮完了"

echo "元サイズ : $(byteStr $totalSize)"
echo "圧縮後のサイズ : $(byteStr $compressSize)"
echo "圧縮率 : $(((${totalSize}-${compressSize})*100/(${totalSize}+${compressSize})))%"

# echo "処理時間: ${$run_time}"
exit 0
