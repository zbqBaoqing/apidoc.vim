" Apidoc vim plugin, for automatic load api note
" auto load apidoc tpl
" Last Change: 26/08/2016
" Maintainer: yexingkong <zbqyexingkong@163.com>
" License: This file is placed in the public domain.

if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif

if exists("b:did_apidoc_plugin")
    finish
endif

let b:did_apidoc_plugin = 1


setlocal formatoptions& formatoptions+=ro

python << endpython

import vim
import json
import os

def readtpl(path):
    if not path:
        raise vim.error("Error: template path is empty.")
    data = ""
    temp_path = path.rstrip("/") + "/template/template"
    with open(temp_path) as f:
        data = f.read()
    return data


def format_data(data, **kargs):
    if not data:
        raise vim.error("Error: template data is empty.")
    if len(kargs) < 1:
        raise vim.error("Sorry: file type not suppert yet.")

    start_pre = kargs["start_pre"] + "\n" 
    end_pre = kargs["end_pre"] + "\n"
    prefix = kargs["prefix"]
    doc = start_pre 
    for line in data.strip().split("\n"):
        doc += "%s %s\n" % (prefix, line)
    doc += end_pre
    return doc
    

def format_by_filetype(filetype):
    sup_format = {1:{"start_pre":"/**", "prefix":"*", "end_pre":"*/"}, \
                    2:{"start_pre":'"""', "prefix":"", "end_pre":'"""'}}
    sup_filetype = {"go":1, "java":1, "php":1, "javascript":1, "python":2}
    
    if filetype not in sup_filetype:
        return  {} 
    else:
        return sup_format[sup_filetype[filetype]]

def write_data_2_buffer(data):
    if not data:
        raise vim.error("Warning: tpl data is empty.")
    row, col = vim.current.window.cursor
    buf = vim.current.buffer
    k = -1
    for line in data.split("\n"):
        num = row + k
        buf.append(str(line), num)
        k += 1
endpython


function! apidoc#GetFileType()
    return &filetype
endfunction


function! apidoc#GetFilePath()
    let l:path = &runtimepath
python << endpython
plugin_path = vim.eval("l:path")
for  path in plugin_path.split(","):
    if path.endswith("apidoc.vim"):
        vim.command("let l:apidoc_path = %r" % path)
        break
endpython
return l:apidoc_path
endfunction

function! apidoc#Execute()
    let l:ty = apidoc#GetFileType()
    let l:apidoc_path = apidoc#GetFilePath()

python << endpython

# 获取插件路径
doc_path = vim.eval("l:apidoc_path")
#读取apidoc模板
tpl_data = readtpl(doc_path)
#获取文件类型
filetype = vim.eval("l:ty")
#获取apidoc支持的格式
fmt = format_by_filetype(filetype)
#对模板数据进行格式化
fmted_data = format_data(tpl_data, **fmt)
#对个格式化的数据写入文件
write_data_2_buffer(fmted_data)

endpython
endfunction

if !exists(":ApiDocTpl")
    command! -nargs=0 ApiDocTpl call apidoc#Execute()
endif

