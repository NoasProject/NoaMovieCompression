#!/bin/bash

dirPath=`dirname ${0}`
fileName=`basename ${0}`

echo "shellの簡易コマンドファイルの作成をおこないます"

cp -r "${dirPath}/shell/CompressionMovie.sh" "${dirPath}/Command/CompressionMovie.command"
ln -sf "${dirPath}/Command/CompressionMovie.command" "${HOME}/"

echo 0