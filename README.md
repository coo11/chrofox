<h1 align="center">
  <img src="chrofox.svg" alt="Logo" width="150"><br/>
  Chrofox
</h1>

<h4 align="center">coo11 的浏览器妙妙小工具</h4>

> [!TIP]
> 问: 这个仓库是做什么用的？\
> 答: 借助工作流脚本，让你的火狐和谷歌浏览器更加易用。

## 配置搜索引擎

> 本仓库的另一个主要作用是让搜索引擎的配置管理更加方便。只需维护仓库根目录下的 [`search_config.json`](/search_config.json)，工作流就会自动生成两个浏览器需要的配置文件。

### Chrome

自 Chrome 137 以来，存储搜索引擎数据的文件[添加了数据验证](https://chromium.googlesource.com/chromium/src.git/+/refs/tags/137.0.7151.138/components/search_engines/keyword_table.h#88)，因此原本通过数据库导入搜索引擎的方法失效。现在的方法是打开 `chrome://settings/searchEngines` 页面，将工作流生成的 `importEngines.js` 在开发者工具中执行来导入，需要配合点击。

### Firefox

将工作流生成的 `search.json.mozlz4` 放入账户数据目录，覆盖同名文件即可。

### 关于导出

- Firefox：执行 [`mozlz4_dump.py`](/tools/mozlz4_dump.py) `search.json.mozlz4` 即可将 lz4 格式的数据文件导出为 JSON，或者使用 [Firefox Search Engine Extractor](https://www.jeffersonscher.com/ffu/searchjson.html) 这个网站。

- Chrome：使用 SQLite 从用户数据目录的 `Web Data` 文件中提取即可，Windows 下注意不要在文件目录中使用反斜杠：\
`sqlite3.exe -cmd ".output "/path/keywords.sql"" -cmd ".dump keywords" "/path/Web Data" .exit`

## Windows 便携版 Chrome

定期下载最新版 Windows Chrome x64，然后和最新的 [Chrome++](https://github.com/Bush2021/chrome_plus) 打包成便携版。

提供最后一版（`109.0.5414`）支持 Windows 7 的便携版下载链接。