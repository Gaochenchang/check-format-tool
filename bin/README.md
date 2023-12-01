Version 1.0

# 1. check-format-tool

此工具可以检查 branch name、commit message、code style。

[vscode 插件 README](../vscode_plugin/bin/README.md)

## 1.1 安装步骤

```shell
cd check-format-tool/bin
./install.sh
export CHECK_REPO_PATH=your_check_repo_path
. ./export.sh
```

## 1.2 用法例举

check-format 工具有三个命令：
 - branch-name 检查分支名称的有效性
 - commit-message 检查提交信息的有效性
 - code-style 检查或格式化代码风格。
              <br><span style="color:red;">注意</span>： 建议先将改动文件`git add`添加至暂存区, 然后使用无文件路径参数的命令操作（类似于`check-format -v code-style`）；
                    若格式化文件不在暂存区，则需使用带有`-F`与文件路径的命令操作（类似于`check-format -F code-style "your file path"`）。

使用命令 `check-format --help` 可查看用法。

```shell
usage: check-format [options] [options] [command] <file_path>

Commands:
  [mode]
    branch-name     Check validity of branch name.
                    eg: check-format branch_name
    commit-message
                    Check validity of commit message format.
                    eg: check-format commit_message
    code-style      Check or format the code format.
                    Note: It is recommended to first add the modified file to the staging
                          area using 'git add' and then use the command operation without
                          file path parameters (similar to 'check-format -v code-style');
                          If the formatted file is not in the staging area, you need to
                          use the command operation with -f/-l and file path (similar to
                          'check-format -f code-style "your_file_path"').
                    eg: check-format code-style
                        check-format code-style "file_path or folder_path"

Options:
  -h, --help      show this help message and exit.
  -f, --format    Force format file(Do not ask).
  -F, --full      Check the entire file.
  -d, --dry_run   Dry run, just print a simple prompt.
  -v, --verbose   Print verbose formatted content.
  -l start_line:end_line, --lines start_line:end_line
                        Specify lines to format.

Examples:
  check-format branch-name
  check-format commit-message
  check-format code-style
  check-format -d code-style
  check-format -f code-style
  check-format -v code-style
  check-format -vf code-style
  check-format -vF code-style
  check-format -Ff code-style
  check-format -vFf code-style "file_path or folder_path"
```

### clang-format off 用法
若部分代码使用工具无法得到正确的格式（比如具有嵌套结构的宏定义），则可使用`// clang-format off`与`// clang-format on`选择格式化区域。
```c
#include <stdio.h>
开启格式化区域
// clang-format off
禁止格式化区域
// clang-format on
开启格式化区域
```

### 这里列举阐释更详细的用法示例：
1. Check branch-name / commit-message / code-style
```shell
git add <Change files>
check-format branch-name
check-format commit-message
check-format code-style
```
2. 需要检查改动文件的全部代码（默认不加`--full`的选项只检查改动部分代码）
```shell
git add <Change files>
check-format --full code-style
check-format -F code-style
```
3. 仅检查 diff 文件是否需要格式化，无详细打印信息，不进行实际的格式化操作
```shell
git add <Change files>
check-format --dry-run code-style
check-format -d code-style
```
4. 检查某文件的整体格式（可递归），此场景不需要文件添加在暂存区。
```shell
check-format --full code-style "components/audio_hal/driver/es7210/es7210.c"
check-format --full code-style "components/audio_hal/driver/es7210"
check-format -F code-style "components/audio_hal/driver/es7210"
```
5. 仅检查某文件是否需要格式化，无详细打印信息，不进行实际的格式化操作
```shell
git add <Change files>
check-format --dry-run code-style "components/audio_hal/driver/es7210"
check-format -d code-style "components/audio_hal/driver/es7210/es7210.c"
```
6. 直接对某文件进行格式化
```shell
git add <Change files>
check-format --format code-style "components/audio_hal/driver/es7210/es7210.c"
check-format -f code-style "components/audio_hal/driver/es7210"
```
7. 自由组合布尔选项
```shell
check-format --verbose --full --format code-style "components/audio_hal/driver/es7210"
check-format -vFf code-style "components/audio_hal/driver/es7210"
```

## 1.3 branch name 格式

```
<prefix>/<description>
```

示例：

```
ci/add_pre_check_job
```

### 1.3.1 branch name 具体要求

1. prefix
    - ci
    - dev
    - docs
    - test
    - debug
    - bugfix
    - feature
    - customer
    - release
2. description
    - 小写描述信息

## 1.4 commit message 格式

仅有标题的 commmit message 格式如下
```shell
<component_name>: <commit messages>
```

示例：
```shell
audio_board: Add esp32_s3_korvo2_v3 board configurations
```
含有正文的 commit message 格式如下

```
<component_name>: <commit message>
# 空行
1. Some info
2. Some info
```
示例：
```shell
audio_board: Add esp32_s3_korvo2_v3 board configurations

1. Update cli sdkconfig
2. Update esp-sr

Close https://xxxx
```

### 1.4.1 component_name 具体要求

1. 为 audio_stream, audio_board, examples, docs, ci, ut, 等。
2. 除下方特殊的组件之外，其余组件为 components 下的一级目录名称与 submodules 的名称。
3. special_components = ["ci", "ut", "docs", "tools", "examples"]

### 1.4.2 commit message 具体要求

1. commit message 不能为空
2. 与前一个标号之间用空格相隔。
3. 以 Add/Fix/Remove/Change/Improve/Update 等动词原型开头
4. 句子首字母大写
5. commit message 标题末尾不能出现`.`
6. 若存在多行详细的 message，需要用空行将 commit message 标题与正文分隔开。
7. 若存在 Close jira 链接的 message，需要用空行将其与上方的 commit message 正文或标题分隔开。

## 1.5 code style 格式

otbs（One True Brace Style） 风格。

```shell
# 示例
int Foo(bool isBar)
{
    if (isFoo) {
        bar();
        return 1;
    } else {
        return 0;
    }
} 
```
clang-format 工具的原始用法如下
```shell
clang-format -style='file:.clang-format' -lines=<start_line>:<end_line> -i <file_path>
```

# 2. pyinstaller

## 2.1 pyinstaller 版本

```
pyinstaller --version
5.13.2
```

## 2.2 打包步骤

```
pyinstaller --add-binary "/your_path/libclang-16.so:." --add-binary "/your_path/clang-format:." --add-data "/your_path/.clang-format:." --add-data "/your_path/.clang-format-function:." --onefile --windowed check_commit_format.py
```
